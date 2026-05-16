//
//  ResultOverlayView.swift
//  marubatsu
//
//  連勝終了の結果カード（Apple HIG: マテリアル・明確な階層・主アクション強調）。
//

import SwiftUI

struct ResultOverlayView: View {
    let outcome: RoundOutcome
    let finalStreak: Int
    let bestStreak: Int
    let isNewBest: Bool
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: "flag.checkered")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)

            Text("連勝終了")
                .font(.title2.bold())

            VStack(spacing: 6) {
                Text("\(finalStreak)")
                    .font(.system(size: 56, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.accentColor)
                    .contentTransition(.numericText())
                Text("今回の連勝")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Label("自己ベスト \(bestStreak)", systemImage: "trophy.fill")
                .font(.headline)
                .foregroundStyle(isNewBest ? Color.accentColor : .secondary)

            if isNewBest && finalStreak > 0 {
                Text("🎉 自己ベスト更新！")
                    .font(.subheadline.bold())
                    .transition(.scale)
            }

            Button(action: onRetry) {
                Text("もう一度")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityHint("連勝数0・空の盤面で新しい連戦を始めます")
        }
        .padding(28)
        .frame(maxWidth: 360)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.primary.opacity(0.08))
        )
        .shadow(color: .black.opacity(0.18), radius: 24, y: 10)
        .padding(28)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }
}
