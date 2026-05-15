# Quickstart: マルバツ・重ねがけ連勝モード

## ビルド & 実行

```bash
# iOS シミュレータでビルド＆テスト
xcodebuild test \
  -project marubatsu.xcodeproj \
  -scheme marubatsu \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

Xcode で開く場合: `marubatsu.xcodeproj` を開き iPhone シミュレータで Run。

## 遊び方

1. 3×3 盤面。あなたは ○、AI は ×。常にあなたが先手。
2. 空きマス（または重ねたいマス）をタップ。既にマークがあれば結合ルールで変化:
   - ○の上に○ → ×／○の上に× → ○／×の上に× → ○／×の上に○ → ×
3. そのラウンドで全9マスに1回ずつ置くとラウンド終了。終了時の盤面で○が3並び＆×が
   3並びでなければ **あなたの勝ち**。
4. 勝つと連勝+1、盤面はそのまま次ラウンドへ。負け／引き分けで連勝終了。
5. 連勝が進むほど AI は強くなる。連勝終了で今回連勝数と自己ベストが表示される。

## 検証ポイント（受け入れ）

- 結合3パターンが正しい（research R2 / contract C1–C3）。
- 二重着手は無効（C4）。
- 9手でラウンド終了し勝敗判定（C5–C6）。
- 勝利で盤面引き継ぎ＆連勝+1、敗北/引分で連勝終了（C7–C8）。
- 自己ベストがアプリ再起動後も保持（@AppStorage）。
- 最低難易度は勝てる／最高難易度は勝てない（A1–A3）。

## テストの所在

- `marubatsuTests/marubatsuTests.swift` … GameEngine / AIPlayer ユニットテスト。
