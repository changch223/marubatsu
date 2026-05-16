//
//  ContentView.swift
//  marubatsu
//
//  対戦画面（Apple HIG 準拠: 背景グラデーション・スタットカード・マテリアル・
//  即時「考え中」オーバーレイ・明確な主アクション）。
//

import SwiftUI

struct ContentView: View {
    @State private var model = GameViewModel()

    var body: some View {
        ZStack {
            backdrop

            VStack(spacing: 18) {
                header
                BoardView(
                    cells: model.cells,
                    isEnabled: model.isInputEnabled,
                    onTap: { model.tap($0) }
                )
                compensationBanner
                legend
                rulesText
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .frame(maxWidth: 600)
            .blur(radius: (model.streakEnded || model.completed) ? 8 : 0)
            .disabled(model.streakEnded || model.completed)

            if model.isAIThinking && !model.streakEnded && !model.completed {
                thinkingOverlay
            }

            if model.completed {
                completeOverlay
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            } else if model.streakEnded, let outcome = model.lastOutcome {
                ResultOverlayView(
                    outcome: outcome,
                    finalStreak: model.finalStreak,
                    bestStreak: model.bestStreak,
                    isNewBest: model.isNewBest,
                    onRetry: { model.retry() }
                )
                .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
        }
        .animation(.smooth(duration: 0.28), value: model.streakEnded)
        .animation(.smooth(duration: 0.28), value: model.completed)
        .animation(.smooth(duration: 0.2), value: model.isAIThinking)
        .animation(.smooth(duration: 0.2), value: model.userHasDoubleTurn)
    }

    // MARK: - 完全勝利

    private var completeOverlay: some View {
        VStack(spacing: 20) {
            Image(systemName: "crown.fill")
                .font(.system(size: 52))
                .foregroundStyle(.yellow)
            Text("完全勝利！")
                .font(.system(.largeTitle, design: .rounded).weight(.heavy))
            Text("10×10 を制覇しました")
                .font(.headline)
                .foregroundStyle(.secondary)
            Label("自己ベスト \(model.bestStreak)", systemImage: "trophy.fill")
                .font(.headline)
            Button {
                model.retry()
            } label: {
                Text("もう一度（4×4 から）")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(28)
        .frame(maxWidth: 380)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 24, y: 10)
        .padding(28)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }

    // MARK: - 背景

    private var backdrop: some View {
        LinearGradient(
            colors: [Color.accentColor.opacity(0.18), Color(.systemBackground)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - ヘッダー

    private var header: some View {
        VStack(spacing: 12) {
            Text("重ねマルバツ 連勝チャレンジ")
                .font(.system(.title, design: .rounded).weight(.bold))
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                statCard(title: "盤面", value: model.boardSize,
                         systemImage: "square.grid.3x3.fill", tint: .teal,
                         suffix: "×\(model.boardSize)")
                statCard(title: "連勝", value: model.currentStreak,
                         systemImage: "flame.fill", tint: .accentColor)
                statCard(title: "自己ベスト", value: model.bestStreak,
                         systemImage: "trophy.fill", tint: .orange)
            }

            Label(model.firstPlayerIsUser ? "このラウンドの先手: あなた"
                                          : "このラウンドの先手: AI",
                  systemImage: "figure.walk")
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityLabel(model.firstPlayerIsUser
                                    ? "このラウンドの先手はあなた" : "このラウンドの先手はAI")
        }
    }

    private func statCard(title: String, value: Int,
                          systemImage: String, tint: Color,
                          suffix: String = "") -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(value)\(suffix)")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .contentTransition(.numericText())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(value)\(suffix)")
    }

    // MARK: - 補正バナー

    @ViewBuilder private var compensationBanner: some View {
        if model.userHasDoubleTurn {
            Label("均衡補正: このターンはあと \(model.userMovesRemaining) 手 置けます",
                  systemImage: "bolt.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(Color.accentColor.opacity(0.12),
                            in: Capsule())
                .accessibilityAddTraits(.isHeader)
        }
    }

    // MARK: - 凡例 / ルール

    private var legend: some View {
        HStack(spacing: 18) {
            Label("あなた", systemImage: "person.fill")
                .foregroundStyle(Color.accentColor)
            Label("AI", systemImage: "cpu")
                .foregroundStyle(.orange)
            Label("直近の手", systemImage: "scope")
                .foregroundStyle(.secondary)
            Label("置けない", systemImage: "lock.fill")
                .foregroundStyle(.secondary)
        }
        .font(.caption2)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("凡例: 青と人アイコンはあなたの手、橙とCPUアイコンはAIの手、太枠は直近の手、鍵は今は置けないマス")
    }

    private var rulesText: some View {
        Text("○=あなた / ✕=AI で交互に着手。空マスは自分の印、相手の印に重ねると奪える、"
             + "自分の印に重ねると相手の印に変わる。タテ/ヨコ/ナナメに N連ラインを"
             + "同時2本そろえたら勝ち。相手の直前マス・その手番で既に置いたマスには"
             + "置けない。2連勝ごとに盤が拡大（4→…→10）、10×10で2連勝＝完全勝利。")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 4)
    }

    // MARK: - 考え中オーバーレイ

    private var thinkingOverlay: some View {
        ZStack {
            Color.black.opacity(0.001).ignoresSafeArea()  // タップ遮断
            VStack(spacing: 14) {
                ProgressView()
                    .controlSize(.large)
                Text("AI が考え中…")
                    .font(.headline)
            }
            .padding(28)
            .background(.regularMaterial,
                        in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 18, y: 8)
        }
        .transition(.opacity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("AI が考え中です")
    }
}

#Preview {
    ContentView()
}
