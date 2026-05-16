//
//  AIMoveProvider.swift
//  marubatsu
//
//  AI 着手選択の抽象。既定は Apple Intelligence Foundation Models（オンデバイス）。
//  未対応端末/シミュレータでは決定的な α-β ヒューリスティック（AIPlayer）へ
//  自動フォールバック。エンジン（純粋ロジック）は不変（Constitution Principle II）。
//

import Foundation

protocol AIMoveProviding: Sendable {
    /// 現局面で AI（×）が置くマス 0..8 を返す。常に合法手。
    func chooseMove(engine: GameEngine, level: Int) async -> Int
}

/// 決定的フォールバック。テスト・オフライン・未対応端末で使用。
struct HeuristicAIProvider: AIMoveProviding {
    func chooseMove(engine: GameEngine, level: Int) async -> Int {
        // 重い探索はバックグラウンドで（メイン＝UI を止めない＝「考え中」表示が出る）。
        await Task.detached(priority: .userInitiated) {
            AIPlayer.chooseMove(engine: engine, level: level)
        }.value
    }
}

/// 既定は本ゲーム専用の強力アルゴリズム AI（決定的・最強）。
/// FoundationModels は任意で別途差し替え可能だが、既定では使用しない
/// （現ルールでは専用探索 AI の方が確実に強いため）。
func makeAIProvider() -> any AIMoveProviding {
    HeuristicAIProvider()
}
