# App Review — Reply for Guideline 2.1 (Information Needed)

App: Max Hard マルバツ (Max Hard Marubatsu) — single-player board game, v1.0

> Paste the **"Review Notes (English)"** block below into App Store Connect →
> App Review Information → **Notes**, and reply to the message in Resolution Center.
> Also attach the screen recording (see "Screen recording" section — must be done
> by you on a physical device).

---

## Review Notes (English) — paste into the Notes field

This is a single-player offline board game (a "stacking tic-tac-toe" variant).
There is no account, no login, no in-app purchase or subscription, no
user-generated content, no ads, and no analytics. The app does not request any
permissions and does not access sensitive data (no location, contacts, camera,
microphone, photos, or App Tracking Transparency prompts). No demo account or
sample files are required — all features are available immediately on launch.

1) Screen recording: Attached. It launches the app and shows the full core
   flow: making a move, the AI thinking and responding, winning a round, the
   board growing on win streaks, and the result screen.

2) Devices/OS tested before submission:
   - iPhone [MODEL] running iOS [VERSION]   ← fill in your real device(s)
   - iOS Simulator (iPhone 17, iOS 26.5) for automated unit tests
   (Please replace the bracketed values with the actual physical devices used.)

3) Purpose and target audience: A brain/strategy puzzle game for casual players
   who enjoy tic-tac-toe and logic challenges. It reinvents tic-tac-toe with
   "stacking" placement, capture, a two-line win condition, an auto-balancing
   turn system, and a board that grows from 4x4 up to 10x10 as the player wins
   in a row. The value is a quick, deep, offline single-player challenge against
   a very strong AI; the goal is to maximize the win streak and reach the
   10x10 "complete victory". Suitable for all ages.

4) Setup / accessing main features: No setup or credentials needed. On launch
   the user sees the board and immediately taps a cell to place their mark (O).
   The AI (X) responds automatically. Win by forming two N-in-a-row lines at the
   same time; winning grows the board and continues the streak; losing ends the
   streak and the result screen offers "retry" from 4x4. The best streak is
   saved locally.

5) External services/tools used for core functionality: None that send data off
   the device. The game logic is fully on-device. For the AI opponent, on
   capable devices the app uses Apple's on-device foundation model via the
   Apple FoundationModels framework (Apple Intelligence) — all processing is
   on-device with no network calls. On devices where Apple Intelligence is
   unavailable, the app automatically falls back to its own built-in
   deterministic search algorithm. No third-party SDKs, no servers, no payment
   processors, no authentication services.

6) Regional differences: None. The app functions identically in all regions and
   does not depend on region, language, or network.

7) Regulated industry / protected third-party material: Not applicable. The app
   is an original game with no protected third-party content and does not
   operate in a regulated industry.

---

## Screen recording (you must capture this on a physical device)

Apple requires a recording made on a real device running the latest OS.

How to record on iPhone:
1. Settings → Control Center → add **Screen Recording**.
2. Open Control Center, tap the record button, wait 3s, then open the app.
3. Demonstrate this flow (~30–60s is enough):
   - App launches → title screen "MAX HARD マルバツ" then the 4x4 board.
   - Tap a cell to place O → "AI が考え中…" appears → AI places X (step by step).
   - Play until you win a round → the winning 2 lines highlight → board grows
     (4x4 → 5x5).
   - Continue 1–2 rounds, then lose once → the result/"連勝終了" screen with
     best streak and "もう一度" button.
4. Stop recording (Control Center or tap the red status bar).
5. In App Store Connect → Resolution Center, reply and attach this video, and
   paste the Review Notes above into App Review Information → Notes.

Tip: do it on the newest iOS you have. If you have an Apple Intelligence–capable
device, that shows the on-device AI path; otherwise the fallback AI is fine and
behaves the same to the user.

---

## レビュー返信メモ（日本語・参考）

本アプリは完全オフラインの1人用ボードゲーム（重ねがけ式マルバツ）。アカウント／
ログイン／課金・サブスク／UGC／広告／解析なし。権限要求・センシティブデータ
アクセスなし（位置・連絡先・カメラ・ATT 等のプロンプト無し）。デモアカウントや
サンプル不要、起動直後に全機能利用可。

AI 対戦は、対応端末では Apple のオンデバイス基盤モデル（Apple FoundationModels /
Apple Intelligence）を使用し処理は端末内で完結（通信なし）。非対応端末では内蔵の
決定的探索アルゴリズムへ自動フォールバック。外部サーバー・第三者SDK・決済・認証は
一切なし。地域差なし。規制業種・保護対象の第三者素材なし。

→ 上記英語ブロックを App Store Connect の「App Review Information → Notes」に貼り、
   実機で撮った画面収録を Resolution Center に添付して返信する。

---

## スクリーンショット確認結果（Guideline 2.3.3）

`screen/1-3.png`（1242×2688）を確認: 1=初期盤面、2=対戦中、3=勝利ライン
ハイライト。いずれも実際のプレイ画面で **2.3.3 は問題なし**（タイトル/スプラッシュ
のみではない）。任意改善: #1 を「対戦が進んだ画面」に差し替えると訴求が強い。

---

## ✅ 対応済: 未使用 Game Center 削除＋ビルド番号更新

- `marubatsu/marubatsu.entitlements` から `com.apple.developer.game-center` を
  削除（空の dict に）。コードに GameKit 不使用を確認済み。pbxproj に capability
  登録は無し（entitlements のみだった）。
- ビルド番号を 1→2 に更新（`CURRENT_PROJECT_VERSION = 2`、`MARKETING_VERSION`
  は 1.0 維持）= App Store Connect で一意な新ビルドとして必要。
- クリーンビルド＋全25テスト緑（iOS 26.5 sim）。

**次の手順（あなた）**: Xcode で Archive → Organizer から App Store Connect へ
アップロード（ビルド2）→ そのビルドを審査に添付し、下記 Notes ＋実機画面収録を
付けて 2.1 に返信する。

その他、権限要求・purpose string は無し（`NS...UsageDescription` 不在を確認済み＝
Notes の「権限なし」記述と一致）。
