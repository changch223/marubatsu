//
//  Mark.swift
//  marubatsu
//
//  ゲームの基本マーク。UI 非依存の純粋型（Constitution Principle II）。
//

import Foundation

enum Mark: Equatable, Sendable {
    case empty
    case o   // ユーザー
    case x   // AI

    /// 相手のマーク（empty は empty のまま）。
    var opponent: Mark {
        switch self {
        case .o: return .x
        case .x: return .o
        case .empty: return .empty
        }
    }

    /// このマス（self）に `placing` を重ねて置いたときの結果。
    /// - 空に置く            → placing
    /// - 同じマークに重ねる   → placing.opponent  （○+○→×, ×+×→○）
    /// - 相手マークに重ねる   → placing           （○+×→○, ×+○→×）
    func combine(placing: Mark) -> Mark {
        if self == .empty { return placing }
        if self == placing { return placing.opponent }
        return placing
    }

    /// 表示用グリフ（色非依存 / Principle III）。
    var glyph: String {
        switch self {
        case .o: return "○"
        case .x: return "✕"
        case .empty: return ""
        }
    }
}
