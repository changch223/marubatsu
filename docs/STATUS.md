# プロジェクト現況 / Resume Notes — Max Hard マルバツ

最終更新: 2026-05-17

## ステータス

- **App Store: ビルド2をアップロードし Guideline 2.1 に返信済み → レビュー結果待ち
  （2026-05-17 時点）。** ビルド2は未使用 Game Center エンタイトルメント削除済み
  （`CURRENT_PROJECT_VERSION = 2`、`MARKETING_VERSION = 1.0`）。Notes/返信文は
  `store/appstore_review_notes.md`。
- 次アクション: レビュー結果が来たら対応（承認→公開設定／リジェクト→指摘箇所修正）。
- 作業ブランチ: `001-marubatsu-endless-rematch`（`main` 未マージ）。
- リポジトリ: https://github.com/changch223/marubatsu
- テスト: `xcodebuild test`（iOS 26.5 シミュレータ）**全25件 緑**。
  ※ シミュレータは Apple Intelligence 非対応のため、AI は α-β フォールバック経路で検証。
  LLM 経路は **Apple Intelligence 有効の実機でのみ動作・要確認**。

## 完成しているもの

- ゲーム本体（SwiftUI）: 一次仕様は `specs/001-marubatsu-endless-rematch/spec.md`。
  - N×N 可変盤（初期4×4／2連勝ごとに+1拡張・既存温存／最大10×10で2連勝＝完全勝利／敗北で4×4）
  - 勝利＝自分の N連ライン同時2本／結合ルール／着手禁止（直前マス＋当手番既出）
  - 自動均衡（各着手後に再計算: O は O≥X+1、X は X≥O・最低1手・1ターン16手上限）
  - AI: 対応端末は Apple Intelligence（FoundationModels）、非対応は決定的α-βへ自動フォールバック
  - UX: O即反映→「AI考え中」→AI一歩ずつ→勝利2ラインハイライト→結果/完全勝利（Apple HIG）
- 表示名「Max Hard マルバツ」、アイコン（最高難度デザイン）、アクセントカラー。
- ドキュメント: `README.md`、`PRIVACY.md`（日英）、`store/appstore_ja.md`（ストア記入文一式）。
- App Store 用スクリーンショット: `screen/1.png` `2.png` `3.png`。

## 次に再開するときの候補タスク

1. **実機（Apple Intelligence 有効）で LLM 対戦を実動作確認**（最重要・未検証）。
2. 審査結果対応（リジェクト時の修正／メタデータ調整）。
3. `main` へ PR 作成・マージ（マージ後 PRIVACY/Marketing URL を `main` パスへ差し替え）。
4. 英語版ストア記入文（`store/appstore_en.md`）作成。
5. プライバシーポリシーを GitHub Pages 等の素のページへ掲載し URL 差し替え。
6. 任意: AI 難易度カーブ調整、UI 微調整、スクショ刷新。

## ビルド/テスト

```bash
xcodebuild test  -project marubatsu.xcodeproj -scheme marubatsu \
  -destination 'platform=iOS Simulator,name=iPhone 17'
xcodebuild build -project marubatsu.xcodeproj -scheme marubatsu \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

## 注意

- `marubatsu.xcodeproj/project.pbxproj` と `marubatsu/marubatsu.entitlements` は
  Xcode により更新済み（表示名・エンタイトルメント）。リバートしないこと。
- 当環境ではシミュレータが不安定になった履歴あり。失敗時は
  `xcrun simctl shutdown all` → 再ブート、または DerivedData 削除で再実行。
