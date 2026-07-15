-- 生徒プロファイル拡張（1対1）
CREATE TABLE student_profiles (
  student_id      TEXT PRIMARY KEY REFERENCES students(id) ON DELETE CASCADE,
  furigana        TEXT NOT NULL DEFAULT '',
  birthday        TEXT NOT NULL DEFAULT '',
  school_name     TEXT NOT NULL DEFAULT '',
  enrolled_date   TEXT NOT NULL DEFAULT '',
  siblings_memo   TEXT NOT NULL DEFAULT '',
  photo_url       TEXT NOT NULL DEFAULT '',
  subjects        TEXT NOT NULL DEFAULT '',
  target_school1  TEXT NOT NULL DEFAULT '',
  target_school2  TEXT NOT NULL DEFAULT '',
  goal            TEXT NOT NULL DEFAULT '',
  strong_subjects TEXT NOT NULL DEFAULT '',
  weak_subjects   TEXT NOT NULL DEFAULT '',
  naishinsho      TEXT NOT NULL DEFAULT '',
  personality     TEXT NOT NULL DEFAULT '',
  health_notes    TEXT NOT NULL DEFAULT '',
  free_memo       TEXT NOT NULL DEFAULT '',
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE student_profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "authenticated_only" ON student_profiles FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- テスト・模試履歴
CREATE TABLE student_tests (
  id         TEXT        PRIMARY KEY,
  student_id TEXT        NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  date       TEXT        NOT NULL,
  test_name  TEXT        NOT NULL,
  subject    TEXT        NOT NULL DEFAULT '',
  score      INTEGER,
  max_score  INTEGER,
  notes      TEXT        NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE student_tests ENABLE ROW LEVEL SECURITY;
CREATE POLICY "authenticated_only" ON student_tests FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- 保護者面談記録
CREATE TABLE student_consultations (
  id         TEXT        PRIMARY KEY,
  student_id TEXT        NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  date       TEXT        NOT NULL,
  memo       TEXT        NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE student_consultations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "authenticated_only" ON student_consultations FOR ALL TO authenticated USING (true) WITH CHECK (true);
