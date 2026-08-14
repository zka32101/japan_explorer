#!/usr/bin/env bash
#
# setup_firebase.sh — automates everything about Firebase project setup
# that the Firebase/FlutterFire CLIs can do non-interactively:
#   1. Select (or create) the Firebase project
#   2. Register the Android + iOS apps and generate config files via
#      `flutterfire configure`
#   3. Register SHA-1/SHA-256 fingerprints for Google Sign-In (if a
#      debug and/or release keystore is present)
#   4. Deploy Firestore/Storage security rules
#   5. Deploy Cloud Functions
#
# What this script deliberately does NOT do (must be done once, by hand,
# in the Firebase Console — see the printed summary at the end):
#   - Enabling Authentication providers (Google Sign-In)
#   - Upgrading the project to the Blaze (pay-as-you-go) plan, required
#     for Cloud Functions — billing account linking has no CLI path
#   - Enabling Analytics / Crashlytics / App Check in the console UI
#
# Prerequisites:
#   npm install -g firebase-tools
#   dart pub global activate flutterfire_cli
#   firebase login          # one-time interactive browser login
#
# Usage:
#   ./scripts/setup_firebase.sh <firebase-project-id>
#
set -euo pipefail

PROJECT_ID="${1:-}"
if [[ -z "$PROJECT_ID" ]]; then
  echo "usage: $0 <firebase-project-id>" >&2
  echo "  e.g. $0 japan-explorer-prod" >&2
  exit 1
fi

BUNDLE_ID="com.yourwish.japanexplorer"

for cmd in firebase flutterfire; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "error: $cmd not found. See the prerequisites in this script's header." >&2
    exit 1
  }
done

firebase projects:list >/dev/null 2>&1 || {
  echo "error: not logged in to Firebase. Run: firebase login" >&2
  exit 1
}

echo "== 1/5: Firebase project =="
if firebase projects:list --json 2>/dev/null | grep -q "\"projectId\": \"$PROJECT_ID\""; then
  echo "  using existing project: $PROJECT_ID"
else
  echo "  project '$PROJECT_ID' not found — creating it"
  firebase projects:create "$PROJECT_ID" --display-name "Japan Explorer"
fi

echo ""
echo "== 2/5: flutterfire configure (Android + iOS) =="
flutterfire configure \
  --project="$PROJECT_ID" \
  --platforms=android,ios \
  --android-package-name="$BUNDLE_ID" \
  --ios-bundle-id="$BUNDLE_ID" \
  --yes
echo "  wrote android/app/google-services.json, ios/Runner/GoogleService-Info.plist, lib/firebase_options.dart"
echo "  (all gitignored — do not commit them)"

echo ""
echo "== 3/5: Google Sign-In SHA fingerprints =="
ANDROID_APP_ID=$(firebase apps:list ANDROID --project "$PROJECT_ID" --json 2>/dev/null \
  | python3 -c "import json,sys; apps=json.load(sys.stdin)['result']; print(next((a['appId'] for a in apps if a['packageName']=='$BUNDLE_ID'), ''))" || true)

register_sha() {
  local keystore="$1" alias="$2" storepass="$3"
  [[ -f "$keystore" ]] || return 0
  [[ -n "$ANDROID_APP_ID" ]] || { echo "  skip (couldn't resolve Android app id)"; return 0; }
  local sha1 sha256
  sha1=$(keytool -list -v -keystore "$keystore" -alias "$alias" -storepass "$storepass" 2>/dev/null \
    | grep "SHA1:" | awk '{print $2}')
  sha256=$(keytool -list -v -keystore "$keystore" -alias "$alias" -storepass "$storepass" 2>/dev/null \
    | grep "SHA256:" | awk '{print $2}')
  [[ -n "$sha1" ]] && firebase apps:android:sha:create "$ANDROID_APP_ID" "$sha1" --project "$PROJECT_ID" || true
  [[ -n "$sha256" ]] && firebase apps:android:sha:create "$ANDROID_APP_ID" "$sha256" --project "$PROJECT_ID" || true
  echo "  registered SHA-1/SHA-256 from $keystore"
}

if [[ -f ~/.android/debug.keystore ]]; then
  register_sha ~/.android/debug.keystore androiddebugkey android
else
  echo "  no debug.keystore found at ~/.android/debug.keystore, skipping"
fi

if [[ -n "${ANDROID_KEYSTORE_PASSWORD:-}" && -f "android/keystore/japan_explorer_release.jks" ]]; then
  register_sha "android/keystore/japan_explorer_release.jks" "${ANDROID_KEY_ALIAS:-japan_explorer}" "$ANDROID_KEYSTORE_PASSWORD"
else
  echo "  no release keystore + ANDROID_KEYSTORE_PASSWORD env var set, skipping"
  echo "  (run scripts/generate_android_keystore.sh first, then re-run this script)"
fi

echo ""
echo "== 4/5: Firestore + Storage rules =="
if [[ -d firebase ]]; then
  (cd firebase && firebase deploy --project "$PROJECT_ID" --only firestore:rules,storage:rules)
else
  echo "  skip (no firebase/ directory found)"
fi

echo ""
echo "== 5/5: Cloud Functions =="
if [[ -d firebase/cloud_functions ]]; then
  (cd firebase/cloud_functions && npm install && firebase deploy --project "$PROJECT_ID" --only functions)
else
  echo "  skip (no firebase/cloud_functions directory found)"
fi

cat <<EOF

Done. Still needs a one-time manual step in the Firebase Console
(https://console.firebase.google.com/project/$PROJECT_ID):
  - Authentication > Sign-in method > enable Google
  - Confirm the project is on the Blaze plan (required for Cloud Functions)
  - Analytics / Crashlytics / App Check enablement, if not already on

Then register the generated config files as GitHub secrets:
  ./scripts/register_github_secrets.sh
EOF
