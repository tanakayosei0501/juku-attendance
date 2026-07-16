# 塾出席管理アプリ — 引き継ぎメモ（Claude Code 用）

このファイルはリポジトリ直下に置いてください。Claude Code が自動で読み込み、毎回この前提でアプリを理解した状態から作業できます。

## 0. 最初に読む人へ（重要な前提）

- オーナー（ようせい）は**非エンジニア**です。専門用語は避け、手順は噛み砕いて説明してください。
- **1つのアプリを2つの校舎（鶴瀬東・羽沢）で共用**しています。コードは1本、校舎ごとの違いは「データの校舎スコープ」か「campus_rules のON/OFF」で吸収する設計です。校舎ごとにアプリを分けないでください。
- 変更を加えたら、原則そのまま `git commit` → `git push`（main）まで行ってください。Vercel が main への push で自動デプロイします（1〜2分）。デプロイ後は Cmd+Shift+R で強制リロードして確認。

## 1. 構成

- **本体**: `index.html` ただ1ファイル（HTML・CSS・JS 全部インライン、ビルド工程なし・フレームワークなし・バニラJS）。
- **ホスティング**: Vercel（GitHub 連携で main への push を自動デプロイ）。本番 URL は juku-attendance-silk.vercel.app。
- **バックエンド**: Supabase（PostgreSQL + RLS）。`@supabase/supabase-js@2` を CDN 読み込み。
- **ログイン**: Supabase Auth の共有アカウント1つ。`FIXED_EMAIL = 'sensei@juku.local'`、パスワードのみ。校舎やユーザーごとの区別はなし。
- **その他ファイル**: `sw.js`（Service Worker）、`manifest.json`（PWA）、`icon.svg`、`vercel.json`、`supabase_*.sql`（機能ごとのスキーマ定義。1機能=1ファイルの慣習）。

Supabase 接続情報は `index.html` 内に定数で直書き（`SUPABASE_URL` / `SUPABASE_KEY`=publishable key / `FIXED_EMAIL`）。

## 2. データの持ち方（インメモリキャッシュ）

- 起動時に `loadAllData()` が全テーブルを `Promise.all` で取得し、グローバル `_db` に格納。以降のCRUDは `_db` を直接書き換えて全再取得を避ける方式。
- 画面は `getStudents() => _db.students` などのアクセサ経由で `_db` を読む。
- `id` はクライアント生成の TEXT: `uid() = Date.now().toString(36) + Math.random().toString(36).slice(2)`。
- **`days`（通塾曜日）は jsonb。曜日を数字の配列で持つ**。対応は `DAYS = ['月','火','水','木','金','土','日']` の**インデックス（月=0, 火=1, 水=2, 木=3, 金=4, 土=5, 日=6）**。例: 火木 = `[1,3]`。
- **`grade` は TEXT。必ず `GRADES` 配列と完全一致**させる: `小学1年生`〜`小学6年生`, `中学1年生`〜`中学3年生`, `高校1年生`〜`高校3年生`（数字は半角）。全角数字や「生」抜けは表示・絞り込みが崩れるので正規化すること。
- 出席ステータス: `STATUSES = ['出席','欠席','遅刻','早退','宿題忘れ自習']`。

## 3. 校舎機能（最重要）

内部の校舎値は **`'鶴瀬東'` と `'羽沢'`**（「校舎」なし。表示時に「校舎」を付ける）。

- `CURRENT_CAMPUS`（グローバル）= `localStorage['currentCampus']`（既定 `'鶴瀬東'`）。
- 画面上部の固定バー `renderCampusSwitcher()` で切替。`setCampus(c)` が localStorage を更新して `location.reload()`。→ 再読込のたびに `loadAllData()` が現在校舎で再フィルタ。
- **データ分離は「キャッシュを絞る」方式**。`loadAllData()` 末尾で:
  - `_db.students` を `campus === CURRENT_CAMPUS` で絞る。
  - その生徒IDの集合で、生徒紐づきの配列（attendance / makeups / homework / quizScores / studentProfiles / studentTests / studentConsultations）を絞る。
  - `_db.quizTests` は `campus === CURRENT_CAMPUS` で絞る。
  - `_db.holidays` は `campus === CURRENT_CAMPUS || campus === '共通'` で絞る。
- 新規作成時に校舎を刻む: `addStudent()`→`campus: CURRENT_CAMPUS`、`addQuizTest()`→`campus: CURRENT_CAMPUS`、`addHoliday()`→`hl-campus` セレクト（当該校舎 or `共通`）。
- **設計上の含意**: 既存の各画面ロジック（renderToday / renderAtt / renderHomework / 集計 / カルテ 等）は `_db` を読むだけなので、フィルタ済みキャッシュのおかげで自動的に現在校舎ぶんだけ表示される。新機能もこの前提に乗せれば校舎対応は自動。

