#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Translate culture_content_extracted.json into a target language using Gemini.
Usage: python translate_culture_content.py <lang> <api_key>
  lang: ja | zh | ko | fr
Writes/updates culture_content_<lang>.json incrementally (resumable).
"""
import json
import io
import os
import sys
import time

# Windows console defaults to cp932, which can't encode em-dashes / CJK text
# that shows up in prompts or API error messages. Force UTF-8 so a stray
# character never crashes an unattended scheduled-task run again.
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
sys.stderr.reconfigure(encoding="utf-8", errors="replace")

import google.genai as genai

SCRATCH = r"H:\マイドライブ\apps\japan_explorer\.translation_cache"
SRC_JSON = f"{SCRATCH}\\culture_content_extracted.json"

LANG_NAMES = {
    "ja": "Japanese",
    "zh": "Simplified Chinese",
    "ko": "Korean",
    "fr": "French",
}

BATCH_SIZE = 3
MAX_RETRIES = 3


def load_entries():
    with io.open(SRC_JSON, "r", encoding="utf-8") as f:
        return json.load(f)


def load_progress(out_path):
    if os.path.exists(out_path):
        with io.open(out_path, "r", encoding="utf-8") as f:
            return json.load(f)
    return {}


def save_progress(out_path, data):
    tmp = out_path + ".tmp"
    with io.open(tmp, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    os.replace(tmp, out_path)


def build_prompt(batch, lang_name):
    payload = []
    for e in batch:
        item = {
            "id": e["id"],
            "title": e["title"],
            "subtitle": e["subtitle"],
            "description": e["description"],
        }
        if e.get("keyFacts"):
            item["keyFacts"] = e["keyFacts"]
        if e.get("didYouKnow"):
            item["didYouKnow"] = e["didYouKnow"]
        payload.append(item)

    return f"""Translate the following JSON array of Japan-culture encyclopedia articles from English to {lang_name}.

Rules:
- Translate "title", "subtitle", "description", "keyFacts" (if present), "didYouKnow" (if present) naturally and accurately, preserving tone (informative, engaging travel/culture encyclopedia style).
- Keep the "id" field EXACTLY unchanged (do not translate ids).
- Preserve markdown-style formatting inside "description" (e.g. **bold**, bullet lines starting with "-", paragraph breaks as \\n\\n).
- Preserve any Japanese terms in parentheses that are already Japanese (e.g. "(chanoyu)") — but if translating INTO Japanese, you may remove redundant romanization since the whole text is now Japanese.
- Do not add or drop array items. Return exactly {len(payload)} items, in the same order.
- Return ONLY a valid JSON array, no explanation, no markdown code fences.

Input:
{json.dumps(payload, ensure_ascii=False)}
"""


class QuotaExhausted(Exception):
    pass


def translate_batch(model, batch, lang_name):
    prompt = build_prompt(batch, lang_name)
    last_error = None
    for attempt in range(MAX_RETRIES):
        try:
            response = model.generate_content(prompt)
            text = response.text.strip()
            if text.startswith("```"):
                text = text.split("```")[1]
                if text.startswith("json"):
                    text = text[4:]
                text = text.strip()
            result = json.loads(text)
            if len(result) != len(batch):
                raise ValueError(f"Expected {len(batch)} items, got {len(result)}")
            return result
        except Exception as e:
            last_error = e
            msg = str(e)
            # Daily free-tier quota errors won't resolve by retrying within
            # this run — stop immediately instead of burning through every
            # remaining batch with futile retries (this used to starve later
            # languages in resume_all.py of their turn before a timeout).
            if "429" in msg or "quota" in msg.lower() or "ResourceExhausted" in msg:
                if "PerDay" in msg or "generate_content_free_tier_requests" in msg:
                    raise QuotaExhausted(msg)
            # Only print if not the last attempt (final one gets logged separately)
            if attempt < MAX_RETRIES - 1:
                print(f"  [retry {attempt+1}/{MAX_RETRIES}] error: {e}", flush=True)
            time.sleep(2 * (attempt + 1))
    # All retries exhausted — log final failure clearly
    print(f"  [FINAL] batch failed after {MAX_RETRIES} retries: {last_error}", flush=True)
    return None


def main():
    if len(sys.argv) < 3:
        print("Usage: translate_culture_content.py <lang> <api_key>")
        sys.exit(1)

    lang = sys.argv[1]
    api_key = sys.argv[2]
    lang_name = LANG_NAMES[lang]
    out_path = f"{SCRATCH}\\culture_content_{lang}.json"

    genai.configure(api_key=api_key)
    model = genai.GenerativeModel("gemini-flash-latest")

    entries = load_entries()
    progress = load_progress(out_path)

    todo = [e for e in entries if e["id"] not in progress]
    print(f"[{lang}] {len(progress)} already done, {len(todo)} remaining out of {len(entries)}", flush=True)

    batches = [todo[i:i+BATCH_SIZE] for i in range(0, len(todo), BATCH_SIZE)]

    for bi, batch in enumerate(batches):
        try:
            result = translate_batch(model, batch, lang_name)
        except QuotaExhausted as e:
            print(f"[{lang}] QUOTA EXHAUSTED at batch {bi+1}/{len(batches)} — "
                  f"stopping this run early (resumes automatically next time)", flush=True)
            print(f"[{lang}] Details: {e}", flush=True)
            break
        except Exception as e:
            # Unexpected error — log but don't crash
            print(f"[{lang}] UNEXPECTED ERROR at batch {bi+1}/{len(batches)}: {e}", flush=True)
            print(f"[{lang}] This batch will be retried on the next run", flush=True)
            continue

        if result is None:
            print(f"[{lang}] batch {bi+1}/{len(batches)} SKIPPED (permanent failure after retries)", flush=True)
            continue

        # Success — save results
        for orig, translated in zip(batch, result):
            if translated.get("id") != orig["id"]:
                # Model may have altered id; trust original order instead.
                translated["id"] = orig["id"]
            progress[orig["id"]] = translated
        save_progress(out_path, progress)
        if (bi + 1) % 10 == 0 or bi == len(batches) - 1:
            print(f"[{lang}] progress: {len(progress)}/{len(entries)} ({bi+1}/{len(batches)} batches)", flush=True)
        time.sleep(0.3)

    print(f"[{lang}] DONE: {len(progress)}/{len(entries)}", flush=True)


if __name__ == "__main__":
    main()
