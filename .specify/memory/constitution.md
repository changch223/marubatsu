<!--
SYNC IMPACT REPORT
==================
Version change: (template / unversioned) → 1.0.0
Bump rationale: Initial ratification — placeholder template replaced with concrete
  governance. Treated as the first formal version (MAJOR baseline 1.0.0).

Modified principles:
  - [PRINCIPLE_1_NAME] → I. SwiftUI ネイティブパターン優先
  - [PRINCIPLE_2_NAME] → II. ゲームルールの正確性（NON-NEGOTIABLE）
  - [PRINCIPLE_3_NAME] → III. UX とアクセシビリティ品質
  - [PRINCIPLE_4_NAME], [PRINCIPLE_5_NAME] → removed (project opted for 3 focused
    principles derived from user-selected themes; see follow-up note)

Added sections:
  - 技術制約 (Technical Constraints)
  - 開発ワークフローと品質ゲート (Development Workflow & Quality Gates)

Removed sections: none (template section slots repurposed, not dropped)

Templates requiring updates:
  - .specify/templates/plan-template.md ✅ no change needed (Constitution Check is
    generic: "[Gates determined based on constitution file]")
  - .specify/templates/spec-template.md ✅ no change needed (no principle coupling)
  - .specify/templates/tasks-template.md ✅ no change needed (no principle coupling)
  - .specify/templates/commands/*.md ✅ none present / no outdated references
  - README.md ⚠ not present (no runtime guidance doc to sync)

Follow-up TODOs:
  - Principle set reduced to 3 per user-selected themes (SwiftUI + native patterns,
    UX & accessibility quality) plus the game's intrinsic rule-correctness
    requirement. Test-First and Simplicity were deselected and are NOT mandated;
    revisit if process maturity increases.
-->

# marubatsu（〇✕ゲーム）Constitution

## Core Principles

### I. SwiftUI ネイティブパターン優先
画面とロジックは SwiftUI の宣言的パターンと標準コンポーネントで構築する。状態管理は
`@State` / `@Observable` / SwiftData など Apple 標準の仕組みを用い、サードパーティ製の
状態管理・UI ライブラリを既定で導入しない（採用する場合は本憲法の改訂手続きを要する）。
ナビゲーション、SF Symbols、ライト/ダーク対応などプラットフォーム慣習に従う。

理由: 標準パターンは保守性、将来の iOS バージョン互換性、そして小規模アプリにおける
構造の単純さを最大化する。

### II. ゲームルールの正確性（NON-NEGOTIABLE）
〇✕の勝敗判定、引き分け、手番交代、不正手（埋まったマスへの着手）の禁止といった
ゲームロジックは、View から分離した純粋な型（UI 非依存）に実装する。8 通りの勝利
パターンおよび引き分けを網羅する XCTest 自動テストでロジックを保証し、ロジック変更は
テストが緑であることを確認してからマージする。

理由: ゲームの中核価値は正しい勝敗判定であり、判定の誤りはユーザー信頼を即座に
損なう。ここだけはテストを非交渉事項とする。

### III. UX とアクセシビリティ品質
全ての対話要素は VoiceOver ラベルを持ち、Dynamic Type と最小タップ領域 44pt を
満たす。盤面状態（〇・✕・空・勝敗ライン）は色のみに依存せず形・記号でも判別でき、
ライト/ダーク両モードで視認可能にする。新規ゲーム開始・着手・結果確認といった主要
操作は 3 タップ以内で到達できる。

理由: 単純なゲームであっても、誰もが快適に遊べることがプロダクトの最低基準である。

## 技術制約 (Technical Constraints)

- 言語/フレームワーク: Swift + SwiftUI、ターゲットは iOS（必要に応じて macOS も
  同一コードで対応）。
- 永続化: ゲーム進行・履歴が必要な場合は SwiftData を用いる。外部ネットワーク依存
  を持たず、オフラインで完全に動作する。
- 依存関係: 標準ライブラリ／Apple フレームワークを既定とし、外部依存の追加は
  Principle I に従い改訂手続きを経る。
- テスト: XCTest を用い、ゲームロジックは UI から分離してテスト可能にする
  （Principle II）。

## 開発ワークフローと品質ゲート (Development Workflow & Quality Gates)

- 機能開発は Spec Kit フロー（specify → plan → tasks → implement）に従う。
- 全ての変更は本憲法への準拠をレビューで確認する。ゲームロジックに触れる変更は
  関連 XCTest が緑であることをマージ条件とする。
- UI 変更は VoiceOver・Dynamic Type・ライト/ダークの確認（Principle III）を
  完了基準に含める。
- 複雑さを増す決定（外部依存、独自状態管理など）は plan の Complexity Tracking で
  正当化を文書化する。

## Governance

本憲法はプロジェクトの他の慣習に優先する。改訂には (a) 変更内容の文書化、
(b) セマンティックバージョニングに基づくバージョン更新、(c) 依存テンプレート・
ドキュメントへの影響反映、を要する。バージョニング規則: 原則の削除・後方非互換な
再定義は MAJOR、原則／節の追加・実質的な拡張は MINOR、文言・誤記・非意味的な
修正は PATCH。全ての PR レビューで本憲法への準拠を検証し、原則違反は是正または
明示的な正当化（plan の Complexity Tracking）を必須とする。実行時の開発ガイダンス
は `CLAUDE.md` および現行プランを参照する。

**Version**: 1.0.0 | **Ratified**: 2026-05-15 | **Last Amended**: 2026-05-15