## 4. 校舎ごとのルール ON/OFF

- テーブル `campus_rules(id, campus, rule_key, enabled, UNIQUE(campus, rule_key))`。
- 現状のルール: `homework_monday_selfstudy`（宿題忘れ→月曜自習）。シード: 鶴瀬東=ON、羽沢=OFF。
- `_db.campusRules` は全校舎ぶん保持（フィルタしない）。判定は **`isRuleEnabled(ruleKey, default=true)`**（現在校舎の行を見る）。
- 現在の適用箇所: `renderHwForgotCard()`（今日タブの宿題忘れカード）と `buildAttRows()` の「⚠️ 先週 宿題忘れ」バッジを、このルールで出し分け。
- 設定UI: 設定モーダル `#settings-modal` 内「📐 校舎ルール設定」。`renderRuleSettings()` が描画、`toggleRule()` が campus_rules を upsert。
- **新ルールの足し方**: `CAMPUS_RULE_DEFS` 配列に1項目（key / label / desc）を追加 → 設定画面にトグルが自動で並ぶ。そのルールで挙動を変えたい箇所で `isRuleEnabled('新key')` を呼ぶ。ON/OFFの初期値が要るなら campus_rules にシードINSERTを1本用意。

## 5. 休講日（校舎別・期間対応）

- テーブル `holidays(id, date TEXT, memo, campus, created_at)`、`UNIQUE(date, campus)`。既定 campus=`'共通'`。
- `共通` は両校舎に効く。校舎別は当該校舎名で保存。
- **期間登録**: `addHoliday()` は `hl-date`(開始) と `hl-end`(任意の終了) を読み、`dateRangeList(start,end)` で1日ずつ展開して**各日を個別の行としてまとめてINSERT**（月またぎ・年またぎOK、最大400日で打ち切り）。終了日が空なら1日だけ。重複日は自動スキップ。
- 各画面の休講判定は `_db.holidays`（校舎フィルタ済み）を日付で参照するだけ。

## 6. Supabase テーブル一覧

`students`（id, name, grade, days jsonb, campus, branch, created_at）※`branch` は旧列で未使用。アプリは `campus` を使う /
`attendance`（id, student_id, date, status, time, memo）/
`makeups`（id, student_id, original_date, makeup_date, memo, done）/
`homework`（id, student_id, date, status, memo）/
`holidays`（id, date, memo, campus, created_at）/
`quiz_tests`（id, date, title, max_score, pass_score, target_students, campus）/
`quiz_scores`（id, test_id, student_id, score）/
`student_profiles`（カルテ各種フィールド）/
`student_tests`（id, student_id, date, test_name, subject, score, max_score, notes）/
`student_consultations`（id, student_id, date, memo）/
`campus_rules`（id, campus, rule_key, enabled）/
`settings`（key, value）※連絡文テンプレを保存。

**RLS**: 全テーブル共通で `CREATE POLICY "authenticated_only" ON <table> FOR ALL TO authenticated USING (true) WITH CHECK (true);`。新テーブルを作る時も同じRLSを付けること。

※ campus 関連のスキーマ変更（`students.campus`, `quiz_tests.campus`, `holidays.campus`, `campus_rules` テーブル）は Supabase SQL Editor で直接適用済み。リポジトリの `supabase_*.sql` に未コミットの可能性があるので、スキーマ定義を残すなら追記を検討。

## 7. 既知の注意点・TODO

- **「復元する」ボタンは危険**。`confirmRestore()` が `students/attendance/makeups` を**全校舎まとめて全削除**してからバックアップJSON（campus列なし）を入れ直す。2校舎運用では両校舎を消して復元分を既定 `鶴瀬東` で作り直してしまう。使わないよう案内するか、校舎対応に改修してから使うこと。「保存する」（バックアップ）は安全。
- 生徒登録の一括投入は SQL で行った実績あり（羽沢=125人）。`days` は jsonb（`'[6]'::jsonb` 等）、`grade` は `GRADES` に一致、`campus='羽沢'`、`id` は一意な TEXT。
- 通塾曜日が未設定だった生徒は暫定で「日曜(=6)」登録。正しい曜日が決まったら編集 or 一括UPDATEで直す想定。
- 改善候補: 休講日の「期間まるごと削除」、復元の校舎対応、暫定日曜生徒の曜日一括更新。

## 8. 作業の進め方

- 変更は `index.html` を直接編集 → 動作確認 → `git commit` → `git push origin main`。Vercel が自動デプロイ。
- 動作確認は本番URLをブラウザで開き、校舎バーで両校舎を切替えて、対象機能が校舎ごとに正しく出るかを見る。Service Worker があるので確認時は Cmd+Shift+R。
- 破壊的なデータ操作（削除・一括更新）を伴う場合は、実行前にオーナーへ一言確認する。
