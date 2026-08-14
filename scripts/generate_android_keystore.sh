#!/usr/bin/env bash
#
# generate_android_keystore.sh — creates the Android release signing
# keystore expected by android/app/build.gradle.kts (via key.properties)
# and by scripts/register_github_secrets.sh.
#
# The resulting .jks and android/key.properties are gitignored on purpose
# — never commit them. Back the .jks up somewhere safe (password manager,
# encrypted drive): losing it means you can never update the app under the
# same Play Store listing again.
#
# Usage:
#   ./scripts/generate_android_keystore.sh
#
# All values can be pre-supplied via env vars to run non-interactively:
#   ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_PASSWORD, ANDROID_KEY_ALIAS,
#   ANDROID_KEYSTORE_PATH (default: android/keystore/japan_explorer_release.jks)
#
set -euo pipefail

command -v keytool >/dev/null 2>&1 || {
  echo "error: keytool not found — install a JDK (it ships with Android Studio too)." >&2
  exit 1
}

KEYSTORE_PATH="${ANDROID_KEYSTORE_PATH:-android/keystore/japan_explorer_release.jks}"
KEY_ALIAS="${ANDROID_KEY_ALIAS:-japan_explorer}"

if [[ -f "$KEYSTORE_PATH" ]]; then
  echo "error: $KEYSTORE_PATH already exists — refusing to overwrite an existing release keystore." >&2
  echo "If you really want a new one, move or delete it first (and know that you can" >&2
  echo "never again update an app already published under the old key's signature)." >&2
  exit 1
fi

if [[ -z "${ANDROID_KEYSTORE_PASSWORD:-}" ]]; then
  read -r -s -p "Keystore password (min 6 chars): " ANDROID_KEYSTORE_PASSWORD; echo
fi
if [[ -z "${ANDROID_KEY_PASSWORD:-}" ]]; then
  read -r -s -p "Key password (can match keystore password): " ANDROID_KEY_PASSWORD; echo
fi

mkdir -p "$(dirname "$KEYSTORE_PATH")"

keytool -genkey -v \
  -keystore "$KEYSTORE_PATH" \
  -alias "$KEY_ALIAS" \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass "$ANDROID_KEYSTORE_PASSWORD" \
  -keypass "$ANDROID_KEY_PASSWORD" \
  -dname "CN=Japan Explorer, OU=Petit Works Apps, O=Petit Works Apps, L=, ST=, C=JP"

cat > android/key.properties <<EOF
storePassword=$ANDROID_KEYSTORE_PASSWORD
keyPassword=$ANDROID_KEY_PASSWORD
keyAlias=$KEY_ALIAS
storeFile=$(python3 -c "import os,sys; print(os.path.relpath(sys.argv[1], 'android'))" "$KEYSTORE_PATH")
EOF

echo ""
echo "Wrote $KEYSTORE_PATH and android/key.properties (both gitignored)."
echo ""
echo "SHA-1 / SHA-256 for Firebase / Google Sign-In:"
keytool -list -v -keystore "$KEYSTORE_PATH" -alias "$KEY_ALIAS" -storepass "$ANDROID_KEYSTORE_PASSWORD" \
  | grep -E "SHA1:|SHA256:"

echo ""
echo "Next steps:"
echo "  1. Add the SHA-1/SHA-256 above to the Android app in Firebase Console"
echo "     (or run scripts/setup_firebase.sh which does this for you)."
echo "  2. Register these as GitHub secrets:"
echo "       ANDROID_KEYSTORE_BASE64=\$(base64 < $KEYSTORE_PATH | tr -d '\\n')"
echo "       ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS, ANDROID_KEY_PASSWORD"
echo "     ...or just run: ./scripts/register_github_secrets.sh"
