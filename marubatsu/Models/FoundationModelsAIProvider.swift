//
//  FoundationModelsAIProvider.swift
//  marubatsu
//
//  Apple Intelligence のオンデバイス基盤モデル（FoundationModels）で AI の着手を選ぶ。
//  不可用/エラー時は決定的 α-β（AIPlayer）へフォールバック。
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, macOS 26.0, *)
struct FoundationModelsAIProvider: AIMoveProviding {

    /// オンデバイスモデルが今使えるか。
    static var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    /// 構造化出力（ガイド付き生成）で 0..8 のマスを受け取る。
    @Generable
    struct AIMove {
        @Guide(description: "Chosen board cell index to place X, an integer from 0 to 8")
        var cell: Int
    }

    func chooseMove(engine: GameEngine, level: Int) async -> Int {
        let fallback = AIPlayer.chooseMove(engine: engine, level: level)
        guard case .available = SystemLanguageModel.default.availability else {
            return fallback
        }
        do {
            let session = LanguageModelSession(instructions: Self.instructions)
            let response = try await session.respond(
                to: Self.prompt(engine: engine, level: level),
                generating: AIMove.self
            )
            let cell = response.content.cell
            // 範囲外、または禁止マス（直前マス／この手番で既に置いた）はフォールバック。
            guard (0..<engine.cellCount).contains(cell),
                  !engine.forbiddenCells.contains(cell) else {
                return fallback
            }
            return cell
        } catch {
            return fallback
        }
    }

    // MARK: - プロンプト

    private static let instructions = """
    You are an expert player of an N×N stacking line game. You play as X; the \
    opponent is O. Pick exactly ONE board cell index to place X.

    Full rules you must respect:
    - Square board (current size given in the prompt), cells indexed row-major.
    - Winning lines: every row, every column, and the 2 main diagonals (length N).
    - You may place on ANY cell, any number of times. Placing your mark on a cell:
      * empty             -> the cell becomes your mark
      * SAME mark as yours -> it flips to the opponent's mark (avoid: self-damage)
      * the OPPONENT's mark -> it becomes your mark (a "capture")
    - WIN CONDITION: the instant a side has TWO completed N-in-a-row lines at the
      same time, that side immediately wins. ONE completed line is NOT enough.
    - You may NOT place on the cell the opponent just placed on (no immediate
      take-back / mirroring).
    - Turn length auto-balances dynamically (recomputed after every placement):
      X keeps placing until X_count >= O_count; O keeps placing until
      O_count >= X_count + 1 (min 1 per turn, hard cap 16). Within one turn each
      cell may be placed on only once; also never the opponent's last cell.
    - Strategy: build toward TWO lines at once; a single line is only a stepping
      stone. Always choose the strongest legal move; respond with only the index.
    """

    private static func prompt(engine: GameEngine, level: Int) -> String {
        let g: (Mark) -> String = { m in
            switch m { case .o: return "O"; case .x: return "X"; case .empty: return "." }
        }
        let n = engine.size
        var rows: [String] = []
        for r in 0..<n {
            let a = r * n
            rows.append((0..<n).map { "\(a + $0)=\(g(engine.board[a + $0]))" }
                .joined(separator: " "))
        }
        let board = rows.joined(separator: "\n")
        _ = level
        let strength = "Always play to win: build two 4-in-a-row lines, "
            + "complete the second line, and never throw the game."
        let forbiddenNote: String
        if !engine.forbiddenCells.isEmpty {
            let list = engine.forbiddenCells.sorted().map(String.init).joined(separator: ", ")
            forbiddenNote = "You may NOT place on these cells this move: \(list)."
        } else {
            forbiddenNote = "No cell is forbidden this move."
        }
        let turnNote = engine.movesRemainingThisTurn > 1
            ? "You have \(engine.movesRemainingThisTurn) consecutive moves this turn "
              + "(count-balance); each cell may be used at most once this turn."
            : "You have one move this turn."
        return """
        4x4 board, cells indexed 0..15 (row-major). You are X, the opponent is O.
        Your X-line counts: you=\(engine.lineCount(.x)) opponent=\(engine.lineCount(.o)).
        Win = hold TWO completed 4-in-a-row lines simultaneously.

        Current board (index=mark, '.'=empty):
        \(board)

        - \(strength)
        - \(forbiddenNote)
        - \(turnNote)

        Choose the single best cell index (0-15) for X to place now.
        """
    }

    private static func idx(_ i: Int) -> String { String(i) }
}
#endif
