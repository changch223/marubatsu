//
//  CellDisplay.swift
//  marubatsu
//
//  盤面1マスの表示用 DTO。全マス常に着手可のため「配置可否」は持たず、
//  「最後に置いた人」と「直近の手か」を可視化する。
//

import Foundation

struct CellDisplay: Equatable, Identifiable {
    let id: Int            // セル index 0..8
    let mark: Mark         // 現在の合成マーク（表示記号）
    let placer: Mark?      // 最後に置いた人（.o=あなた / .x=AI / nil=未配置）
    let isLastMove: Bool   // 直近の手で置かれたマスか
}
