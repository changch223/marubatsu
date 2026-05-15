# Implementation Plan: マルバツ・重ねがけ連勝モード

**Branch**: `001-marubatsu-endless-rematch` | **Date**: 2026-05-16 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `specs/001-marubatsu-endless-rematch/spec.md`

## Summary

3×3 盤面で○（ユーザー）対×（AI）。1ラウンド＝全9マスに1回ずつ重ねて置く（計9手、
ユーザー先手で5手・AI4手）。既存マスへ重ねると結合ルール（同じ→相手／相手→自分／空→
そのまま）でマスが変化。ラウンド終了時の3並びで勝者決定、盤面はリセットせず次ラウンドへ
引き継ぐ。ユーザー勝利で連勝+1、敗北/引き分けで途切れ、自己ベストを永続保存。AI は連勝で
強化され最高段階ではユーザーが勝てない。技術アプローチ: UI 非依存の純粋ロジック型
`GameEngine`／`AIPlayer` を XCTest で網羅検証し、`@Observable` ビューモデル＋SwiftUI で
描画、自己ベストは `@AppStorage` で永続化。

## Technical Context

**Language/Version**: Swift 5.0  
**Primary Dependencies**: SwiftUI（標準のみ。サードパーティ依存なし）  
**Storage**: 自己ベスト（単一 Int）のみ — `@AppStorage`（UserDefaults）。SwiftData/Item の
雛形は本機能に不要のため撤去（進行・履歴の永続化はスコープ外）  
**Testing**: XCTest（純粋ロジック型を UI 非依存でユニットテスト）  
**Target Platform**: iOS 26.5（iPhone）。コードは macOS/visionOS でもビルド可能だが検証は iOS  
**Project Type**: mobile-app（単一 Xcode プロジェクト、SwiftUI）  
**Performance Goals**: 着手→AI応手の反映 2秒以内、勝利→次ラウンド自動開始 2秒以内、60fps UI  
**Constraints**: 完全オフライン、外部ネットワーク依存なし、ローカル永続のみ  
**Scale/Scope**: 単一ユーザー・ローカル。盤面 3×3 固定、画面 1〜2（対戦＋結果オーバーレイ）

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. SwiftUI ネイティブパターン優先**: ✅ SwiftUI ビュー＋`@Observable` ビューモデル、
  自己ベストは `@AppStorage`。サードパーティ依存ゼロ。SwiftData は本機能に不要なため
  使用しない（憲法の「永続化が必要な場合は SwiftData」は進行・履歴向け。単一スカラの
  設定値は `@AppStorage` が標準かつ単純で Principle I に合致）。違反なし。
- **II. ゲームルールの正確性（NON-NEGOTIABLE）**: ✅ 結合ルール・ラウンド終了・3並び
  判定・連勝遷移を UI 非依存の純粋型 `GameEngine` に実装し、XCTest で全分岐を網羅
  （結合3パターン×双方向、8勝利ライン、双方あり/なし引き分け、連勝増減）。
- **III. UX とアクセシビリティ品質**: ✅ ○/✕ は記号で色非依存、各セルに VoiceOver
  ラベル、最小タップ 44pt、Dynamic Type、ライト/ダーク対応。主要操作（着手・再挑戦）は
  1〜2タップ。

**結果: 違反なし。Complexity Tracking 記入不要。**

## Project Structure

### Documentation (this feature)

```text
specs/001-marubatsu-endless-rematch/
├── plan.md              # This file
├── spec.md              # Feature spec
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   └── game-engine.md   # 公開ロジック型の契約（UIコントラクト）
├── checklists/
│   └── requirements.md  # spec 品質チェックリスト
└── tasks.md             # /speckit-tasks 出力（plan では作らない）
```

### Source Code (repository root)

```text
marubatsu/
├── marubatsuApp.swift        # App エントリ（SwiftData/Item を撤去し簡素化）
├── ContentView.swift         # 対戦画面（盤面＋連勝表示＋結果オーバーレイ）
├── Models/
│   ├── Mark.swift            # enum Mark { empty, o, x } ＋ opponent/combine
│   ├── GameEngine.swift      # 純粋ロジック: 盤面・ラウンド・結合・勝敗・連勝
│   └── AIPlayer.swift        # 連勝→難易度の着手選択（純粋）
├── ViewModels/
│   └── GameViewModel.swift   # @Observable: GameEngine 駆動＋@AppStorage 自己ベスト
├── Views/
│   ├── BoardView.swift       # 3×3 グリッド（アクセシブル）
│   └── ResultOverlayView.swift # 連勝終了時の結果＋自己ベスト＋再挑戦
└── (Item.swift は削除)

marubatsuTests/
└── marubatsuTests.swift      # GameEngine / AIPlayer のユニットテスト（Principle II）

marubatsuUITests/             # 既存雛形のまま（変更なし）
```

**Structure Decision**: 既存の単一 Xcode プロジェクト（mobile-app）を踏襲。ロジックは
`Models/` の純粋型に集約し UI から完全分離（Principle II）。`ViewModels/` で `@Observable`
状態管理、`Views/` で SwiftUI 描画（Principle I）。SwiftData 雛形（`Item.swift` と
`ModelContainer`）は本機能で不要のため撤去し、永続は `@AppStorage` の単一値に限定。

## Complexity Tracking

> Constitution Check に違反なし — 記入不要。
