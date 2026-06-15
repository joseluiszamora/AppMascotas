-- ============================================================
-- Migración: Preferencia de tema del usuario
-- ============================================================

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS theme_preference TEXT NOT NULL DEFAULT 'system'
    CHECK (theme_preference IN ('system', 'light', 'dark'));
