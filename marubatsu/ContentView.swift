//
//  ContentView.swift
//  marubatsu
//
//  対戦画面: 連勝表示 ＋ 3×3 盤面 ＋ 連勝終了オーバーレイ。
//

import SwiftUI

struct ContentView: View {
    @State private var model = GameViewModel()

    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                header
                BoardView(
                    cells: model.cells,
                    isEnabled: model.isInputEnabled,
                    onTap: { model.tap($0) }
                )
                legend
                Text("あなたは ○、AI は ✕。全9マスに1回ずつ置くと1ラウンド終了。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .blur(radius: model.streakEnded ? 6 : 0)
            .disabled(model.streakEnded)

            if model.streakEnded, let outcome = model.lastOutcome {
                ResultOverlayView(
                    outcome: outcome,
                    finalStreak: model.finalStreak,
                    bestStreak: model.bestStreak,
                    isNewBest: model.isNewBest,
                    onRetry: { model.retry() }
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: model.streakEnded)
    }

    private var legend: some View {
        HStack(spacing: 16) {
            Label("あなたが配置", systemImage: "person.fill")
                .foregroundStyle(Color.accentColor)
            Label("AIが配置", systemImage: "cpu")
                .foregroundStyle(Color.orange)
            Label("太枠＝直近の手", systemImage: "square.dashed.inset.filled")
                .foregroundStyle(.secondary)
        }
        .font(.caption2)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("凡例: 青と人アイコンはあなたが置いたマス、橙とCPUアイコンはAIが置いたマス、太枠は直近の手")
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("マルバツ 重ねがけ連勝")
                .font(.title.bold())
            HStack(spacing: 24) {
                Label("\(model.currentStreak)", systemImage: "flame.fill")
                    .accessibilityLabel("現在の連勝 \(model.currentStreak)")
                Label("\(model.bestStreak)", systemImage: "trophy.fill")
                    .accessibilityLabel("自己ベスト \(model.bestStreak)")
            }
            .font(.title3.bold())
            Text(model.firstPlayerIsUser ? "このラウンドの先手: あなた" : "このラウンドの先手: AI")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ContentView()
}
