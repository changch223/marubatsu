---
description: "Task list for マルバツ・重ねがけ連勝モード"
---

# Tasks: マルバツ・重ねがけ連勝モード

**Input**: Design documents from `specs/001-marubatsu-endless-rematch/`
**Prerequisites**: plan.md, spec.md, data-model.md, contracts/game-engine.md, research.md

**Tests**: 憲法 Principle II（ゲームルールの正確性・NON-NEGOTIABLE）により、ロジック型は
XCTest で網羅検証する。テストタスクは必須として含む。

**Organization**: ユーザーストーリー単位でフェーズ分割。各フェーズは独立検証可能。

## Path Conventions

- 単一 Xcode プロジェクト。ロジック: `marubatsu/Models/`、状態: `marubatsu/ViewModels/`、
  UI: `marubatsu/Views/`、テスト: `marubatsuTests/marubatsuTests.swift`。

---

## Phase 1: Setup

- [X] T001 `marubatsu/Models/`・`marubatsu/ViewModels/`・`marubatsu/Views/` グループを作成し、Xcode プロジェクト `marubatsu.xcodeproj` のターゲット `marubatsu` に追加できる構成にする
- [X] T002 `marubatsu/Item.swift` を削除し、`marubatsu/marubatsuApp.swift` から SwiftData(`ModelContainer`/`Schema`/`Item`) を撤去して `WindowGroup { ContentView() }` のみの最小構成にする
- [X] T003 [P] `marubatsuTests/marubatsuTests.swift` を本機能用のテストファイル雛形（`import XCTest @testable import marubatsu`、空のテストクラス）に置換する

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: 全ストーリーが依存するコア型。完了まで US 実装に進めない。

- [X] T004 `marubatsu/Models/Mark.swift` に `enum Mark { case empty, o, x }`、`var opponent`、`func combine(placing:) -> Mark`（empty→placing / 同→opponent / 異→placing）を実装（data-model.md / contract C1–C3）
- [X] T005 [P] `marubatsuTests/marubatsuTests.swift` に `Mark.combine` 全6入力（{empty,o,x}×{o,x}）と `opponent` の単体テストを追加（contract C1–C3）
- [X] T006 `marubatsu/Models/GameEngine.swift` に `struct GameEngine`（`board:[Mark]`9要素, `placedThisRound:Set<Int>`, `currentPlayer`, `moveCount`, `streak`, `init()`, `availableCells`, `isRoundOver`）の骨格を実装（data-model.md / contract）

**Checkpoint**: `Mark` と `GameEngine` 骨格が存在し、テストターゲットがビルド可能。

---

## Phase 3: User Story 1 - 1ラウンド（1層）を遊んで勝敗が決まる (Priority: P1) 🎯 MVP

**Goal**: 空盤面で9手＝1ラウンド、終了時に3並びで勝敗判定。

**Independent Test**: 連勝/難易度/引き継ぎ無しで、9手→勝敗判定が単独で成立する。

- [X] T007 [US1] `GameEngine.place(at:)` を実装（未着手マスのみ可、結合適用、`placedThisRound`/`moveCount`/`currentPlayer` 更新、不正手は `false` 無変更）— `marubatsu/Models/GameEngine.swift`（contract C1–C4）
- [X] T008 [US1] `GameEngine` に 8 ライン定義と `hasLine(_:)`、`func outcome() -> RoundOutcome?`（○のみ→userWin / ×のみ→userLoss / 双方or無→draw、`moveCount==9` のみ非nil）と `enum RoundOutcome` を実装 — `marubatsu/Models/GameEngine.swift`（contract C5–C6）
- [X] T009 [P] [US1] `marubatsuTests/marubatsuTests.swift` に 9手ラウンド進行・二重着手無効(C4)・8勝利ライン・双方あり/なし引き分け の単体テストを追加（contract C5–C6）
- [X] T010 [US1] `marubatsu/Views/BoardView.swift` を作成（3×3 グリッド、各セル Button、○/✕記号で色非依存、44pt、`accessibilityLabel`/`Hint`、Dynamic Type）
- [X] T011 [US1] `marubatsu/ViewModels/GameViewModel.swift` に `@Observable` クラスを作成し `GameEngine` を保持、`tap(index:)` でユーザー着手→ラウンド終了時 `outcome` を保持
- [X] T012 [US1] `marubatsu/ContentView.swift` を `BoardView` ＋ ラウンド結果表示につなぎ、`GameViewModel` を `@State` で駆動（SwiftData 依存を含めない）

**Checkpoint**: 空盤面で1ラウンド遊び、3並びで勝敗が画面に出る（MVP）。

---

## Phase 4: User Story 2 - 置いた○×を残し次ラウンドを重ねる (Priority: P1)

**Goal**: ラウンド終了後も盤面保持、次ラウンドを重ねがけ（結合）で続行。

**Independent Test**: 第1ラウンド終了後に盤面が残り、第2ラウンドの着手が結合ルール通り。

- [X] T013 [US2] `GameEngine.startNextRound(after:)` を実装（`board` 保持、`placedThisRound` クリア、`moveCount=0`、`currentPlayer=.o`）— `marubatsu/Models/GameEngine.swift`（contract C7）
- [X] T014 [P] [US2] `marubatsuTests/marubatsuTests.swift` に 盤面引き継ぎ＋第2ラウンドの結合（○+○→×, ○+×→○, ×+×→○, ×+○→×）単体テストを追加（contract C2–C3, C7）
- [X] T015 [US2] `GameViewModel` をラウンド終了→`startNextRound` 連結に対応させ、結合後の盤面が `BoardView` に反映されるよう更新 — `marubatsu/ViewModels/GameViewModel.swift`

