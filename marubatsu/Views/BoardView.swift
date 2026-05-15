//
//  BoardView.swift
//  marubatsu
//
//  3×3 盤面。全マスいつでも重ね置き可。配置者を色＋アイコンで区別し、
//  直近の手を強調（Principle III: 色のみに依存しない）。
//

import SwiftUI

struct BoardView: View {
    let cells: [CellDisplay]
    let isEnabled: Bool
    let onTap: (Int) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(cells) { cell in
                Button {
                    onTap(cell.id)
                } label: {
                    cellView(cell)
                }
                .buttonStyle(.plain)
                .disabled(!isEnabled)
                .accessibilityLabel(accessibilityLabel(cell))
                .accessibilityValue(stateDescription(cell))
                .accessibilityHint("タップで重ねて置きます。重ねると記号が変化します。")
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func placerColor(_ placer: Mark?) -> Color {
        switch placer {
        case .o: return .accentColor
        case .x: return .orange
        default: return .primary.opacity(0.25)
        }
    }

    private func cellView(_ cell: CellDisplay) -> some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            placerColor(cell.placer),
                            lineWidth: cell.isLastMove ? 4 : (cell.placer == nil ? 1 : 2)
                        )
                )

            Text(cell.mark.glyph)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if let placer = cell.placer {
                Image(systemName: placer == .o ? "person.fill" : "cpu")
                    .foregroundStyle(placerColor(placer))
                    .imageScale(cell.isLastMove ? .large : .small)
                    .padding(6)
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 88)
        .frame(minWidth: 44, minHeight: 44)
    }

    // MARK: - アクセシビリティ

    private func accessibilityLabel(_ cell: CellDisplay) -> String {
        let row = cell.id / 3 + 1
        let col = cell.id % 3 + 1
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
        return cell.isLastMove ? "\(who)・直近の手" : who
    }
}
