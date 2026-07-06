-- 宿題管理テーブル
CREATE TABLE homework (
  id          TEXT        PRIMARY KEY,
  student_id  TEXT        NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  date        TEXT        NOT NULL,
  status      TEXT,        -- NULL=未記録 / '完了' / '忘れ' / '欠席'
  memo        TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (student_id, date)
);

-- RLS有効化
ALTER TABLE homework ENABLE ROW LEVEL SECURITY;

-- ログイン済みユーザーのみ読み書き可
CREATE POLICY "authenticated_only" ON homework FOR ALL TO authenticated USING (true) WITH CHECK (true);
