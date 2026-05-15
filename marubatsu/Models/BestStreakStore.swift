//
//  BestStreakStore.swift
//  marubatsu
//
//  自己ベスト（最高連勝数）の永続化。UserDefaults("bestStreak") に単一 Int を保存。
//  SwiftUI の @AppStorage("bestStreak") と同一キーで相互運用可能。テストでは
//  独立スイートを注入できる（Constitution Principle II: テスト容易性）。
//

import Foundation

struct BestStreakStore {
    static let key = "bestStreak"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var value: Int {
        get { defaults.integer(forKey: Self.key) }
        nonmutating set { defaults.set(newValue, forKey: Self.key) }
    }

    /// 今回の連勝数で自己ベストを更新（大きければ）。更新後の値を返す。
    @discardableResult
    func update(with finalStreak: Int) -> Int {
        if finalStreak > value { value = finalStreak }
        return value
    }
}
