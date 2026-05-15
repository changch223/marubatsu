# Contract: GameEngine（UI 非依存ロジック）

本機能の「外部インターフェース」は、UI が依存する純粋ロジック型の公開 API である。
シグネチャと観測可能な振る舞いを契約として固定する（Principle II）。

## Mark

```swift
enum Mark { case empty, o, x
    var opponent: Mark            // o<->x, empty->empty
    func combine(placing: Mark) -> Mark
}
```

契約:
- `combine`: empty+P→P / 同+P→P.opponent / 異+P→P
- 全6入力（{empty,o,x}×{o,x}）が決定的。

## GameEngine

```swift
struct GameEngine {
    private(set) var board: [Mark]            // 9要素
    private(set) var placedThisRound: Set<Int>
    private(set) var currentPlayer: Mark      // .o 始まり
    private(set) var moveCount: Int           // 0...9
    private(set) var streak: Int              // 連勝数

    init()                                    // 空盤面・streak 0
    var availableCells: [Int]                 // 未着手マス
    var isRoundOver: Bool                     // moveCount == 9
    mutating func place(at index: Int) -> Bool // 不正手は false（無変更）
    func outcome() -> RoundOutcome?           // ラウンド終了時のみ非nil
    mutating func startNextRound(after: RoundOutcome) // win:盤面保持/敗北引分:streak確定
    mutating func resetSession()              // streak 0・空盤面
}
enum RoundOutcome { case userWin, userLoss, draw }
```

観測可能契約:
- C1: 空盤面に `.o` を置くと当該マスが `.o`（結合: empty）。
- C2: `.o` のマスにユーザーが置くと `.x`（同→相手）。
- C3: `.x` のマスにユーザーが置くと `.o`（異→placing）。
- C4: 同マスへ同ラウンド内 2 回目の `place` は `false` を返し状態不変。
- C5: `moveCount==9` で `isRoundOver==true`、`outcome()` が確定。
- C6: `outcome`: ○のみライン→`.userWin` / ×のみ→`.userLoss` / 双方or無→`.draw`。
- C7: `.userWin` 後 `startNextRound` で `board` 保持・`streak+1`・`moveCount=0`・
  `placedThisRound` 空・`currentPlayer=.o`。
- C8: `.userLoss`/`.draw` 後は `streak` が確定（増加しない）。
- C9: `resetSession` 後 `streak==0` かつ全マス `.empty`。

## AIPlayer

```swift
struct AIPlayer {
    static func difficultyLevel(forStreak streak: Int) -> Int   // 単調増加
    static func chooseMove(engine: GameEngine, level: Int) -> Int // availableCells から
}
```

観測可能契約:
- A1: `difficultyLevel` は streak に対し単調非減少。
- A2: `chooseMove` の返値は常に `engine.availableCells` に含まれる。
- A3: 最高 level では、ユーザーが各手で最善（その時点で○ライン最大化/×阻止）を
  指しても `outcome()` が `.userWin` にならない（代表シナリオで検証）。
