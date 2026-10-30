-- 振替の種類（授業 / 合格講座）を区別する
ALTER TABLE makeups ADD COLUMN IF NOT EXISTS kind TEXT NOT NULL DEFAULT '授業';
