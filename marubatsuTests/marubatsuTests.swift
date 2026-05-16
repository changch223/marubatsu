//
//  marubatsuTests.swift
//  marubatsuTests
//
//  ゲームロジックの網羅テスト（Constitution Principle II）。
//  ルール: 4x4／4目（縦横＋主対角線2本）／交互1手／重ね置き可だが相手の直前マス禁止／
//  3並びでなく4並べた瞬間に勝ち／引き分けなし／勝利で先手交代／奪取補償なし。
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
        #expect(Mark.o.combine(placing: .o) == .x)
        #expect(Mark.x.combine(placing: .x) == .o)
        #expect(Mark.x.combine(placing: .o) == .o)
        #expect(Mark.o.combine(placing: .x) == .x)
    }
}

// MARK: - GameEngine（4x4 / 4目）

struct GameEngineTests {

    @Test func boardStartsAt4x4With10Lines() {
        let e = GameEngine()
        #expect(e.cellCount == 16)
        #expect(e.size == 4)
        #expect(e.winLength == 4)
        #expect(e.lines.count == 10)                    // 4行+4列+対角2
        #expect(GameEngine.linesToWin == 2)             // 2ライン同時で勝ち
        #expect(e.board.count == 16)
        #expect(e.lines.allSatisfy { $0.count == 4 })
    }

    @Test func boardGrowsEveryTwoWins() {
        var e = GameEngine()
        #expect(e.size == 4)
        e.startNextRound(after: .userWin)              // streak1
        #expect(e.size == 4 && e.streak == 1)
        e.startNextRound(after: .userWin)              // streak2 → 5×5
        #expect(e.size == 5 && e.cellCount == 25 && e.lines.count == 12)
        for _ in 0..<10 { e.startNextRound(after: .userWin) }  // streak12 → 10×10
        #expect(e.streak == 12 && e.size == 10)
        #expect(e.isCompleteVictory == false)
        e.startNextRound(after: .userWin)              // streak13、まだ10
        #expect(e.size == 10 && e.isCompleteVictory == false)
        e.startNextRound(after: .userWin)              // streak14 → 完全勝利
        #expect(e.isCompleteVictory == true)
    }

    @Test func growPreservesExistingMarks() {
        var e = GameEngine()
        _ = e.place(at: 0)                              // O を index0 に
        #expect(e.board[0] == .o)
        e.startNextRound(after: .userWin)               // streak1, 4×4 維持
        #expect(e.size == 4 && e.board[0] == .o)
        e.startNextRound(after: .userWin)               // streak2 → 5×5 拡張
        #expect(e.size == 5 && e.board.count == 25)
        #expect(e.board[0] == .o)                        // 左上に温存
        #expect(e.placers[0] == .o)
        #expect(e.board[24] == .empty)                   // 新規領域は空
    }

    @Test func resetSessionReturnsToFourByFour() {
        var e = GameEngine()
        for _ in 0..<4 { e.startNextRound(after: .userWin) }   // 6×6 へ
        #expect(e.size == 6)
        e.resetSession()
        #expect(e.size == 4 && e.cellCount == 16 && e.streak == 0)
        #expect(e.board.allSatisfy { $0 == .empty })
    }

    @Test func antiMirrorRejectsOpponentLastCell() {
        var e = GameEngine()
        #expect(e.place(at: 0) == true)
        #expect(e.forbiddenCells.contains(0))
        let before = e
        #expect(e.place(at: 0) == false)
        #expect(e == before)
    }

    @Test func restackAllowedWhenNotOpponentsLastCell() {
        var e = GameEngine()
        _ = e.place(at: 0)   // o
        _ = e.place(at: 1)   // x
        #expect(e.place(at: 0) == true)
        #expect(e.board[0] == .x)        // ○の上に○ → ×
    }

