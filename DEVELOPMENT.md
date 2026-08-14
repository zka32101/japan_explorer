# Japan Explorer — Development Guide

## 環境構築

### 1. Firebase Setup

```bash
# Firebase CLI インストール
npm install -g firebase-tools

# ログイン
firebase login

# FlutterFire 設定
dart pub global activate flutterfire_cli
flutterfire configure --project=japan-explorer-prod
```

Firebaseプロジェクト作成〜SHA登録〜ルール/Functionsデプロイ〜GitHub Secrets登録までの一連の流れを自動化したスクリプトが `scripts/` にあります。詳細は [`scripts/README.md`](scripts/README.md) を参照してください。

### 2. 環境変数

```bash
cp .env.example .env
# .env を編集して各 API キーを設定
```

### 3. Android 設定

`android/app/build.gradle`:
- minSdkVersion: 21
- targetSdkVersion: 34
- Google Maps API Key を AndroidManifest.xml に追加

### 4. iOS 設定

`ios/Podfile`:
- platform :ios, '12.0'

`ios/Runner/Info.plist` に追加:
- NSCameraUsageDescription
- NSLocationWhenInUseUsageDescription
- NSMicrophoneUsageDescription

## 開発フロー

```bash
# 依存関係インストール
flutter pub get

# コード生成 (Riverpod/Freezed)
dart run build_runner build --delete-conflicting-outputs

# 実行
flutter run

# テスト
flutter test

# ビルド
flutter build apk --release
flutter build ios --release
```

## Week 別の実装進捗

- [x] Week 1-2: プロジェクト基盤（Flutter + Firebase + Riverpod）
- [ ] Week 3-4: ホーム・詳細・検索画面
- [ ] Week 5-6: マイプラン・Google Maps
- [ ] Week 7-8: 認証・リテンション・モデレーション
- [ ] Week 9-10: 統合テスト・バグ修正
- [ ] Week 11: リリース準備
- [ ] Week 12: MVP リリース
- [ ] Week 13-16: Camera AI 文化コンシェルジュ

## アーキテクチャ

- **State Management**: Riverpod 2.x
- **Navigation**: GoRouter
- **Backend**: Firebase (Auth / Firestore / Storage / FCM)
- **AI**: Claude Vision API (Week 13+)
- **Maps**: Google Maps Flutter
- **i18n**: easy_localization (EN/JA)

## Firestore データ構造

```
users/{uid}
curations/{id}
ratings/{userId}_{curationId}
plans/{planId}
posts/{postId}
phrases/{phraseId}
rankings/{rankingId}
```
