//
//  GameViewModel.swift
//  marubatsu
//
//  GameEngine を駆動する @Observable 状態（Principle I）。
//  UX フロー: ユーザー着手を即反映 → 「AI考え中」→ AI を1手ずつ可視更新 →
//  決着時は勝利2ラインをハイライト表示 → 結果ポップアップ。
//

import Foundation
import Observation

@MainActor
@Observable
final class GameViewModel {

    private(set) var engine = GameEngine()
    private(set) var lastOutcome: RoundOutcome?
    private(set) var streakEnded = false
    private(set) var completed = false        // 10×10 で2連勝＝完全勝利
    private(set) var finalStreak = 0
    private(set) var bestStreak: Int
    private(set) var isNewBest = false
    private(set) var isAIThinking = false
    /// 決着時に光らせる勝利ライン上のマス。
    private(set) var highlightCells: Set<Int> = []

    @ObservationIgnored private let bestStore: BestStreakStore
    @ObservationIgnored private let aiProvider: any AIMoveProviding
    @ObservationIgnored private var aiTask: Task<Void, Never>?

    /// AI の1手を見せる間隔 / 決着ラインを見せる時間。
    private let stepDelay: Duration = .milliseconds(440)
    private let revealDelay: Duration = .milliseconds(1200)

    init(bestStore: BestStreakStore = BestStreakStore(),
         aiProvider: any AIMoveProviding = makeAIProvider()) {
        self.bestStore = bestStore
        self.aiProvider = aiProvider
        self.bestStreak = bestStore.value
    }

    // MARK: - 表示用

    var currentStreak: Int { engine.streak }
    var boardSize: Int { engine.size }
    var firstPlayerIsUser: Bool { engine.firstPlayer == .o }
    var forbiddenCells: Set<Int> { engine.forbiddenCells }

    var userMovesRemaining: Int {
        (!streakEnded && engine.currentPlayer == .o && !engine.isRoundOver)
            ? engine.movesRemainingThisTurn : 0
    }
    var userHasDoubleTurn: Bool { userMovesRemaining > 1 }

    var cells: [CellDisplay] {
        let forbidden = engine.forbiddenCells
        let showForbidden = !streakEnded && !engine.isRoundOver
        return (0..<engine.cellCount).map { i in
            CellDisplay(
                id: i,
                mark: engine.board[i],
                placer: engine.placers[i],
                isLastMove: engine.lastMove == i,
                isWinning: highlightCells.contains(i),
                isForbidden: showForbidden && forbidden.contains(i)
            )
        }
    }

    /// ユーザーが着手できる状態か（AI 思考中・決着表示中・AI 手番は不可）。
    var isInputEnabled: Bool {
        !streakEnded && !completed && !isAIThinking
            && !engine.isRoundOver && engine.currentPlayer == .o
    }

    // MARK: - 操作

    func tap(_ index: Int) {
        guard isInputEnabled else { return }
        guard engine.place(at: index) else { return }
        // ユーザーの着手は即 UI 反映（このメソッドから戻ると SwiftUI が再描画）。
        startAdvance()
    }

    func retry() {
        aiTask?.cancel()
        aiTask = nil
        isAIThinking = false
        highlightCells = []
        engine = GameEngine()      // 4×4 から再スタート
        lastOutcome = nil
        streakEnded = false
        completed = false
        finalStreak = 0
        isNewBest = false
    }

    // MARK: - 進行（非同期・一歩ずつ）

    private func startAdvance() {
        guard aiTask == nil else { return }
        aiTask = Task { [weak self] in
            await self?.advance()
        }
    }

    private func advance() async {
        defer {
            isAIThinking = false
            aiTask = nil
        }
        while true {
            if Task.isCancelled { return }

            if let outcome = engine.outcome() {
                await resolve(outcome)
                if streakEnded || completed { return }
                continue   // userWin: 次ラウンドへ（AI 先手なら継続）
            }

            if engine.currentPlayer != .x { return }   // ユーザー手番待ち

            // 「AI 考え中」を表示してから計算（重い探索はバックグラウンド）。
            isAIThinking = true
            let level = AIPlayer.difficultyLevel(forStreak: engine.streak)
            let move = await aiProvider.chooseMove(engine: engine, level: level)
            if Task.isCancelled { return }
            isAIThinking = false

            if !engine.place(at: move) {
                let safe = AIPlayer.chooseMove(engine: engine, level: level)
                if !engine.place(at: safe) { return }
            }
            // この1手を見せてから次へ（AI の動きが一歩ずつ分かる）。
            if engine.outcome() == nil {
                try? await Task.sleep(for: stepDelay)
            }
        }
    }

    /// 決着処理: 勝利2ラインをハイライトし、見せてから結果へ。
    private func resolve(_ outcome: RoundOutcome) async {
        lastOutcome = outcome
        let winner: Mark = (outcome == .userWin) ? .o : .x
        highlightCells = Set(engine.completedLines(winner).flatMap { $0 })
        isAIThinking = false
        try? await Task.sleep(for: revealDelay)   // 2ライン連結を見せる
        if Task.isCancelled { return }

        if outcome == .userWin {
            highlightCells = []
            engine.startNextRound(after: .userWin)
            if engine.isCompleteVictory {
                finalStreak = engine.streak
                bestStreak = bestStore.update(with: finalStreak)
                isNewBest = finalStreak > 0
                completed = true       // 10×10 で2連勝＝完全勝利
            }
        } else {
            finalStreak = engine.streak
            let previousBest = bestStore.value
            bestStreak = bestStore.update(with: finalStreak)
            isNewBest = finalStreak > previousBest && finalStreak > 0
            streakEnded = true        // ハイライトを見せた後に失敗ポップアップ
        }
    }
}
