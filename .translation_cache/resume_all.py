#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Resume all 4 language translations (each capped by that day's free-tier quota).
Run this once per day; it will pick up where it left off automatically.

API keys should be provided via environment variables:
  GEMINI_API_KEY_JA, GEMINI_API_KEY_ZH, GEMINI_API_KEY_KO, GEMINI_API_KEY_FR
OR via the GEMINI_API_KEY env var (will be used for all languages).

Example:
  export GEMINI_API_KEY="your_key_here"
  python resume_all.py
"""
import subprocess
import sys
import os

DIR = os.path.dirname(os.path.abspath(__file__))
SCRIPT = os.path.join(DIR, "translate_culture_content.py")

# Try to get keys from environment variables
# Fall back to per-language env vars, or fail gracefully
LANGUAGES = ["ja", "zh", "ko", "fr"]
KEYS = {}

global_key = os.environ.get("GEMINI_API_KEY", "").strip()
if not global_key:
    print("ERROR: GEMINI_API_KEY environment variable not set")
    print("Set it before running this script: export GEMINI_API_KEY='your_key'")
    sys.exit(1)

for lang in LANGUAGES:
    # Try language-specific key first, fall back to global
    key = os.environ.get(f"GEMINI_API_KEY_{lang.upper()}", global_key).strip()
    if not key:
        print(f"ERROR: No API key found for language '{lang}'")
        sys.exit(1)
    KEYS[lang] = key

print(f"Starting daily translation sync for {len(KEYS)} languages...", flush=True)
failed_langs = []

for lang, key in KEYS.items():
    print(f"\n===== Resuming {lang} =====", flush=True)
    result = subprocess.run([sys.executable, SCRIPT, lang, key])
    if result.returncode != 0:
        failed_langs.append(lang)
        print(f"⚠️  Language '{lang}' exited with code {result.returncode}", flush=True)

print("\n" + "="*50, flush=True)
if failed_langs:
    print(f"⚠️  Some languages failed: {', '.join(failed_langs)}", flush=True)
    print("These will be retried on the next scheduled run.", flush=True)
    sys.exit(1)
else:
    print("✓ All languages processed successfully for today's quota.", flush=True)
