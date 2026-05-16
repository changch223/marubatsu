//
//  AIPlayer.swift
//  marubatsu
//
//  本ゲーム専用の強力 AI（UI 非依存・決定的）。
//
//  戦略の要点（このルールでの勝ち方 / 4x4 4目）:
//  - 自分の (winLength-1) 連は残り1つが空でも相手でも1手必殺（空→自分 / 相手→奪取）。
//  - 相手の脅威は「石を奪取して壊す」か「自分が先に並べる」でしか止まらない。
//  - 自分の石の上に置くと相手の石に変わる（自滅）→ 基本は空マスで伸ばす。
//  - 空マスで同時2脅威（フォーク）を作れば相手は1つしか潰せず勝てる。
//  実装: 反復深化 α-β＋置換表＋脅威ベース評価＋静止探索＋手順並べ替え。
//

import Foundation

enum AIPlayer {

    static let maxLevel = 5

    /// 互換のため残置（強さには未使用：AI は常に最強）。
    static func difficultyLevel(forStreak streak: Int) -> Int {
        max(0, min(streak, maxLevel))
    }

    private static let winScore = 1_000_000
    // 4x4 は分岐16・実質無限深さ。応答性優先で控えめに（強いが完全読みでない＝
    // 盤が広いぶん人間に勝機あり）。決定的（ノード予算で再現可能）。
    private static let maxDepth = 5
    private static let nodeBudget = 45_000

    /// 相手の直前マスを除いた合法手。
    private static func legalCells(_ e: GameEngine) -> [Int] {
        (0..<e.cellCount).filter { !e.forbiddenCells.contains($0) }
    }

    /// AI（×）の着手を1つ返す。返値は常に合法手。連勝に関係なく常に最強。
    static func chooseMove(engine: GameEngine,
                           level: Int = 0,
                           rng: () -> Double = { 0 }) -> Int {
        _ = level; _ = rng
        let legal = legalCells(engine)
        guard let firstLegal = legal.first else { return 0 }

        // 1) 即勝ち手があれば即取る。
        for c in legal {
            var e = engine
            if e.place(at: c), e.outcome() == .userLoss { return c }
        }

        // 2) 反復深化 α-β（ノード上限まで深掘り＝決定的・再現可能）。
        var nodes = 0
        var table: [Int: (depth: Int, value: Int)] = [:]
        var bestMove = firstLegal

        for depth in 1...maxDepth {
            if nodes > nodeBudget { break }
            var localBest = firstLegal
            var localValue = Int.min
            var alpha = -winScore - maxDepth
            let beta = winScore + maxDepth
            let ordered = orderedMoves(engine, preferred: bestMove)
            for c in ordered {
                var child = engine
                guard child.place(at: c) else { continue }
                let v = child.isRoundOver
                    ? terminal(child, ply: 1)
                    : search(child, depth: depth - 1, ply: 1,
                             alpha: alpha, beta: beta,
                             nodes: &nodes, table: &table)
                if v > localValue {
                    localValue = v
                    localBest = c
                }
                alpha = max(alpha, v)
            }
            // この深さを予算内で完了した場合のみ採用（部分結果は捨てる）。
            if nodes <= nodeBudget {
                bestMove = localBest
                if localValue >= winScore { break }   // 必勝確定
            } else {
                break
            }
        }
        return bestMove
    }

    // MARK: - 探索（X 視点 minimax + α-β）

    private static func terminal(_ e: GameEngine, ply: Int) -> Int {
        switch e.roundResult {
        case .userLoss: return winScore - ply     // X 勝ち（早いほど高い）
        case .userWin:  return -(winScore - ply)  // O 勝ち
        case nil:       return 0
        }
    }

