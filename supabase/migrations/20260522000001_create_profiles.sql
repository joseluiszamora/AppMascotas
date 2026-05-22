-- ============================================================
-- Migración 001: Perfiles de usuario
-- ============================================================

-- Función reutilizable para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- ============================================================
-- Tabla: profiles
-- ============================================================
CREATE TABLE public.profiles (
  id                     UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  first_name             TEXT,
  last_name              TEXT,
  phone                  TEXT,
  phone_visible          BOOLEAN     NOT NULL DEFAULT FALSE,
  avatar_url             TEXT,
  -- Preferencias de mascotas: dogs | cats | both | others
  pet_preferences        TEXT        NOT NULL DEFAULT 'both'
                           CHECK (pet_preferences IN ('dogs', 'cats', 'both', 'others')),
  notifications_enabled  BOOLEAN     NOT NULL DEFAULT TRUE,
  notification_radius_km INTEGER     NOT NULL DEFAULT 10
                           CHECK (notification_radius_km > 0 AND notification_radius_km <= 200),
  notification_types     JSONB       NOT NULL DEFAULT '{"lost": true, "found": true}'::jsonb,
  created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Trigger: actualizar updated_at automáticamente
CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================
-- RLS
-- ============================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Cualquier usuario autenticado puede leer perfiles
CREATE POLICY "profiles_select_authenticated"
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (TRUE);

-- El usuario solo puede insertar su propio perfil
CREATE POLICY "profiles_insert_own"
  ON public.profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (id = auth.uid());

-- El usuario solo puede actualizar su propio perfil
CREATE POLICY "profiles_update_own"
  ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- No se permite borrar perfiles directamente (CASCADE desde auth.users)
-- (No se crea policy DELETE → bloqueado por RLS)

-- ============================================================
-- Función: crear perfil automáticamente tras registro
-- Se activa con el trigger en auth.users
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id)
  VALUES (NEW.id)
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- Índices
-- ============================================================
-- La PK ya tiene índice; no se necesitan adicionales en esta tabla.
