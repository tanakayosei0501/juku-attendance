-- =====================================================================
-- 音声メモAI 授業報告システム — Supabase セットアップSQL
-- Supabase SQL Editor で実行してください
-- =====================================================================

-- 講師テーブル
CREATE TABLE IF NOT EXISTS vr_teachers (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_user_id UUID UNIQUE,
  name        TEXT NOT NULL,
  campus      TEXT NOT NULL,
  role        TEXT NOT NULL DEFAULT 'teacher', -- 'admin' | 'teacher'
  active      BOOLEAN DEFAULT true,
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- 生徒テーブル
CREATE TABLE IF NOT EXISTS vr_students (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name            TEXT NOT NULL,
  grade           TEXT,
  campus          TEXT NOT NULL,
  teacher_id      UUID REFERENCES vr_teachers(id),
  subjects        TEXT[],
  parent_name     TEXT,
  parent_contact  TEXT,
  notes           TEXT,
  active          BOOLEAN DEFAULT true,
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
);

-- 授業セッションテーブル
CREATE TABLE IF NOT EXISTS vr_sessions (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id            UUID NOT NULL REFERENCES vr_teachers(id),
  student_id            UUID NOT NULL REFERENCES vr_students(id),
  campus                TEXT NOT NULL,
  subject               TEXT,
  started_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  ended_at              TIMESTAMPTZ,
  status                TEXT NOT NULL DEFAULT 'recording',
  -- status values:
  -- recording / saved / processing / review_pending / approved / sent / error
  memo_count            INTEGER DEFAULT 0,
  total_duration_sec    INTEGER DEFAULT 0,
  combined_transcript   TEXT,
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now()
);

-- 音声メモテーブル
CREATE TABLE IF NOT EXISTS vr_voice_memos (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  local_id            TEXT NOT NULL UNIQUE, -- クライアント生成ID（重複防止）
  session_id          UUID NOT NULL REFERENCES vr_sessions(id) ON DELETE CASCADE,
  recorded_at         TIMESTAMPTZ NOT NULL,
  duration_sec        REAL,
  storage_path        TEXT,                 -- Supabase Storageのパス
  upload_status       TEXT NOT NULL DEFAULT 'local',
  -- upload_status: local / uploading / uploaded / error
  transcript          TEXT,
  transcript_status   TEXT NOT NULL DEFAULT 'pending',
  -- transcript_status: pending / processing / done / error
  created_at          TIMESTAMPTZ DEFAULT now()
);

-- AI分析テーブル
CREATE TABLE IF NOT EXISTS vr_analysis (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id  UUID NOT NULL UNIQUE REFERENCES vr_sessions(id) ON DELETE CASCADE,
  subject     TEXT,
  unit        TEXT,
  content     JSONB,  -- { content, understanding, achievements, issues, next_steps }
  created_at  TIMESTAMPTZ DEFAULT now(),
  updated_at  TIMESTAMPTZ DEFAULT now()
);

-- 保護者向け報告テーブル
CREATE TABLE IF NOT EXISTS vr_reports (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id      UUID NOT NULL UNIQUE REFERENCES vr_sessions(id) ON DELETE CASCADE,
  content         TEXT NOT NULL,           -- AI生成原文
  edited_content  TEXT,                    -- 先生が編集した場合
  status          TEXT NOT NULL DEFAULT 'review_pending',
  -- status: review_pending / approved / sent
  approved_at     TIMESTAMPTZ,
  sent_at         TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
);

-- 設定テーブル（塾ごとのカスタム設定）
CREATE TABLE IF NOT EXISTS vr_settings (
  key         TEXT PRIMARY KEY,
  value       TEXT,
  updated_at  TIMESTAMPTZ DEFAULT now()
);

-- =====================================================================
-- RLS（行レベルセキュリティ）
-- =====================================================================

ALTER TABLE vr_teachers    ENABLE ROW LEVEL SECURITY;
ALTER TABLE vr_students    ENABLE ROW LEVEL SECURITY;
ALTER TABLE vr_sessions    ENABLE ROW LEVEL SECURITY;
ALTER TABLE vr_voice_memos ENABLE ROW LEVEL SECURITY;
ALTER TABLE vr_analysis    ENABLE ROW LEVEL SECURITY;
ALTER TABLE vr_reports     ENABLE ROW LEVEL SECURITY;
ALTER TABLE vr_settings    ENABLE ROW LEVEL SECURITY;

CREATE POLICY "authenticated_only" ON vr_teachers    FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_only" ON vr_students    FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_only" ON vr_sessions    FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_only" ON vr_voice_memos FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_only" ON vr_analysis    FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_only" ON vr_reports     FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_only" ON vr_settings    FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- =====================================================================
-- Supabase Storage バケット（voice-memos）
-- ※ RLSエラーが出る場合はSupabaseダッシュボード → Storage から手動で作成
-- =====================================================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'voice-memos',
  'voice-memos',
  false,
  52428800,  -- 50MB上限
  ARRAY['audio/webm', 'audio/ogg', 'audio/mp4', 'audio/mpeg', 'audio/wav', 'audio/aac']
)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS
CREATE POLICY "voice_upload" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'voice-memos');

CREATE POLICY "voice_select" ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'voice-memos');

CREATE POLICY "voice_delete" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'voice-memos');

-- =====================================================================
-- 初期データ（任意）
-- =====================================================================

-- 初回管理者アカウント作成後、以下を手動編集して実行:
-- INSERT INTO vr_teachers (auth_user_id, name, campus, role)
-- VALUES ('<Supabase AuthのUUID>', '管理者名', '鶴瀬東', 'admin');

-- =====================================================================
-- ✅ 完了後の確認
-- SELECT * FROM vr_teachers;
-- SELECT * FROM vr_students;
-- SELECT bucket_id, name FROM storage.buckets WHERE id = 'voice-memos';
-- =====================================================================
