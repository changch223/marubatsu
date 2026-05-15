//
//  marubatsuTests.swift
//  marubatsuTests
//
//  ゲームロジックの網羅テスト（Constitution Principle II）。
//  新ルール: 無制限重ねがけ／3並べた瞬間に勝ち／引き分けなし／勝利で先手交代。
//

import Testing
import Foundation
@testable import marubatsu

// MARK: - Mark

struct MarkTests {

    @Test func opponent() {
        #expect(Mark.o.opponent == .x)
        #expect(Mark.x.opponent == .o)
        #expect(Mark.empty.opponent == .empty)
    }

    @Test func combineAllSixInputs() {
        #expect(Mark.empty.combine(placing: .o) == .o)
        #expect(Mark.empty.combine(placing: .x) == .x)
        #expect(Mark.o.combine(placing: .o) == .x)   // ○+○→×
        #expect(Mark.x.combine(placing: .x) == .o)   // ×+×→○
        #expect(Mark.x.combine(placing: .o) == .o)   // ×の上に○→○
        #expect(Mark.o.combine(placing: .x) == .x)   // ○の上に×→×
    }
}

// MARK: - GameEngine（新ルール）

struct GameEngineTests {

    @Test func placeAnywhereAndRestackSameCellAppliesCombine() {
        var e = GameEngine()
        #expect(e.place(at: 0) == true)   // 空→○ (mover .o)
        #expect(e.board[0] == .o)
        #expect(e.place(at: 0) == true)   // ○の上に× → ×
        #expect(e.board[0] == .x)
        #expect(e.place(at: 0) == true)   // ×の上に○ → ○
        #expect(e.board[0] == .o)
    }

    @Test func userWinsInstantlyOnThreeInARow() {
        var e = GameEngine()
        for c in [0, 3, 1, 4, 2] { _ = e.place(at: c) }  // ○ at 0,1,2
        #expect(e.isRoundOver == true)
        #expect(e.outcome() == .userWin)
        #expect(e.moveCount == 5)                          // 9手前で即決着
    }

    @Test func userLosesWhenAIMakesLine() {
        var e = GameEngine()
        for c in [0, 3, 1, 4, 8, 5] { _ = e.place(at: c) } // × at 3,4,5
        #expect(e.isRoundOver == true)
        #expect(e.outcome() == .userLoss)
    }

    @Test func startNextRoundTogglesFirstPlayerAndKeepsBoard() {
        var e = GameEngine()
        for c in [0, 3, 1, 4, 2] { _ = e.place(at: c) }
        #expect(e.outcome() == .userWin)
        #expect(e.firstPlayer == .o)
        let boardBefore = e.board
        let placersBefore = e.placers
        e.startNextRound(after: .userWin)
        #expect(e.streak == 1)
        #expect(e.firstPlayer == .x)         // 勝つたびに先手交代
        #expect(e.currentPlayer == .x)
        #expect(e.board == boardBefore)      // 盤面引き継ぎ
        #expect(e.placers == placersBefore)
        #expect(e.moveCount == 0)
        #expect(e.lastMove == nil)
        #expect(e.outcome() == nil)
    }

    @Test func resetSessionRestoresInitialState() {
        var e = GameEngine()
        for c in [0, 3, 1, 4, 2] { _ = e.place(at: c) }
        e.startNextRound(after: .userWin)
        e.resetSession()
        #expect(e.streak == 0)
        #expect(e.firstPlayer == .o)
        #expect(e.currentPlayer == .o)
        #expect(e.board.allSatisfy { $0 == .empty })
        #expect(e.placers.allSatisfy { $0 == nil })
        #expect(e.outcome() == nil)
    }

    @Test func placersAndLastMoveTracked() {
        var e = GameEngine()
        _ = e.place(at: 0)               // .o
        #expect(e.placers[0] == .o)
        #expect(e.lastMove == 0)
        _ = e.place(at: 1)               // .x
        #expect(e.placers[1] == .x)
        #expect(e.lastMove == 1)
        #expect(e.placers[2] == nil)
    }

    @Test func placeRejectedAfterRoundOver() {
        var e = GameEngine()
        for c in [0, 3, 1, 4, 2] { _ = e.place(at: c) }   // userWin
        let before = e
        #expect(e.place(at: 5) == false)
        #expect(e == before)
    }
}

// MARK: - AIPlayer

struct AIPlayerTests {

    @Test func difficultyIsMonotonic() {
        var last = AIPlayer.difficultyLevel(forStreak: 0)
        for s in 0...20 {
            let lvl = AIPlayer.difficultyLevel(forStreak: s)
            #expect(lvl >= last)
            last = lvl
        }
    }

    @Test func chooseMoveReturnsLegalCell() {
        for level in 0...AIPlayer.maxLevel {
            var e = GameEngine()
            _ = e.place(at: 0)                 // user → AI 手番
            let m = AIPlayer.chooseMove(engine: e, level: level)
            #expect((0..<9).contains(m))
        }
    }

    @Test func aiTakesImmediateWin() {
        var e = GameEngine()
        // user: 3,4,6 / AI: 0,1 → AI 手番で 2 を置くと × の 0,1,2 完成
        for c in [3, 0, 4, 1, 6] { _ = e.place(at: c) }
        #expect(e.currentPlayer == .x)
        let m = AIPlayer.chooseMove(engine: e, level: AIPlayer.maxLevel)
        var n = e
        _ = n.place(at: m)
        #expect(n.outcome() == .userLoss)      // AI が即勝ち手を取る
    }

    @Test func maxLevelIsDeterministic() {
        // 最高難易度はランダムを使わない（同一局面で同じ手）。
        var e = GameEngine()
        for c in [3, 0, 4] { _ = e.place(at: c) }
        #expect(e.currentPlayer == .x)
        let m1 = AIPlayer.chooseMove(engine: e, level: AIPlayer.maxLevel, rng: { 0.99 })
        let m2 = AIPlayer.chooseMove(engine: e, level: AIPlayer.maxLevel, rng: { 0.01 })
        #expect(m1 == m2)
        #expect((0..<9).contains(m1))
    }
}

// MARK: - BestStreakStore

struct BestStreakStoreTests {

    @Test func updatesOnlyWhenGreater() {
        let suiteName = "test.bestStreak.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = BestStreakStore(defaults: defaults)
        #expect(store.value == 0)
        #expect(store.update(with: 3) == 3)
        #expect(store.update(with: 2) == 3)
        #expect(store.update(with: 5) == 5)
        #expect(store.value == 5)
    }
}
