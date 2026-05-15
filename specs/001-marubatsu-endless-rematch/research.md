# Phase 0 Research: マルバツ・重ねがけ連勝モード

## R1. 自己ベストの永続化方式

- **Decision**: `@AppStorage("bestStreak")`（UserDefaults）に単一 Int を保存。
- **Rationale**: 保存対象は最高連勝数の単一スカラのみ。SwiftUI 標準で最も単純、
  ゼロ依存、Principle I（SwiftUI ネイティブ）に合致。アプリ再起動後も自動復元。
- **Alternatives considered**: SwiftData（憲法は「進行・履歴が必要なら SwiftData」。
  単一設定値には過剰でモデルコンテナ管理コスト増、却下）／ファイル直書き（手動 I/O
  が冗長、却下）。

## R2. 結合ルールの定式化

- **Decision**: `combine(existing, placing)` = `existing == placing ? placing.opponent : placing`
  （`existing == .empty` のときは `.empty` を相手扱いせず `placing` を返す: empty は
  opponent でも placing でもないため `existing == placing` が偽 → `placing`）。
- **Rationale**: 仕様の全4ケースを単一式で表現:
  - 空に置く → placing（○/×そのまま）
  - 同じマークに重ねる → 相手マーク（○+○→×、×+×→○）
  - 相手マークに重ねる → placing（○+×→○、×+○→×）
- **Alternatives considered**: ルックアップテーブル（冗長）／個別 if 連鎖（テスト性
  低下）。式が最小かつ全網羅で採用。

## R3. ラウンド進行（「全9マスに1回ずつ」）

- **Decision**: ラウンドごとに「このラウンドで着手済みのマス集合」を保持。プレイヤーは
  未着手マスのみ選択可。ユーザー先手・交互で 9 手（ユーザー5・AI4）。9手目完了で
  ラウンド終了し勝敗判定。各着手は結合ルールで盤面を更新（盤面はラウンド跨ぎで保持）。
- **Rationale**: 仕様の区切り定義「全9マスに1回ずつ重ねたら」を素直にモデル化。盤面と
  「当ラウンド着手済み」を分離することで重ねがけと引き継ぎが両立。
- **Alternatives considered**: マスごとの層スタックを保持（3D 構造）。表示は常に最新層
  のみで結合結果が確定値のため、層履歴の保持は不要と判断し却下（単純化）。

## R4. ラウンド勝敗判定

- **Decision**: ラウンド終了時点の盤面で 8 ライン（縦3・横3・斜2）を走査。○の3並び
  有無と×の3並び有無を算出。ユーザー勝利＝○ラインありかつ×ラインなし。敗北＝×あり
  かつ○なし。引き分け＝双方あり または 双方なし。判定はラウンド終了時のみ（途中の
  一時的3並びでは終了しない）。
- **Rationale**: 仕様 FR-007 と Assumptions（9手完了後にのみ判定）に一致。
- **Alternatives considered**: 即時終了（3並び発生で打ち切り）→ 仕様で否定済み、却下。

## R5. AI 難易度（連勝で強化、最高段階は勝てない）

- **Decision**: 難易度を連勝数の関数 `level(streak)` で段階化。AI の着手選択は
  「ヒューリスティック評価＋難易度依存のランダム性」。低難易度はランダム比率高め、
  難易度上昇でランダム比率を 0 に向けて低減し、最高段階では決定的探索（残りラウンド
  の最善応手探索）で「ユーザーが勝てない」着手を選ぶ。評価関数は結合ルール適用後の
  ライン数差＋ユーザー3並び阻止を加点。
- **Rationale**: 仕様は「観測可能な振る舞い」で規定（最低: 熟練ユーザー90%勝利／
  最高: 勝率0%）。本変種は古典三目並べと別物のため完全読みではなく、難易度スケール＋
  最高段階の探索で観測要件を満たす実装に倒す。ラウンドは最大9手で分岐限定のため
  端末上で許容コスト。
- **Alternatives considered**: 全段階で完全ミニマックス（低難易度の「勝てる」要件を
  満たせない、却下）／純ランダムのみ（最高段階で勝率0%にできない、却下）。

## R6. SwiftData 雛形の扱い

- **Decision**: `Item.swift` と `marubatsuApp` の `ModelContainer` を撤去。`@AppStorage`
  のみで永続。`ContentView` は対戦 UI に置換。
- **Rationale**: 本機能に SwiftData は不要。雛形残置は Principle I（単純さ／標準構成）
  に反し混乱の元。撤去で依存と複雑性を最小化。
- **Alternatives considered**: 雛形温存（未使用コード・不要コンテナ初期化が残る、却下）。

## R7. アクセシビリティ方針

- **Decision**: 各セルは Button、`accessibilityLabel`（位置＋現在マーク）と
  `accessibilityHint`（重ねた場合の結果）を付与。マークは記号（○/✕）で色非依存。
  最小タップ 44pt、Dynamic Type 対応、ライト/ダーク両対応。連勝数・結果は読み上げ対象。
- **Rationale**: Principle III の必須要件を満たす。
- **Alternatives considered**: 色のみで状態表現（Principle III 違反、却下）。

すべての NEEDS CLARIFICATION は spec のクラリフィケーション工程で解消済み。残課題なし。
