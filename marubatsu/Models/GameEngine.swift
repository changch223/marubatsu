//
//  GameEngine.swift
//  marubatsu
//
//  重ねがけマルバツ（クラシック化）の純粋ロジック（UI 非依存 / Principle II）。
//  ・お互い交互に置く（O=ユーザー / X=AI）
//  ・どのマスにもいつでも何度でも重ねて置ける（結合ルール適用）
//  ・縦横斜めに3並べた瞬間にその側の勝ち（引き分けなし）
//  ・勝利で盤面 fix して引き継ぎ、勝つたびに先手交代
//

import Foundation

enum RoundOutcome: Equatable {
    case userWin
    case userLoss
}

struct GameEngine: Equatable {

    private(set) var board: [Mark]
    /// 各マスを最後に置いた人（.o=ユーザー / .x=AI / nil=未配置）。引き継がれる。
    private(set) var placers: [Mark?]
    /// このラウンドの先手（既定 .o、ユーザー勝利のたびにトグル）。
    private(set) var firstPlayer: Mark
    private(set) var currentPlayer: Mark
    private(set) var moveCount: Int
    private(set) var streak: Int
    /// 直近に着手したマス（UI ハイライト用）。
    private(set) var lastMove: Int?
    /// 確定したラウンド結果（nil=継続中）。
    private(set) var roundResult: RoundOutcome?

    init() {
        board = Array(repeating: .empty, count: 9)
        placers = Array(repeating: nil, count: 9)
        firstPlayer = .o
        currentPlayer = .o
        moveCount = 0
        streak = 0
        lastMove = nil
        roundResult = nil
    }

    /// 8 勝利ライン（縦3・横3・斜2）。
    static let lines: [[Int]] = [
        [0, 1, 2], [3, 4, 5], [6, 7, 8],
        [0, 3, 6], [1, 4, 7], [2, 5, 8],
        [0, 4, 8], [2, 4, 6]
    ]

    var isRoundOver: Bool { roundResult != nil }

    func hasLine(_ mark: Mark) -> Bool {
        guard mark != .empty else { return false }
        return Self.lines.contains { line in line.allSatisfy { board[$0] == mark } }
    }

    /// 着手。どのマスにも何度でも重ね置き可。ラウンド確定後は不可。
    @discardableResult
    mutating func place(at index: Int) -> Bool {
        guard (0..<9).contains(index), roundResult == nil else { return false }
        let mover = currentPlayer
        board[index] = board[index].combine(placing: mover)
        placers[index] = mover
        lastMove = index
        moveCount += 1

        // 着手直後に勝敗判定（クラシック: 3並べた瞬間に決着）。
        if hasLine(mover) {
            roundResult = (mover == .o) ? .userWin : .userLoss
        } else if hasLine(mover.opponent) {
            // combine 反転で相手の3並びが成立した場合は相手の勝ち。
            roundResult = (mover.opponent == .o) ? .userWin : .userLoss
        } else {
            currentPlayer = mover.opponent
        }
        return true
    }

    /// ラウンド終了時のみ非 nil。
    func outcome() -> RoundOutcome? { roundResult }

    /// 次ラウンドへ。userWin で連勝 +1・先手交代。盤面/配置者は保持。
    mutating func startNextRound(after outcome: RoundOutcome) {
        if outcome == .userWin {
            streak += 1
            firstPlayer = firstPlayer.opponent
        }
        currentPlayer = firstPlayer
        moveCount = 0
        roundResult = nil
        lastMove = nil
    }

    /// 連戦リセット（連勝0・空盤面・ユーザー先手）。
    mutating func resetSession() {
        board = Array(repeating: .empty, count: 9)
        placers = Array(repeating: nil, count: 9)
        firstPlayer = .o
        currentPlayer = .o
        moveCount = 0
        streak = 0
        lastMove = nil
        roundResult = nil
    }
}
