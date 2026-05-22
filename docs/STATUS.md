# プロジェクト現況 / Resume Notes — Max Hard マルバツ

最終更新: 2026-05-22

## ステータス

- **App Store: v1.0（ビルド2）レビュー承認 ✅（2026-05-22）。** ストア配信中／公開準備完了
  （リリース設定どおり）。Notes/返信文の履歴は `store/appstore_review_notes.md`。
- 次アクション: 公開後の運用フェーズ（下記「次の運用候補」参照）。
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

## 次の運用候補（任意）

1. **`main` へ PR ＆マージ**（マージ後 PRIVACY/Marketing URL を `main` パスへ差し替えて
   App Store Connect 側も更新するとブランチ削除リスクなし）。
2. **タグを切る**: `v1.0`（または `v1.0-build2`）でリリース履歴を残す。
3. **実機（Apple Intelligence 有効端末）で LLM 対戦の動作確認**（未検証）。
4. **英語版ストア記入文** `store/appstore_en.md` を作成（海外配信を強化するなら）。
5. プライバシーポリシーを GitHub Pages 等の素ページへ掲載し App Store URL を差し替え。
6. 任意: AI 難易度カーブ調整、UI/スクショ刷新、次バージョン機能の検討。

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
