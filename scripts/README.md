# セットアップスクリプト

CI（`.github/workflows/ios.yml`, `deploy.yml`）が必要とするFirebase設定・署名鍵・GitHub Secretsを、可能な限り自動化するためのスクリプト群です。**すべてあなたのローカル環境で実行してください**（Firebase/Apple/Google Playの各アカウントへのログインが必要なため、CI上やこのセッションからは実行できません）。

## 実行順序

```bash
# 0. 前提ツールのインストール（初回のみ）
npm install -g firebase-tools
dart pub global activate flutterfire_cli
brew install gh   # または https://cli.github.com/

# 1. 各サービスに一度だけ対話ログイン
firebase login
gh auth login

# 2. Androidリリース署名鍵を生成（初回のみ・既存があればスキップ）
./scripts/generate_android_keystore.sh

# 3. Firebaseプロジェクトの作成/設定・SHA登録・ルール/Functionsデプロイ
./scripts/setup_firebase.sh japan-explorer-prod

# 4. 生成されたファイル・入力した値をGitHub Secretsへ一括登録
./scripts/register_github_secrets.sh
```

`register_github_secrets.sh --list` で現在の登録状況だけ確認できます。`--dry-run` で実際に登録せず内容だけ確認できます。

## スクリプトでは自動化できない、手動が必要な部分

| 作業 | 理由 |
|---|---|
| Apple Developer Program加入（年間$99） | 本人確認・支払いが必須 |
| Google Play Consoleデベロッパー登録（$25） | 同上 |
| App Store Connect APIキーの発行 | AppleのUI操作でしか発行できない |
| Firebase Blazeプラン（従量課金）への切り替え | 請求先アカウントのリンクがコンソールUI操作前提 |
| Firebase Authentication で Google サインインを有効化 | コンソールUI操作 |
| iOS配布証明書・プロビジョニングプロファイルの作成 | Apple Developer Portalでの発行が前提（`fastlane match`導入でチーム内共有・自動更新は可能） |

これらを終えたら、生成されたファイル（`.p12`, `.mobileprovision`, `AuthKey_*.p8`, Play ConsoleサービスアカウントJSON）のパスを環境変数で `register_github_secrets.sh` に渡すか、対話プロンプトで入力してください（スクリプト先頭のコメントに変数名一覧があります）。
