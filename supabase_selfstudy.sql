-- 宿題忘れ自学（月曜）の出欠。通常授業の出欠とは別管理
CREATE TABLE selfstudy_attendance (
  id         TEXT        PRIMARY KEY,
  student_id TEXT        NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  date       TEXT        NOT NULL,
  status     TEXT,
  memo       TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (student_id, date)
);
ALTER TABLE selfstudy_attendance ENABLE ROW LEVEL SECURITY;
CREATE POLICY "authenticated_only" ON selfstudy_attendance FOR ALL TO authenticated USING (true) WITH CHECK (true);
