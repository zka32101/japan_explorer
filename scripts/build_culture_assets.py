#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Build the compact per-language culture-content assets bundled with the app.

Input : <cache>/culture_content_extracted.json        (English source, 1221 articles)
        <cache>/culture_content_<lang>.json           (Gemini translations)
Output: assets/culture_content/<lang>.json            {id: {"t","s","d","k","y"}}

The translations come from an LLM, so every entry is validated against the
English source and repaired or dropped:
  * only the known fields are kept (stray keys such as title_en are ignored,
    misspelled keys such as didYouKNOW are mapped back),
  * keyFacts / didYouKnow are only kept when the source has them,
  * keyFacts must have the same number of items as the source,
  * text must actually differ from English and not be empty.
An article that fails validation is left out, so the app falls back to English
for it instead of showing something wrong.

Usage:
  python scripts/build_culture_assets.py [--cache DIR] [lang ...]
"""
import argparse
import difflib
import io
import json
import os
import re
import sys

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DEFAULT_CACHE = r"H:\マイドライブ\apps\japan_explorer\.translation_cache"
OUT_DIR = os.path.join(ROOT, "assets", "culture_content")

# canonical field -> (compact key)
COMPACT = {"title": "t", "subtitle": "s", "description": "d", "keyFacts": "k", "didYouKnow": "y"}


def norm_key(key):
    """Map a possibly misspelled key back to a canonical field name."""
    low = re.sub(r"[^a-z]", "", key.lower())
    if low in ("id", "title", "subtitle", "description", "keyfacts"):
        return {"id": "id", "title": "title", "subtitle": "subtitle",
                "description": "description", "keyfacts": "keyFacts"}[low]
    if low.startswith("didyou"):
        return "didYouKnow"
    return None  # title_en, subtitle_zh, ...


def repair(entry):
    """Return {canonical field: value} from a raw translated entry."""
    out = {}
    for key, value in entry.items():
        canon = norm_key(key)
        if canon and canon not in out and value not in (None, "", []):
            out[canon] = value
    return out


def looks_translated(src, dst, lang):
    """Reject empty text and text that is just the English original."""
    if not isinstance(dst, str) or not dst.strip():
        return False
    if lang.startswith("en"):
        return True
    ratio = difflib.SequenceMatcher(None, src[:400], dst[:400]).ratio()
    return ratio < 0.9


def build_language(lang, source, cache):
    path = os.path.join(cache, f"culture_content_{lang}.json")
    if not os.path.exists(path):
        print(f"[{lang}] no translation file - skipped")
        return None
    raw = json.load(io.open(path, encoding="utf-8"))
    out, dropped = {}, {}
    for art_id, src_entry in source.items():
        entry = raw.get(art_id)
        if entry is None:
            dropped["missing"] = dropped.get("missing", 0) + 1
            continue
        got = repair(entry)
        compact = {}
        ok = True
        # The description is what proves the article was really translated.
        # Titles/subtitles may legitimately match English (proper nouns such as
        # "Ramune"), so they only need to be non-empty.
        if not looks_translated(src_entry.get("description", ""), got.get("description"), lang):
            dropped["description"] = dropped.get("description", 0) + 1
            continue
        for field in ("title", "subtitle", "description"):
            value = got.get(field)
            if not isinstance(value, str) or not value.strip():
                ok = False
                dropped[field] = dropped.get(field, 0) + 1
                break
            compact[COMPACT[field]] = value.strip()
        if not ok:
            continue
        src_facts = src_entry.get("keyFacts") or []
        if src_facts:
            facts = got.get("keyFacts")
            if isinstance(facts, list) and len(facts) == len(src_facts) \
                    and all(isinstance(f, str) and f.strip() for f in facts):
                compact["k"] = [f.strip() for f in facts]
            else:
                dropped["keyFacts"] = dropped.get("keyFacts", 0) + 1
        if src_entry.get("didYouKnow"):
            dyk = got.get("didYouKnow")
            if isinstance(dyk, str) and dyk.strip():
                compact["y"] = dyk.strip()
            else:
                dropped["didYouKnow"] = dropped.get("didYouKnow", 0) + 1
        out[art_id] = compact
    os.makedirs(OUT_DIR, exist_ok=True)
    out_path = os.path.join(OUT_DIR, f"{lang}.json")
    with io.open(out_path, "w", encoding="utf-8", newline="\n") as f:
        json.dump(out, f, ensure_ascii=False, separators=(",", ":"))
    size = os.path.getsize(out_path) / 1e6
    print(f"[{lang}] {len(out)}/{len(source)} articles, {size:.2f} MB, dropped: {dropped or 'none'}")
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--cache", default=DEFAULT_CACHE)
    ap.add_argument("langs", nargs="*", default=["ja", "zh", "ko", "fr", "zh-TW"])
    args = ap.parse_args()
    src_list = json.load(io.open(os.path.join(args.cache, "culture_content_extracted.json"), encoding="utf-8"))
    source = {e["id"]: e for e in src_list}
    for lang in args.langs:
        build_language(lang, source, args.cache)


if __name__ == "__main__":
    main()