    /// X 視点スコア（X が最大化、O が最小化）。
    private static func search(_ e: GameEngine, depth: Int, ply: Int,
                               alpha: Int, beta: Int,
                               nodes: inout Int,
                               table: inout [Int: (depth: Int, value: Int)]) -> Int {
        nodes += 1
        if e.isRoundOver { return terminal(e, ply: ply) }
        if depth <= 0 || nodes > nodeBudget {
            return quiescence(e)
        }

        let key = stateKey(e)
        if let hit = table[key], hit.depth >= depth { return hit.value }

        let maximizing = (e.currentPlayer == .x)
        var a = alpha
        var b = beta
        var best = maximizing ? Int.min : Int.max

        for c in orderedMoves(e, preferred: nil) {
            var child = e
            guard child.place(at: c) else { continue }
            let v = child.isRoundOver
                ? terminal(child, ply: ply + 1)
                : search(child, depth: depth - 1, ply: ply + 1,
                         alpha: a, beta: b, nodes: &nodes, table: &table)
            if maximizing {
                best = max(best, v); a = max(a, best)
            } else {
                best = min(best, v); b = min(b, best)
            }
            if a >= b { break }
        }
        if best == Int.min || best == Int.max { best = quiescence(e) }
        table[key] = (depth, best)
        return best
    }

    /// 静止評価: 手番側が即勝ち手を持つなら勝ち確定として返す。
    private static func quiescence(_ e: GameEngine) -> Int {
        let mover = e.currentPlayer
        for c in legalCells(e) {
            var n = e
            if n.place(at: c), let r = n.roundResult {
                if (mover == .x && r == .userLoss) || (mover == .o && r == .userWin) {
                    return mover == .x ? (winScore - 1) : -(winScore - 1)
                }
            }
        }
        return evaluate(e)
    }

    // MARK: - 評価（X 視点・脅威ベース）

    /// 勝利＝N連ラインを2本同時保有。完成ライン数とリーチを重視。
    private static func evaluate(_ e: GameEngine) -> Int {
        let len = e.winLength
        var score = 0
        var xFull = 0, oFull = 0
        for line in e.lines {
            var xc = 0, oc = 0
            for i in line {
                switch e.board[i] {
                case .x: xc += 1
                case .o: oc += 1
                case .empty: break
                }
            }
            if xc == len { xFull += 1; score += 30_000 }
            else if oc == len { oFull += 1; score -= 30_000 }
            else if xc == len - 1 && oc == 0 { score += 400 }
            else if oc == len - 1 && xc == 0 { score -= 400 }
            else if xc > 0 && oc == 0 { score += xc * xc }
            else if oc > 0 && xc == 0 { score -= oc * oc }
        }
        // 完成1本は勝利(2本)に王手＝極めて有利。
        if xFull >= 1 { score += 15_000 }
        if oFull >= 1 { score -= 15_000 }
        return score
    }

    // MARK: - 手順並べ替え（α-β 効率化）

    private static func orderedMoves(_ e: GameEngine, preferred: Int?) -> [Int] {
        let mover = e.currentPlayer
        let cells = legalCells(e)
        // 各手を簡易評価（即勝ち > 結果評価）。
        let scored: [(c: Int, s: Int)] = cells.map { c in
            var n = e
            guard n.place(at: c) else { return (c, Int.min) }
            if let r = n.roundResult {
                let win = (mover == .x && r == .userLoss) || (mover == .o && r == .userWin)
                return (c, win ? 10_000_000 : -10_000_000)
            }
            // X 視点評価を手番側視点へ。
            let v = evaluate(n) * (mover == .x ? 1 : -1)
            return (c, v)
        }
        var order = scored.sorted { $0.s > $1.s }.map { $0.c }
        if let p = preferred, let idx = order.firstIndex(of: p) {
            order.remove(at: idx)
            order.insert(p, at: 0)
        }
        return order
    }

    // MARK: - 置換表キー

    private static func markCode(_ m: Mark) -> Int {
        switch m { case .empty: return 0; case .o: return 1; case .x: return 2 }
    }

    private static func stateKey(_ e: GameEngine) -> Int {
        // 盤が最大10×10（100マス）まで拡張するため Hasher で安全にハッシュ。
        var h = Hasher()
        for m in e.board { h.combine(markCode(m)) }
        h.combine(e.currentPlayer == .x)
        h.combine(e.lastMove ?? -1)
        for c in e.forbiddenCells.sorted() { h.combine(c) }
        h.combine(e.movesThisTurn)
        return h.finalize()
    }
}
