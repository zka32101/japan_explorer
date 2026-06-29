# Japan Explorer — Release Checklist

> Track every item before submitting to Google Play and Apple App Store.
> Version: **1.0.0**

---

## 1. Development & Code

- [ ] All planned Week 1–11 features implemented and tested
- [ ] Unit tests pass: `flutter test`
- [ ] Integration tests pass: `flutter test integration_test/`
- [ ] No Flutter analyzer errors: `flutter analyze`
- [ ] `flutter pub outdated` reviewed — no critical security patches missed
- [ ] Debug prints removed / behind `kDebugMode` guards
- [ ] API keys NOT hardcoded in Dart source (use env/config injection)
- [ ] `firestoreProvider` injectable — `StreakNotifier`/`PostNotifier` testable (Week 11 tech debt)

---

## 2. Firebase Setup

- [ ] `flutterfire configure` run — `google-services.json` and `GoogleService-Info.plist` generated
- [ ] Firebase project: **Production** (not dev/staging) selected
- [ ] Firestore security rules reviewed and deployed
- [ ] Firebase Storage security rules reviewed and deployed
- [ ] Cloud Functions deployed: `badge_notifications.js`, `notification_trigger.js`, `rating_aggregator.js`
- [ ] FCM test notification delivered to Android device
- [ ] FCM test notification delivered to iOS device
- [ ] Firebase Analytics events verified in DebugView
- [ ] Crashlytics test crash recorded
- [ ] Google Sign-In SHA-1 and SHA-256 fingerprints added to Firebase project
  - Debug: `keytool -list -v -keystore ~/.android/debug.keystore`
  - Release: `keytool -list -v -keystore android/keystore/japan_explorer_release.jks`

---

## 3. Android

### Signing
- [ ] Release keystore generated: `android/keystore/japan_explorer_release.jks`
- [ ] `android/key.properties` created from template (NOT committed to git)
- [ ] Release APK / AAB signs successfully: `flutter build appbundle --release`
- [ ] Keystore backed up securely (not in project folder, not in git)

### Configuration
- [ ] `android/local.properties` has `MAPS_API_KEY=<real key>`
- [ ] `android/app/google-services.json` present
- [ ] `versionCode` and `versionName` set in `pubspec.yaml` (propagates via flutter vars)
- [ ] `android:label="Japan Explorer"` in AndroidManifest ✅
- [ ] `android:allowBackup="false"` in AndroidManifest ✅
- [ ] ProGuard rules cover all used libraries ✅

### Build
- [ ] `flutter build appbundle --release` succeeds (no errors)
- [ ] AAB tested on: Android 8.0 (API 26), Android 12, Android 14
- [ ] Google Maps renders correctly on device
- [ ] Push notifications received on device

---

## 4. iOS

### Signing
- [ ] Apple Developer account active ($99/year)
- [ ] App ID registered: `com.funvestment.japan_explorer`
- [ ] Distribution certificate created in Xcode / Apple Developer portal
- [ ] Provisioning profile (App Store Distribution) created and downloaded
- [ ] `GoogleService-Info.plist` added to Xcode project (Runner target)
- [ ] `REVERSED_CLIENT_ID` value from `GoogleService-Info.plist` confirmed matches `Info.plist` URL scheme

### Configuration
- [ ] Google Maps API key added: Xcode → Runner → Info → `GMSApiKey` (or `AppDelegate.swift`)
  ```swift
  GMSServices.provideAPIKey("YOUR_IOS_MAPS_API_KEY")
  ```
- [ ] All `NSUsageDescription` strings in `Info.plist` ✅
- [ ] Portrait-only iPhone orientation set ✅
- [ ] `CFBundleDisplayName` = "Japan Explorer" ✅

### Build
- [ ] `flutter build ipa --release` succeeds
- [ ] Tested on: iPhone SE (small screen), iPhone 15 Pro, iPad (if supported)
- [ ] Push notifications entitlement added in Xcode (Push Notifications capability)
- [ ] Background modes: Remote notifications enabled in Xcode capabilities
- [ ] Apple Sign-In capability added (required if any other social login is offered)

---

## 5. Store Assets

### Google Play
- [ ] App icon 512×512 PNG
- [ ] Feature graphic 1024×500 PNG
- [ ] Minimum 2 phone screenshots
- [ ] Short description (80 chars) ✅ (`store_listing/play_store_listing.md`)
- [ ] Full description ✅
- [ ] Privacy Policy URL live and accessible
- [ ] Content rating questionnaire completed (IARC)
- [ ] Target audience: 18+

### Apple App Store
- [ ] App icon (no alpha) — all required sizes via Xcode Asset Catalog
- [ ] iPhone 6.9" screenshots (3 minimum)
- [ ] iPhone 6.5" screenshots (3 minimum)
- [ ] iPad 13" screenshots (3 minimum, if iPad supported)
- [ ] Description ✅ (`store_listing/app_store_listing.md`)
- [ ] Keywords ✅
- [ ] Support URL live
- [ ] Privacy Policy URL live and accessible ✅
- [ ] App Privacy nutrition labels filled in App Store Connect ✅ (see app_store_listing.md)
- [ ] Export compliance: No encryption beyond standard HTTPS → "No" to encryption questions

---

## 6. Legal & Compliance

- [ ] Privacy Policy hosted at a live URL ✅ (`PRIVACY_POLICY.md`)
- [ ] Terms of Service (optional but recommended)
- [ ] GDPR compliance: data deletion flow works (Profile → Settings → Delete Account)
- [ ] Copyright notices for third-party assets (map tiles, icons, fonts)
- [ ] Google Maps usage complies with [Maps Platform Terms](https://cloud.google.com/maps-platform/terms)
- [ ] Firebase / Gemini API usage complies with respective terms

---

## 7. Final Pre-Submit Checks

- [ ] App version in `pubspec.yaml`: `version: 1.0.0+1`
- [ ] No test/debug screens accessible from production build
- [ ] Crash rate < 1% on internal test track
- [ ] Cold start time < 3 seconds on mid-range device
- [ ] Memory usage stable (no leaks after 10 min session)
- [ ] All deep links / URL schemes tested
- [ ] Accessibility: tap targets ≥ 44px, sufficient color contrast

---

## 8. Post-Launch

- [ ] Monitor Firebase Crashlytics for D+1, D+3, D+7
- [ ] Monitor Firebase Analytics retention
- [ ] Respond to initial Play Store / App Store reviews
- [ ] Set up Firebase Remote Config for kill switches / feature flags
- [ ] Plan v1.0.1 hotfix window (2 weeks after launch)

---

*Last updated: 2026-06-08*
