# Phase 1 Data Model: マルバツ・重ねがけ連勝モード

## Mark (enum)

| 値 | 意味 |
|----|------|
| `.empty` | 空マス |
| `.o` | ユーザーのマーク |
| `.x` | AI のマーク |

- `opponent`: `.o → .x`, `.x → .o`, `.empty → .empty`
- `combine(placing:)`（既存マス self に placing を重ねた結果）:
  - `self == .empty` → `placing`
  - `self == placing` → `placing.opponent`
  - その他（self == placing.opponent）→ `placing`

## Board (value type)

- `cells: [Mark]`（長さ 9、index 0..8 を 3×3 にマップ。row=i/3, col=i%3）
- 派生: `lines() -> [[Int]]`（8 ライン固定）／`hasLine(_ mark: Mark) -> Bool`
- 不変条件: 要素数は常に 9。

## RoundState (value type)

- `board: Board` — ラウンド跨ぎで引き継がれる現在盤面
- `placedThisRound: Set<Int>` — 当ラウンドで着手済みのマス
- `currentPlayer: Mark`（`.o` 始まり、交互）
- `moveCount: Int`（0..9）
- 状態遷移:
  - `place(at:)`: `index ∉ placedThisRound` のときのみ有効 → `board.cells[index] =
    board.cells[index].combine(placing: currentPlayer)`、`placedThisRound.insert`、
    `moveCount += 1`、`currentPlayer.toggle()`
  - `moveCount == 9` → ラウンド終了 → `RoundOutcome` 算出

## RoundOutcome (enum)

| 値 | 条件 |
|----|------|
| `.userWin` | ○ライン有り かつ ×ライン無し |
| `.userLoss` | ×ライン有り かつ ○ライン無し |
| `.draw` | 双方ライン有り または 双方無し |

## StreakSession (value type)

- `streak: Int`（現在連勝数、初期 0）
- 遷移:
  - `.userWin` → `streak += 1`、盤面引き継ぎで次ラウンド開始（`placedThisRound`
    クリア、`currentPlayer = .o`、`moveCount = 0`、`board` は保持）
  - `.userLoss` / `.draw` → 連戦終了。`finalStreak = streak`
- `reset()`: `streak = 0`、`board` 空、新規連戦

## BestStreakRecord (persisted scalar)

- `bestStreak: Int`（`@AppStorage("bestStreak")`、初期 0、アプリ再起動後も保持）
- 更新: 連戦終了時 `bestStreak = max(bestStreak, finalStreak)`

## AIDifficulty

- `level(forStreak:) -> Int`（連勝数に単調増加）
- `chooseMove(round:level:) -> Int`（未着手マスから選択）
  - 低 level: ランダム比率高（ヒューリスティック弱）
  - level 上昇: ランダム比率 → 0、ヒューリスティック/探索強化
  - 最高 level: 決定的探索で「ユーザーが勝てない」着手（観測要件: 勝率0%）

## エンティティ関係

```text
StreakSession 1—1 RoundState 1—1 Board 1—* Mark(9)
StreakSession ──更新──> BestStreakRecord(@AppStorage)
RoundState ──AI手──> AIDifficulty
RoundState ──終了──> RoundOutcome ──> StreakSession 遷移
```
