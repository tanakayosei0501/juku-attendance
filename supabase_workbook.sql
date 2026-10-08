-- 学校ワーク進捗テーブル（1生徒×1教科ごとに1行。rounds = 終わった周回数 0〜3）
CREATE TABLE student_workbooks (
  id         TEXT        PRIMARY KEY,
  student_id TEXT        NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  subject    TEXT        NOT NULL,
  rounds     INTEGER     NOT NULL DEFAULT 0,
  updated_at TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (student_id, subject)
);
ALTER TABLE student_workbooks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "authenticated_only" ON student_workbooks FOR ALL TO authenticated USING (true) WITH CHECK (true);