    @Test func singleLineDoesNotWin() {
        var e = GameEngine()
        // O が row0(0,1,2,3) のみ完成。1本では勝てない。
        for c in [0, 5, 1, 6, 2, 7, 3] { _ = e.place(at: c) }
        #expect(e.lineCount(.o) == 1)
        #expect(e.isRoundOver == false)
        #expect(e.outcome() == nil)
    }

    @Test func userWinsOnTwoLines() {
        var e = GameEngine()
        // O: row0{0,1,2,3} ＋ col0{0,4,8,12} の2ライン同時 → 勝ち
        for c in [0, 5, 1, 6, 2, 7, 3, 9, 4, 10, 8, 13, 12] { _ = e.place(at: c) }
        #expect(e.lineCount(.o) >= 2)
        #expect(e.outcome() == .userWin)
        #expect(e.moveCount == 13)
    }

    @Test func aiWinsOnTwoLines() {
        var e = GameEngine()
        // X: col3{3,7,11,15} ＋ row3{12,13,14,15} を15で同時完成 → userLoss
        for c in [0, 3, 1, 7, 2, 11, 4, 12, 5, 13, 6, 14, 8, 15] { _ = e.place(at: c) }
        #expect(e.outcome() == .userLoss)
        #expect(e.moveCount == 14)
    }

    @Test func startNextRoundTogglesFirstPlayerAndKeepsBoard() {
        var e = GameEngine()
        for c in [0, 5, 1, 6, 2, 7, 3, 9, 4, 10, 8, 13, 12] { _ = e.place(at: c) }
        #expect(e.outcome() == .userWin)
        #expect(e.firstPlayer == .o)
        let boardBefore = e.board
        let placersBefore = e.placers
        e.startNextRound(after: .userWin)
        #expect(e.streak == 1)
        #expect(e.firstPlayer == .x)
        #expect(e.currentPlayer == .x)
        #expect(e.board == boardBefore)
        #expect(e.placers == placersBefore)
        #expect(e.moveCount == 0)
        #expect(e.lastMove == nil)
        #expect(e.forbiddenCells.isEmpty)
        #expect(e.outcome() == nil)
    }

    @Test func resetSessionRestoresInitialState() {
        var e = GameEngine()
        for c in [0, 5, 1, 6, 2, 7, 3, 9, 4, 10, 8, 13, 12] { _ = e.place(at: c) }
        e.startNextRound(after: .userWin)
        e.resetSession()
        #expect(e.streak == 0)
        #expect(e.firstPlayer == .o)
        #expect(e.currentPlayer == .o)
        #expect(e.board.count == 16)
        #expect(e.board.allSatisfy { $0 == .empty })
        #expect(e.placers.allSatisfy { $0 == nil })
        #expect(e.lastMove == nil)
        #expect(e.outcome() == nil)
    }

    @Test func placersAndLastMoveTracked() {
        var e = GameEngine()
        _ = e.place(at: 0)
        #expect(e.placers[0] == .o)
        #expect(e.lastMove == 0)
        _ = e.place(at: 1)
        #expect(e.placers[1] == .x)
        #expect(e.lastMove == 1)
        #expect(e.placers[2] == nil)
    }

    @Test func earlyAlternationIsSingleMove() {
        var e = GameEngine()
        #expect(e.currentPlayer == .o && e.movesRemainingThisTurn == 1)
        _ = e.place(at: 0)
        #expect(e.currentPlayer == .x && e.movesRemainingThisTurn == 1)  // X は O と同数(1)へ
        _ = e.place(at: 4)
        #expect(e.currentPlayer == .o && e.movesRemainingThisTurn == 1)  // O は X+1 維持
    }

    @Test func turnLengthBalancesByCounts() {
        var e = GameEngine()
        // O0,X4,O1,X5,O2 → O3/X2、X が O(0) を奪取して O2/X3。
        for c in [0, 4, 1, 5, 2, 0] { _ = e.place(at: c) }
        #expect(e.board[0] == .x)
        #expect(e.markCount(.o) == 2)
        #expect(e.markCount(.x) == 3)
        #expect(e.currentPlayer == .o)
        // O は X+1=4 まで → 4-2 = 2 手
        #expect(e.movesRemainingThisTurn == 2)
    }

