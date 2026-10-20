-- 合格講座：受講者
CREATE TABLE goukaku_members (
  id         TEXT        PRIMARY KEY,
  student_id TEXT        NOT NULL UNIQUE REFERENCES students(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE goukaku_members ENABLE ROW LEVEL SECURITY;
CREATE POLICY "authenticated_only" ON goukaku_members FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- 合格講座：出欠（備考つき。通常授業の出欠とは別管理）
CREATE TABLE goukaku_attendance (
  id         TEXT        PRIMARY KEY,
  student_id TEXT        NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  date       TEXT        NOT NULL,
  status     TEXT,
  memo       TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (student_id, date)
);
ALTER TABLE goukaku_attendance ENABLE ROW LEVEL SECURITY;
CREATE POLICY "authenticated_only" ON goukaku_attendance FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- 合格講座だけの休講日（校舎別）
CREATE TABLE goukaku_holidays (
  id         TEXT        PRIMARY KEY,
  date       TEXT        NOT NULL,
  memo       TEXT,
  campus     TEXT        NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (date, campus)
);
ALTER TABLE goukaku_holidays ENABLE ROW LEVEL SECURITY;
CREATE POLICY "authenticated_only" ON goukaku_holidays FOR ALL TO authenticated USING (true) WITH CHECK (true);
