//
//  GameViewModel.swift
//  marubatsu
//
//  GameEngine を駆動する @Observable 状態（Principle I）。
//  交互1手ずつ。先手が AI のラウンドは AI が先に着手。3並べた瞬間に決着。
//

import Foundation
import Observation

@Observable
final class GameViewModel {

    private(set) var engine = GameEngine()
    private(set) var lastOutcome: RoundOutcome?
    private(set) var streakEnded = false
    private(set) var finalStreak = 0
    private(set) var bestStreak: Int
    private(set) var isNewBest = false

    @ObservationIgnored private let bestStore: BestStreakStore

    init(bestStore: BestStreakStore = BestStreakStore()) {
        self.bestStore = bestStore
        self.bestStreak = bestStore.value
        // ラウンド1はユーザー先手のため開始時の AI 着手は不要。
    }

    // MARK: - 表示用

    var currentStreak: Int { engine.streak }
    var firstPlayerIsUser: Bool { engine.firstPlayer == .o }

    var cells: [CellDisplay] {
        (0..<9).map { i in
            CellDisplay(
                id: i,
                mark: engine.board[i],
                placer: engine.placers[i],
                isLastMove: engine.lastMove == i
            )
        }
    }

    /// ユーザーが着手できる状態か（連戦中・ユーザー手番・ラウンド継続中）。
    var isInputEnabled: Bool {
        !streakEnded && !engine.isRoundOver && engine.currentPlayer == .o
    }

    // MARK: - 操作

    /// マスをタップ（ユーザー着手）。以後 AI 手番・決着・先手交代を自動進行。
    func tap(_ index: Int) {
        guard isInputEnabled else { return }
        guard engine.place(at: index) else { return }
        settle()
    }

    /// 連勝終了後の再挑戦（連勝0・空盤面・ユーザー先手）。
    func retry() {
        engine.resetSession()
        lastOutcome = nil
        streakEnded = false
        finalStreak = 0
        isNewBest = false
        settle()
    }

    // MARK: - 内部

    /// AI 手番の自動消化・ラウンド決着・先手交代付き次ラウンド開始を、
    /// ユーザー手番になるか連勝終了するまで進める。
    private func settle() {
        var safety = 0
        while true {
            safety += 1
            if safety > 500 { return }   // 病的な自動連鎖の保険（UI ハング防止）
            if let outcome = engine.outcome() {
                lastOutcome = outcome
                if outcome == .userWin {
                    engine.startNextRound(after: .userWin)
                    continue   // 先手交代後、AI 先手なら次ループで AI 着手
                } else {
                    finalStreak = engine.streak
                    let previousBest = bestStore.value
                    bestStreak = bestStore.update(with: finalStreak)
                    isNewBest = finalStreak > previousBest && finalStreak > 0
                    streakEnded = true
                    return
                }
            }
            if engine.currentPlayer == .x {
                let level = AIPlayer.difficultyLevel(forStreak: engine.streak)
                let move = AIPlayer.chooseMove(engine: engine, level: level)
                engine.place(at: move)
                continue
            }
            return // ユーザー手番待ち
        }
    }
}
