-- 小テスト定義テーブル
CREATE TABLE quiz_tests (
  id         TEXT        PRIMARY KEY,
  date       TEXT        NOT NULL,
  title      TEXT        NOT NULL,
  max_score  INTEGER     NOT NULL DEFAULT 100,
  pass_score INTEGER     NOT NULL DEFAULT 60,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE quiz_tests ENABLE ROW LEVEL SECURITY;
CREATE POLICY "authenticated_only" ON quiz_tests FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- 小テスト点数テーブル
CREATE TABLE quiz_scores (
  id         TEXT        PRIMARY KEY,
  test_id    TEXT        NOT NULL REFERENCES quiz_tests(id) ON DELETE CASCADE,
  student_id TEXT        NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  score      INTEGER,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (test_id, student_id)
);
ALTER TABLE quiz_scores ENABLE ROW LEVEL SECURITY;
CREATE POLICY "authenticated_only" ON quiz_scores FOR ALL TO authenticated USING (true) WITH CHECK (true);
