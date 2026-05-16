//
//  BoardView.swift
//  marubatsu
//
//  4×4 盤面。配置者を色＋アイコンで区別し直近の手を強調。
//  Apple HIG: マテリアル背景・角丸・色非依存・44pt以上・Dynamic Type・ライト/ダーク。
//

import SwiftUI

struct BoardView: View {
    let cells: [CellDisplay]
    let isEnabled: Bool
    let onTap: (Int) -> Void

    /// 盤の一辺（cells 数の平方根）。
    private var n: Int { max(1, Int(Double(cells.count).squareRoot().rounded())) }
    private var spacing: CGFloat { n <= 5 ? 8 : (n <= 7 ? 5 : 3) }
    private var glyphSize: CGFloat { max(11, 120 / CGFloat(n)) }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: spacing), count: n)
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(cells) { cell in
                Button {
                    onTap(cell.id)
                } label: {
                    cellView(cell)
                }
                .buttonStyle(.plain)
                .disabled(!isEnabled || cell.isForbidden)
                .accessibilityLabel(accessibilityLabel(cell))
                .accessibilityValue(stateDescription(cell))
                .accessibilityHint(cell.isForbidden
                    ? "このターンは置けません"
                    : "タップで重ねて置きます。重ねると記号が変化します。")
            }
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.primary.opacity(0.06))
        )
        .accessibilityElement(children: .contain)
    }

    private func tint(_ placer: Mark?) -> Color {
        switch placer {
        case .o: return .accentColor
        case .x: return .orange
        default: return .secondary
        }
    }

    private func cellView(_ cell: CellDisplay) -> some View {
        let tinted = tint(cell.placer)
        let win = cell.isWinning
        return ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(win
                      ? AnyShapeStyle(Color.green.opacity(0.30))
                      : (cell.placer == nil
                         ? AnyShapeStyle(Color(.tertiarySystemFill))
                         : AnyShapeStyle(tinted.opacity(cell.isLastMove ? 0.22 : 0.12))))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(win ? Color.green
                                          : (cell.isLastMove ? tinted : tinted.opacity(0.35)),
                                      lineWidth: win ? 3 : (cell.isLastMove ? 3 : 1))
                )

            Text(cell.mark.glyph)
                .font(.system(size: glyphSize, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.5)
                .foregroundStyle(cell.mark == .empty ? AnyShapeStyle(.clear)
                                                      : AnyShapeStyle(.primary))
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if cell.isForbidden && !win {
                // 薄いマテリアルで減光（記号は透ける）。
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .accessibilityHidden(true)
                    .transition(.opacity)
            }

            // 右上のバッジ: 禁止時は鍵、それ以外は配置者アイコン。
            if cell.isForbidden && !win {
                Image(systemName: "lock.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(5)
                    .accessibilityHidden(true)
            } else if let placer = cell.placer {
                Image(systemName: placer == .o ? "person.fill" : "cpu")
                    .font(.caption2)
                    .foregroundStyle(tinted)
                    .padding(5)
                    .accessibilityHidden(true)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(minWidth: 44, minHeight: 44)
        .opacity(cell.isForbidden && !win ? 0.85 : 1)
        .animation(.snappy(duration: 0.18), value: cell.mark)
        .animation(.snappy(duration: 0.22), value: cell.isWinning)
        .animation(.snappy(duration: 0.18), value: cell.isForbidden)
    }

    private func accessibilityLabel(_ cell: CellDisplay) -> String {
        let row = cell.id / n + 1
        let col = cell.id % n + 1
        let state: String
        switch cell.mark {
        case .o: state = "○"
        case .x: state = "×"
        case .empty: state = "空"
        }
        return "行\(row) 列\(col)、\(state)"
    }

    private func stateDescription(_ cell: CellDisplay) -> String {
        let who: String
        switch cell.placer {
        case .o: who = "あなたが配置"
        case .x: who = "AIが配置"
        default: who = "未配置"
        }
        var s = who
        if cell.isLastMove { s += "・直近の手" }
        if cell.isWinning { s += "・勝利ライン" }
        if cell.isForbidden { s += "・このターンは置けません" }
        return s
    }
}
