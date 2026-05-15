//
//  AIPlayer.swift
//  marubatsu
//
//  連勝で強くなる AI（UI 非依存 / 純粋）。ゲームは無制限重ねがけで深さ無限のため
//  全探索は不可 → 深さ制限 α-β 探索＋評価関数。低 level はランダム比率高。
//

import Foundation

enum AIPlayer {

    /// 最高難易度レベル。
    static let maxLevel = 5

    /// 連勝数 → 難易度レベル（単調非減少 / contract A1）。
    static func difficultyLevel(forStreak streak: Int) -> Int {
        max(0, min(streak, maxLevel))
    }

    /// AI（×）の着手を1つ返す。返値は常に 0..8 の合法手（A2）。
    static func chooseMove(engine: GameEngine,
                           level: Int,
                           rng: () -> Double = { Double.random(in: 0..<1) }) -> Int {
        let cells = Array(0..<9)

        // 1) 即勝ち手があれば取る。
        for c in cells {
            var e = engine
            if e.place(at: c), e.outcome() == .userLoss { return c }
        }

        // 2) 低難易度はランダム比率高。
        let clamped = max(0, min(level, maxLevel))
        let randomChance = Double(maxLevel - clamped) / Double(maxLevel) // level0→1.0
        if clamped < maxLevel, rng() < randomChance {
            return cells[Int(rng() * 9) % 9]
        }

        // 3) 深さ制限 α-β 探索で最善手。
        let depth = clamped >= maxLevel ? 4 : max(1, clamped)
        var bestCell = 0
        var bestValue = Int.min
        for c in cells {
            var e = engine
            guard e.place(at: c) else { continue }
            let v = e.isRoundOver
                ? terminalScore(e)
                : search(e, depth: depth - 1, alpha: Int.min + 1, beta: Int.max - 1)
            if v > bestValue {
                bestValue = v
                bestCell = c
            }
        }
        return bestCell
    }

    // MARK: - 探索（X 視点でスコア最大化）

    private static func terminalScore(_ e: GameEngine) -> Int {
        switch e.roundResult {
        case .userLoss: return 1_000_000   // X 勝ち
        case .userWin:  return -1_000_000  // O 勝ち
        case nil:       return 0
        }
    }

    private static func search(_ e: GameEngine, depth: Int, alpha: Int, beta: Int) -> Int {
        if e.isRoundOver { return terminalScore(e) }
        if depth == 0 { return evaluate(e) }

        var a = alpha
        var b = beta
        let maximizing = (e.currentPlayer == .x)
        if maximizing {
            var best = Int.min
            for c in 0..<9 {
                var n = e
                guard n.place(at: c) else { continue }
                best = max(best, search(n, depth: depth - 1, alpha: a, beta: b))
                a = max(a, best)
                if a >= b { break }
            }
            return best
        } else {
            var best = Int.max
            for c in 0..<9 {
                var n = e
                guard n.place(at: c) else { continue }
                best = min(best, search(n, depth: depth - 1, alpha: a, beta: b))
                b = min(b, best)
                if a >= b { break }
            }
            return best
        }
    }

    /// X 視点の評価。3並びは terminal で処理済みなので 1〜2 個の脅威を評価。
    private static func evaluate(_ e: GameEngine) -> Int {
        var score = 0
        for line in GameEngine.lines {
            var xc = 0, oc = 0
            for i in line {
                switch e.board[i] {
                case .x: xc += 1
                case .o: oc += 1
                case .empty: break
                }
            }
            if oc == 0 { score += (xc == 2 ? 50 : xc == 1 ? 5 : 0) }
            if xc == 0 { score -= (oc == 2 ? 50 : oc == 1 ? 5 : 0) }
        }
        return score
    }
}
