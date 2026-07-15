-- ════════════════════════════════════════════
--  校舎（branch）対応 — students / holidays
-- ════════════════════════════════════════════

-- 1) students テーブルに校舎列を追加
ALTER TABLE students
  ADD COLUMN IF NOT EXISTS branch TEXT NOT NULL DEFAULT '鶴瀬東校舎';

-- 2) 既存の生徒を全員「鶴瀬東校舎」に設定
UPDATE students
  SET branch = '鶴瀬東校舎'
  WHERE branch IS NULL OR branch = '';

-- 3) holidays テーブルに校舎列を追加
ALTER TABLE holidays
  ADD COLUMN IF NOT EXISTS branch TEXT NOT NULL DEFAULT '鶴瀬東校舎';

-- 4) 既存の休講日を「鶴瀬東校舎」に設定
UPDATE holidays
  SET branch = '鶴瀬東校舎'
  WHERE branch IS NULL OR branch = '';
