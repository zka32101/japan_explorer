# Deep Link Files — Hosting Guide

Both files in this directory must be served from `https://japanexplorer.app` before
submitting to the stores.

---

## Android — assetlinks.json

Host at: `https://japanexplorer.app/.well-known/assetlinks.json`

**Before deploying, replace the SHA-256 fingerprint:**

```
keytool -printcert -jarfile path/to/release.apk
```

Or from the Play Console → App Integrity → App signing → SHA-256 certificate fingerprint.

Replace `REPLACE_WITH_RELEASE_SHA256_FINGERPRINT` with the colon-separated hex string,
e.g. `"AB:CD:EF:..."`.

**Server requirements:**
- Content-Type: `application/json`
- No redirect on `/.well-known/assetlinks.json`
- Accessible over HTTPS (TLS required)

**Verify with:**
```
https://digitalassetlinks.googleapis.com/v1/statements:list?source.web.site=https://japanexplorer.app&relation=delegate_permission/common.handle_all_urls
```

---

## iOS — apple-app-site-association

Host at: `https://japanexplorer.app/.well-known/apple-app-site-association`
         (also optionally at `https://japanexplorer.app/apple-app-site-association`)

**Before deploying, replace the Team ID:**
- Find it in the Apple Developer portal → Membership → Team ID (10-char string, e.g. `ABC1234DEF`)
- Replace both `REPLACE_WITH_TEAM_ID` occurrences with that value.

**Server requirements:**
- Content-Type: `application/json`
- No redirect (must serve directly, no 301/302)
- Accessible over HTTPS

**Verify with:**
```
https://app-site-association.cdn-apple.com/a/v1/japanexplorer.app
```

---

## Xcode project wiring (Runner.entitlements is already set)

After deploying the AASA file, in Xcode:
1. Open `ios/Runner.xcworkspace`
2. Select Runner target → Signing & Capabilities
3. Add capability: **Associated Domains**
4. Add entry: `applinks:japanexplorer.app`
   (Runner.entitlements already has this — Xcode will pick it up automatically)

---

## GoRouter route mapping

| URL / URI                                      | GoRouter path         |
|------------------------------------------------|-----------------------|
| `https://japanexplorer.app/spots/{id}`         | `/spots/{id}`         |
| `https://japanexplorer.app/plans/{id}`         | `/plans/{id}`         |
| `https://japanexplorer.app/profile/{uid}`      | `/profile/{uid}`      |
| `https://japanexplorer.app/challenge/{id}`     | `/challenge/{id}`     |
| `japanexplorer://spots/{id}`                   | `/spots/{id}`         |
| `japanexplorer://plans/{id}`                   | `/plans/{id}`         |

FCM `fcm_service.dart` already normalises all three URL forms to the GoRouter path.
