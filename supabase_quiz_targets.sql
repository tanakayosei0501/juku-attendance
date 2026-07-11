-- quiz_tests テーブルに対象者リスト列を追加
-- target_students: 対象生徒IDの配列（JSON）。空配列のときはその日の全生徒が対象
ALTER TABLE quiz_tests ADD COLUMN IF NOT EXISTS target_students JSONB NOT NULL DEFAULT '[]';
