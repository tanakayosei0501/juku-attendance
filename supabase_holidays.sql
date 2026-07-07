-- 休講日テーブル
CREATE TABLE holidays (
  id         TEXT        PRIMARY KEY,
  date       TEXT        NOT NULL UNIQUE,
  memo       TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS 有効化
ALTER TABLE holidays ENABLE ROW LEVEL SECURITY;

-- ログイン済みユーザーのみ読み書き可
CREATE POLICY "authenticated_only" ON holidays FOR ALL TO authenticated USING (true) WITH CHECK (true);
