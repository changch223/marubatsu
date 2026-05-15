//
//  ResultOverlayView.swift
//  marubatsu
//
//  連勝終了時の結果表示（今回連勝数・自己ベスト・再挑戦）。
//  ライト/ダーク対応・アクセシブル（Principle III）。
//

import SwiftUI

struct ResultOverlayView: View {
    let outcome: RoundOutcome
    let finalStreak: Int
    let bestStreak: Int
    let isNewBest: Bool
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("敗北… 連勝終了")
                .font(.title2.bold())

            VStack(spacing: 8) {
                Text("今回の連勝: \(finalStreak)")
                    .font(.title3)
                Text("自己ベスト: \(bestStreak)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                if isNewBest && finalStreak > 0 {
                    Text("🎉 自己ベスト更新！")
                        .font(.subheadline.bold())
                }
            }
            .accessibilityElement(children: .combine)

            Button(action: onRetry) {
                Text("再挑戦")
                    .font(.headline)
                    .frame(minWidth: 44, minHeight: 44)
                    .padding(.horizontal, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.accentColor)
                    )
                    .foregroundStyle(.white)
            }
            .accessibilityHint("連勝数0・空の盤面で新しい連戦を始めます")
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(radius: 12)
        )
        .padding(32)
    }
}