    @Test func consecutiveMoveCannotRepeatCell() {
        var e = GameEngine()
        for c in [0, 4, 1, 5, 2, 0] { _ = e.place(at: c) }
        #expect(e.currentPlayer == .o && e.movesRemainingThisTurn == 2)
        #expect(e.place(at: 8) == true)            // 1手目
        #expect(e.currentPlayer == .o && e.movesRemainingThisTurn == 1)
        #expect(e.place(at: 8) == false)           // 連続で同マス不可
        #expect(e.place(at: 9) == true)            // 別マスは可 → 手番交代
        #expect(e.currentPlayer == .x)
        #expect(e.movesRemainingThisTurn == 1)     // O4 vs X3 → X は1手で追いつき
    }

    @Test func sameCellOncePerTurnEvenNonConsecutive() {
        var e = GameEngine()
        for c in [0, 4, 1, 5] { _ = e.place(at: c) }   // O2 X2、O 手番（直前=5）
        #expect(e.place(at: 1) == true)                // 自分の O(1) を X 化 → O1 X3、O 継続
        #expect(e.currentPlayer == .o)
        #expect(e.place(at: 8) == true)                // O 1→2
        #expect(e.place(at: 9) == true)                // O 2→3、まだ O 手番
        #expect(e.currentPlayer == .o)
        // cell 1 はこの手番で既に置いた（直前=9 ではない）→ それでも不可
        #expect(e.forbiddenCells.contains(1))
        #expect(e.place(at: 1) == false)
        #expect(e.place(at: 8) == false)               // 8 もこの手番で既出 → 不可
        #expect(e.place(at: 10) == true)               // 新規マスは可 → O=4 で手番交代
        #expect(e.currentPlayer == .x)
    }

    @Test func placeRejectedAfterRoundOver() {
        var e = GameEngine()
        for c in [0, 5, 1, 6, 2, 7, 3, 9, 4, 10, 8, 13, 12] { _ = e.place(at: c) }  // 2ライン勝ち
        let before = e
        #expect(e.place(at: 1) == false)
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

    @Test func chooseMoveReturnsLegalCellAndAvoidsForbidden() {
        var e = GameEngine()
        _ = e.place(at: 5)
        #expect(e.forbiddenCells.contains(5))
        let m = AIPlayer.chooseMove(engine: e)
        #expect((0..<16).contains(m))
        #expect(!e.forbiddenCells.contains(m))
    }

    @Test func aiTakesTwoLineWin() {
        var e = GameEngine()
        // X: row3{12,13,14,15} 完成(1本) ＋ col0{0,4,?,12} に 0,4,12。
        // X 手番で 8 を置くと col0 完成＝2本同時 → 勝ち。
        for c in [1, 0, 2, 4, 3, 12, 5, 13, 6, 14, 9, 15, 10] { _ = e.place(at: c) }
        #expect(e.currentPlayer == .x)
        #expect(e.lineCount(.x) == 1)
        let m = AIPlayer.chooseMove(engine: e)
        var n = e
        _ = n.place(at: m)
        #expect(n.outcome() == .userLoss)
    }

    @Test func maxLevelIsDeterministic() {
        var e = GameEngine()
        for c in [3, 0, 4] { _ = e.place(at: c) }
        #expect(e.currentPlayer == .x)
        let m1 = AIPlayer.chooseMove(engine: e, rng: { 0.99 })
        let m2 = AIPlayer.chooseMove(engine: e, rng: { 0.01 })
        #expect(m1 == m2)
        #expect((0..<16).contains(m1))
    }

    @Test func heuristicProviderReturnsLegalMove() async {
        var e = GameEngine()
        _ = e.place(at: 0)
        let m = await HeuristicAIProvider().chooseMove(engine: e, level: 0)
        #expect((0..<16).contains(m))
        #expect(!e.forbiddenCells.contains(m))
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
