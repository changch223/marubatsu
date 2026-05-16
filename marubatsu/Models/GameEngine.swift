//
//  GameEngine.swift
//  marubatsu
//
//  連勝でサイズが拡張する重ねがけマルバツの純粋ロジック（Principle II）。
//  ・盤は N×N。勝利＝自分の「Nマス連ライン」を同時に2本（縦横＋主対角線2本）
//  ・2連勝ごとに N が +1（4→5→…→10）。昇格時は既存の○×を左上に温存して拡張
//  ・10×10 で2連勝＝完全勝利。敗北で連戦終了（次回は 4×4 から）
//  ・交互着手 / 重ね置き可 / 結合ルール / 自動均衡（動的再計算）/ 着手禁止集合
//

import Foundation

enum RoundOutcome: Equatable, Sendable {
    case userWin
    case userLoss
}

struct GameEngine: Equatable, Sendable {

    static let minSize = 4
    static let maxSize = 10
    static let linesToWin = 2

    /// 連勝数 → 盤サイズ（2連勝ごとに+1、最大10）。
    static func size(forStreak streak: Int) -> Int {
        min(maxSize, minSize + streak / 2)
    }

    /// N×N の勝利ライン（N行 + N列 + 主対角線2本、各長さN）。
    static func makeLines(_ n: Int) -> [[Int]] {
        var ls: [[Int]] = []
        for r in 0..<n { ls.append((0..<n).map { r * n + $0 }) }
        for c in 0..<n { ls.append((0..<n).map { $0 * n + c }) }
        ls.append((0..<n).map { $0 * n + $0 })
        ls.append((0..<n).map { $0 * n + (n - 1 - $0) })
        return ls
    }

    private(set) var size: Int
    private(set) var board: [Mark]
    private(set) var placers: [Mark?]
    private(set) var lines: [[Int]]
    private(set) var firstPlayer: Mark
    private(set) var currentPlayer: Mark
    private(set) var moveCount: Int
    private(set) var streak: Int
    private(set) var lastMove: Int?
    private(set) var roundResult: RoundOutcome?
    private(set) var movesThisTurn: Int
    private(set) var placedThisTurn: Set<Int>

    var cellCount: Int { size * size }
    var winLength: Int { size }
    var maxMovesPerTurn: Int { cellCount }

    /// 10×10 で2連勝＝完全勝利（昇格上限を超えた）。
    var isCompleteVictory: Bool { (Self.minSize + streak / 2) > Self.maxSize }

    init(size: Int = GameEngine.minSize) {
        self.size = size
        board = Array(repeating: .empty, count: size * size)
        placers = Array(repeating: nil, count: size * size)
        lines = GameEngine.makeLines(size)
        firstPlayer = .o
        currentPlayer = .o
        moveCount = 0
        streak = 0
        lastMove = nil
        roundResult = nil
        movesThisTurn = 0
        placedThisTurn = []
    }

    // MARK: - 集計

    func markCount(_ mark: Mark) -> Int {
        guard mark != .empty else { return 0 }
        return board.reduce(0) { $0 + ($1 == mark ? 1 : 0) }
    }

    func hasLine(_ mark: Mark) -> Bool {
        guard mark != .empty else { return false }
        return lines.contains { line in line.allSatisfy { board[$0] == mark } }
    }

    func lineCount(_ mark: Mark) -> Int {
        guard mark != .empty else { return 0 }
        return lines.reduce(0) { acc, line in
            acc + (line.allSatisfy { board[$0] == mark } ? 1 : 0)
        }
    }

    func completedLines(_ mark: Mark) -> [[Int]] {
        guard mark != .empty else { return [] }
        return lines.filter { line in line.allSatisfy { board[$0] == mark } }
    }

    var isRoundOver: Bool { roundResult != nil }

    /// この着手で置けないマス: 相手の直前マス＋この手番で既に置いたマス。
    var forbiddenCells: Set<Int> {
        var s = placedThisTurn
        if let l = lastMove { s.insert(l) }
        return s
    }

    /// UI 用: 現手番で目標到達まで残り何手か（最低1、ラウンド終了時0）。
    var movesRemainingThisTurn: Int {
        guard !isRoundOver else { return 0 }
        let o = markCount(.o)
        let x = markCount(.x)
        let need = currentPlayer == .o ? (x - o) + 1 : (o - x)
        return max(1, need)
    }

    // MARK: - 進行

    private func turnSatisfied(for player: Mark) -> Bool {
        let o = markCount(.o)
        let x = markCount(.x)
        return player == .o ? (o >= x + 1) : (x >= o)
    }

    private mutating func beginTurn(for player: Mark) {
        currentPlayer = player
        movesThisTurn = 0
        placedThisTurn = []
    }

    /// 着手。重ね置き可。禁止マス／ラウンド確定後は不可。
    @discardableResult
    mutating func place(at index: Int) -> Bool {
        guard (0..<cellCount).contains(index), roundResult == nil else { return false }
        if forbiddenCells.contains(index) { return false }
        let mover = currentPlayer

        board[index] = board[index].combine(placing: mover)
        placers[index] = mover
        lastMove = index
        placedThisTurn.insert(index)
        moveCount += 1

        if lineCount(mover) >= Self.linesToWin {
            roundResult = (mover == .o) ? .userWin : .userLoss
            return true
        } else if lineCount(mover.opponent) >= Self.linesToWin {
            roundResult = (mover.opponent == .o) ? .userWin : .userLoss
            return true
        }

        movesThisTurn += 1
        if turnSatisfied(for: mover) || movesThisTurn >= maxMovesPerTurn {
            beginTurn(for: mover.opponent)
        }
        return true
    }

    func outcome() -> RoundOutcome? { roundResult }

    /// 既存マークを左上に温存して N×N へ拡張。
    private mutating func expand(to ns: Int) {
        var nb = Array(repeating: Mark.empty, count: ns * ns)
        var np = Array(repeating: Mark?.none, count: ns * ns)
        for r in 0..<size {
            for c in 0..<size {
                nb[r * ns + c] = board[r * size + c]
                np[r * ns + c] = placers[r * size + c]
            }
        }
        size = ns
        board = nb
        placers = np
        lines = GameEngine.makeLines(ns)
    }

    /// 次ラウンドへ。userWin で連勝+1・先手交代。2連勝ごとに盤を拡張（温存）。
    mutating func startNextRound(after outcome: RoundOutcome) {
        if outcome == .userWin {
            streak += 1
            firstPlayer = firstPlayer.opponent
            let ns = Self.size(forStreak: streak)
            if ns > size { expand(to: ns) }
        }
        moveCount = 0
        roundResult = nil
        lastMove = nil
        beginTurn(for: firstPlayer)
    }

    /// 連戦リセット（連勝0・4×4 空盤面・ユーザー先手）。
    mutating func resetSession() {
        size = Self.minSize
        board = Array(repeating: .empty, count: size * size)
        placers = Array(repeating: nil, count: size * size)
        lines = GameEngine.makeLines(size)
        firstPlayer = .o
        moveCount = 0
        streak = 0
        lastMove = nil
        roundResult = nil
        beginTurn(for: .o)
    }
}