**Checkpoint**: 第1→第2ラウンドで盤面が引き継がれ、重ねがけ結果が表示される。

---

## Phase 5: User Story 3 - 勝つと連勝が積み上がる (Priority: P1)

**Goal**: ユーザー勝利で連勝+1・自動継続、敗北/引き分けで連勝終了。

**Independent Test**: 勝利→連勝+1→自動次ラウンド、敗北/引分→連勝停止。

- [X] T016 [US3] `GameEngine` に勝利時 `streak += 1`・敗北/引分で確定するロジックを `startNextRound`/`outcome` 連携で実装し `resetSession()` を追加 — `marubatsu/Models/GameEngine.swift`（contract C7–C9）
- [X] T017 [P] [US3] `marubatsuTests/marubatsuTests.swift` に 連勝増加・敗北/引分での停止・`resetSession` で streak0＆空盤面 の単体テストを追加（contract C8–C9）
- [X] T018 [US3] `GameViewModel` に現在連勝数の公開プロパティと勝利時の自動次ラウンド遷移を実装 — `marubatsu/ViewModels/GameViewModel.swift`
- [X] T019 [US3] `ContentView` に現在連勝数の常時表示（VoiceOver 読み上げ対象）を追加 — `marubatsu/ContentView.swift`

**Checkpoint**: 連勝が積み上がり、敗北/引分で止まることが画面で確認できる。

---

## Phase 6: User Story 4 - 連勝するほど AI が強くなる (Priority: P2)

**Goal**: 連勝で難易度上昇、最高段階はユーザーが勝てない。

**Independent Test**: level を上げると AI 着手品質が上がり、最高 level で勝率0%。

- [X] T020 [US4] `marubatsu/Models/AIPlayer.swift` に `static func difficultyLevel(forStreak:) -> Int`（単調増加）と `static func chooseMove(engine:level:) -> Int`（低level=ランダム比率高、高level=ヒューリスティック/探索、返値は必ず availableCells）を実装（research R5 / contract A1–A3）
- [X] T021 [P] [US4] `marubatsuTests/marubatsuTests.swift` に A1(単調非減少)・A2(返値∈availableCells)・A3(最高levelで代表シナリオ userWin にならない) の単体テストを追加
- [X] T022 [US4] `GameViewModel` の AI 着手を `AIPlayer.chooseMove` に接続し、`difficultyLevel(forStreak:)` を現在連勝数から決定 — `marubatsu/ViewModels/GameViewModel.swift`

**Checkpoint**: 連勝が進むと AI が強くなり、いずれ勝てなくなる。

---

## Phase 7: User Story 5 - 連勝終了時に結果と自己ベストが分かる (Priority: P2)

**Goal**: 連勝終了で今回連勝数＋自己ベスト表示、再起動後も保持、再挑戦可能。

**Independent Test**: 連勝終了→結果表示→自己ベスト更新→再起動後保持→再挑戦で0から。

- [X] T023 [US5] `GameViewModel` に `@AppStorage("bestStreak")` を追加し、連勝終了時 `bestStreak = max(bestStreak, finalStreak)` を実装 — `marubatsu/ViewModels/GameViewModel.swift`（research R1 / FR-015,016）
- [X] T024 [P] [US5] `marubatsuTests/marubatsuTests.swift` に 自己ベスト更新判定（更新あり/なし）の単体テストを追加（UserDefaults を suite 分離）
- [X] T025 [US5] `marubatsu/Views/ResultOverlayView.swift` を作成（今回連勝数・自己ベスト・「再挑戦」ボタン、アクセシブル、ライト/ダーク対応）
- [X] T026 [US5] `ContentView` で連勝終了時に `ResultOverlayView` を表示し、再挑戦で `resetSession()`＋連勝0＋空盤面に戻す — `marubatsu/ContentView.swift`（FR-017）

**Checkpoint**: 連勝終了で結果と自己ベストが出て、再挑戦できる。自己ベストは永続。

---

## Phase 8: Polish & Cross-Cutting

- [X] T027 [P] `marubatsu` スキームで iOS シミュレータ向けに `xcodebuild test` を実行し全 XCTest が緑であることを確認（quickstart.md 手順）
- [X] T028 [P] アクセシビリティ最終確認（VoiceOver ラベル/ヒント、Dynamic Type、44pt、色非依存、ライト/ダーク）を全画面で実施（Principle III）
- [X] T029 SC-002/SC-003 のタイミング（AI応手・次ラウンド開始が各2秒以内）を実機/シミュレータで確認

---

## Dependencies & Execution Order

- **Setup (P1: T001–T003)** → **Foundational (P2: T004–T006)** → 以降の US。
- US 完了順: **US1 (T007–T012)** → **US2 (T013–T015)** → **US3 (T016–T019)** →
  **US4 (T020–T022)** → **US5 (T023–T026)** → **Polish (T027–T029)**。
- US2/US3 は US1 のエンジンに依存。US4 は US3 の streak に依存。US5 は US3 に依存。
- Foundational 完了が全 US のブロッキング前提（特に T004 Mark, T006 GameEngine 骨格）。

## Parallel Opportunities

- T003 と T001/T002 は別ファイルで並行可。
- 各 US 内のテストタスク（[P]: T005, T009, T014, T017, T021, T024）は対応実装の直後に
  別関心で並行追加可能。
- Polish の T027/T028 は並行実行可。

## Implementation Strategy

- **MVP = Phase 1–3（US1）**: 空盤面で1ラウンド遊び勝敗が出る。
- 以降 US2→US3 でコア（重ねがけ＋連勝）完成（全 P1）。US4/US5（P2）で難易度と記録を付加。
- 各 Checkpoint で独立に動作確認しながら増分デリバリ。
