#!/usr/bin/env bash
#
# register_github_secrets.sh — one-shot registration of all GitHub Actions
# secrets used by .github/workflows/ios.yml and .github/workflows/deploy.yml.
#
# This script does NOT create any credentials itself — it only uploads
# files/values you already have (from Firebase Console, Apple Developer,
# App Store Connect, and Google Play Console) as GitHub repo secrets, via
# the GitHub CLI. Nothing here is committed to git or leaves your machine
# except the `gh secret set` calls to GitHub's API.
#
# Prerequisites:
#   - GitHub CLI installed and authenticated: `gh auth login`
#   - Run from the repo root (or set REPO below)
#
# Usage:
#   ./scripts/register_github_secrets.sh            # interactive, prompts for anything missing
#   ./scripts/register_github_secrets.sh --dry-run   # show what would be set/skipped, no changes
#   ./scripts/register_github_secrets.sh --list      # show current secret registration status only
#
# Every value can also be pre-supplied via environment variable (see the
# SECRETS table below) to run this fully non-interactively, e.g. in a
# password manager's `env` injection or a local .secrets.env file:
#
#   source .secrets.env && ./scripts/register_github_secrets.sh
#
set -euo pipefail

REPO="${GH_REPO:-zka32101/japan_explorer}"
DRY_RUN=false
LIST_ONLY=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --list) LIST_ONLY=true ;;
    -h|--help)
      sed -n '2,25p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      exit 1
      ;;
  esac
done

command -v gh >/dev/null 2>&1 || {
  echo "error: GitHub CLI (gh) not found. Install it: https://cli.github.com/" >&2
  exit 1
}

gh auth status >/dev/null 2>&1 || {
  echo "error: gh is not authenticated. Run: gh auth login" >&2
  exit 1
}

# ── Secret definitions ───────────────────────────────────────────────────
# type:
#   base64-file  -> secret value is base64(file contents), no line wraps
#   raw-file     -> secret value is the file's raw contents, verbatim
#   plain        -> secret value is a plain string (password, ID, key)
#
# format: name|type|source (file path for *-file, env var name for plain)|description
SECRETS=(
  "IOS_GOOGLESERVICE_INFO_PLIST_BASE64|base64-file|ios/Runner/GoogleService-Info.plist|iOS Firebase config (flutterfire configure output)"
  "ANDROID_GOOGLE_SERVICES_JSON_BASE64|base64-file|android/app/google-services.json|Android Firebase config (flutterfire configure output)"
  "ANDROID_KEYSTORE_BASE64|base64-file|android/keystore/japan_explorer_release.jks|Android release signing keystore (see scripts/generate_android_keystore.sh)"
  "IOS_DISTRIBUTION_P12_BASE64|base64-file|IOS_P12_PATH|iOS distribution certificate (.p12), exported from Keychain Access"
  "IOS_PROVISIONING_PROFILE_BASE64|base64-file|IOS_PROVISIONING_PROFILE_PATH|App Store distribution provisioning profile (.mobileprovision)"
  "APPSTORE_API_PRIVATE_KEY|raw-file|APPSTORE_API_KEY_PATH|App Store Connect API key (.p8) from Users and Access > Keys"
  "GOOGLE_PLAY_SERVICE_ACCOUNT_JSON|raw-file|GOOGLE_PLAY_SA_JSON_PATH|Play Console service account key JSON (Setup > API access)"
  "IOS_P12_PASSWORD|plain|IOS_P12_PASSWORD|Password for the .p12 above"
  "APPSTORE_ISSUER_ID|plain|APPSTORE_ISSUER_ID|App Store Connect API Issuer ID"
  "APPSTORE_KEY_ID|plain|APPSTORE_KEY_ID|App Store Connect API Key ID"
  "ANDROID_KEYSTORE_PASSWORD|plain|ANDROID_KEYSTORE_PASSWORD|Android keystore password"
  "ANDROID_KEY_ALIAS|plain|ANDROID_KEY_ALIAS|Android key alias (e.g. japan_explorer)"
  "ANDROID_KEY_PASSWORD|plain|ANDROID_KEY_PASSWORD|Android key password (same as keystore password for PKCS12 keystores — see generate_android_keystore.sh)"
  "GOOGLE_MAPS_API_KEY|plain|GOOGLE_MAPS_API_KEY|Google Maps API key"
)

echo "Target repo: $REPO"
$DRY_RUN && echo "(dry run — no secrets will be changed)"
echo ""

already_set() {
  gh secret list --repo "$REPO" --json name -q '.[].name' 2>/dev/null | grep -qx "$1"
}

set_secret_from_value() {
  local name="$1" value="$2"
  if [[ -z "$value" ]]; then
    echo "  skip  $name (no value provided)"
    return
  fi
  if $DRY_RUN; then
    echo "  would set  $name"
    return
  fi
  printf '%s' "$value" | gh secret set "$name" --repo "$REPO" >/dev/null
  echo "  set    $name"
}

for entry in "${SECRETS[@]}"; do
  IFS='|' read -r name type source desc <<< "$entry"

  if $LIST_ONLY; then
    if already_set "$name"; then
      echo "  [x] $name"
    else
      echo "  [ ] $name  — $desc"
    fi
    continue
  fi

  case "$type" in
    base64-file)
      # `source` is either a fixed repo-relative path, or (for items whose
      # location varies per developer) the name of an env var holding the
      # path.
      path="$source"
      [[ "$source" == *_PATH ]] && path="${!source:-}"
      if [[ -z "$path" || ! -f "$path" ]]; then
        echo "  skip  $name (file not found: ${path:-<unset $source>}) — $desc"
        continue
      fi
      value=$(base64 < "$path" | tr -d '\n')
      set_secret_from_value "$name" "$value"
      ;;
    raw-file)
      path="${!source:-}"
      if [[ -z "$path" || ! -f "$path" ]]; then
        echo "  skip  $name (file not found: ${path:-<unset $source>}) — $desc"
        continue
      fi
      set_secret_from_value "$name" "$(cat "$path")"
      ;;
    plain)
      value="${!source:-}"
      if [[ -z "$value" ]]; then
        # Interactive fallback — passwords/keys are hidden, everything
        # else echoes so you can see what you typed.
        if [[ "$name" == *PASSWORD* || "$name" == *PRIVATE_KEY* ]]; then
          read -r -s -p "  $name ($desc), leave blank to skip: " value; echo
        else
          read -r -p "  $name ($desc), leave blank to skip: " value
        fi
      fi
      set_secret_from_value "$name" "$value"
      ;;
  esac
done

echo ""
if $LIST_ONLY; then
  echo "Run without --list to register missing secrets."
else
  echo "Done. Verify with: gh secret list --repo $REPO"
fi
