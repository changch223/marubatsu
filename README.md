# Max Hard マルバツ

> 連勝で巨大化する **最高難度の重ねマルバツ**（iOS / SwiftUI）

リポジトリ: https://github.com/changch223/marubatsu
（開発ブランチ: `001-marubatsu-endless-rematch`）

> ⚠️ これは叩き（ドラフト）です。仕様は `specs/001-marubatsu-endless-rematch/spec.md` が一次情報。

---

## 概要

「マルバツ」をベースに、**重ねがけ**・**自動均衡**・**連勝で盤が拡大**する一風変わった
対 AI 連勝チャレンジ。AI は連勝に依存せず常に最強（決定的）。どこまで勝ち続け、
最後の **10×10 を制覇（完全勝利）** できるかを競う。

- プラットフォーム: iOS（SwiftUI、Swift Testing）。コードは macOS/visionOS でもビルド可。
- 要件: Xcode 26 系 / iOS 26.5 SDK（`IPHONEOS_DEPLOYMENT_TARGET = 26.0`）。
- 永続化: 自己ベスト（最高連勝数）のみ（`UserDefaults`）。完全オフライン。

## ルール（現行仕様）

- 盤は **N×N**（初期 4×4、最大 10×10）。○=あなた / ✕=AI で **交互に着手**。
- **結合ルール**（重ね置き時）:
  - 空マス → 自分の印
  - 自分の印に重ねる → 相手の印に変わる（自滅）
  - 相手の印に重ねる → 自分の印（**奪取**）
- **勝利**: タテ/ヨコ/主対角の **N連ラインを同時に2本以上** 完成した瞬間に決着。
  1本では決着せず、**引き分けは無い**（どちらかが2本作るまで続行）。
- **着手禁止**: 相手の直前マス／その手番で既に置いたマス（同マスは1ターン1回）。
- **自動均衡（動的再計算）**: 各着手後に石数を数え直し、
  - AI(×) は `X ≥ O` になるまで連続着手
  - あなた(○) は `O ≥ X+1` になるまで連続着手
  - 最低1手、1ターン上限16手（自滅の無限ループ防止）。
- **連勝で拡大**: ユーザーが勝つと連勝+1・先手交代し、盤面（○×・配置者）を引き継ぎ。
  **2連勝ごとに盤を +1拡張**（既存マークは左上に温存）。
- **完全勝利**: 10×10 で2連勝＝ゲームクリア。**ユーザー敗北で連戦終了**（再挑戦は 4×4 から）。

## AI

- 既定は本ゲーム専用の**決定的な強力探索 AI**（反復深化 α-β＋脅威ベース評価＋
  置換表[Hasher]＋静止探索）。重い探索はバックグラウンド実行。
- Apple Intelligence の **FoundationModels** 実装も同梱（既定では未使用、差し替え可能）。

## UX

ユーザー着手を即反映 → 「AI が考え中…」→ AI の手を一歩ずつ更新 →
決着時は勝利2ラインをハイライト → 結果／完全勝利を表示。Apple HIG 準拠
（マテリアル/Dynamic Type/VoiceOver/ライト・ダーク）、アプリアイコン同梱。

## ビルド & テスト

```bash
# テスト（iOS シミュレータ）
xcodebuild test \
  -project marubatsu.xcodeproj -scheme marubatsu \
  -destination 'platform=iOS Simulator,name=iPhone 17'

# ビルドのみ
xcodebuild build \
  -project marubatsu.xcodeproj -scheme marubatsu \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

Xcode で `marubatsu.xcodeproj` を開いて Run も可。

## 構成

```
marubatsu/
  Models/      Mark, GameEngine（純粋ロジック）, AIPlayer, AIMoveProvider,
               FoundationModelsAIProvider, BestStreakStore, CellDisplay
  ViewModels/  GameViewModel（@Observable / @MainActor）
  Views/       BoardView, ResultOverlayView
  ContentView.swift / marubatsuApp.swift
marubatsuTests/  Swift Testing（ゲームロジック網羅・25 ケース）
specs/001-marubatsu-endless-rematch/  spec / plan / tasks / research ほか
```

設計方針はリポジトリ内の `.specify/memory/constitution.md`（SwiftUI ネイティブ／
ゲームルールの正確性をテストで担保／UX・アクセシビリティ）に準拠。

## ステータス

- 全テスト緑（`xcodebuild test`、iOS 26.5 シミュレータ）。
- 仕様は反復改訂中。最新は `spec.md` を参照。

## ライセンス

未定（TBD）。
