-- ============================================================
-- Migración 002: Mascotas y fotos de mascotas
-- ============================================================

-- ============================================================
-- Tabla: pets
-- ============================================================
CREATE TABLE public.pets (
  id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id                UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  name                    TEXT        NOT NULL,
  -- Tipo: dog | cat | other
  type                    TEXT        NOT NULL
                            CHECK (type IN ('dog', 'cat', 'other')),
  breed                   TEXT,
  -- Sexo: male | female | unknown
  sex                     TEXT        NOT NULL DEFAULT 'unknown'
                            CHECK (sex IN ('male', 'female', 'unknown')),
  age_years               INTEGER     CHECK (age_years >= 0 AND age_years <= 30),
  age_months              INTEGER     CHECK (age_months >= 0 AND age_months <= 11),
  dominant_color          TEXT,
  -- Tamaño: small | medium | large | extra_large
  size                    TEXT        NOT NULL DEFAULT 'medium'
                            CHECK (size IN ('small', 'medium', 'large', 'extra_large')),
  distinctive_features    TEXT,
  is_vaccinated           BOOLEAN     NOT NULL DEFAULT FALSE,
  is_sterilized           BOOLEAN     NOT NULL DEFAULT FALSE,
  chip_number             TEXT,
  -- Estado: normal | lost | found
  status                  TEXT        NOT NULL DEFAULT 'normal'
                            CHECK (status IN ('normal', 'lost', 'found')),
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Trigger: actualizar updated_at automáticamente
CREATE TRIGGER pets_updated_at
  BEFORE UPDATE ON public.pets
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================
-- RLS: pets
-- ============================================================
ALTER TABLE public.pets ENABLE ROW LEVEL SECURITY;

-- Cualquier usuario autenticado puede ver mascotas (necesario para búsqueda de perdidas)
CREATE POLICY "pets_select_authenticated"
  ON public.pets
  FOR SELECT
  TO authenticated
  USING (TRUE);

-- Solo el dueño puede registrar mascotas propias
CREATE POLICY "pets_insert_own"
  ON public.pets
  FOR INSERT
  TO authenticated
  WITH CHECK (owner_id = auth.uid());

-- Solo el dueño puede editar sus mascotas
CREATE POLICY "pets_update_own"
  ON public.pets
  FOR UPDATE
  TO authenticated
  USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());

-- Solo el dueño puede eliminar sus mascotas
CREATE POLICY "pets_delete_own"
  ON public.pets
  FOR DELETE
  TO authenticated
  USING (owner_id = auth.uid());

-- ============================================================
-- Tabla: pet_photos
-- ============================================================
CREATE TABLE public.pet_photos (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id     UUID        NOT NULL REFERENCES public.pets(id) ON DELETE CASCADE,
  url        TEXT        NOT NULL,
  is_primary BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- RLS: pet_photos
-- ============================================================
ALTER TABLE public.pet_photos ENABLE ROW LEVEL SECURITY;

-- Cualquier usuario autenticado puede ver fotos de mascotas
CREATE POLICY "pet_photos_select_authenticated"
  ON public.pet_photos
  FOR SELECT
  TO authenticated
  USING (TRUE);

-- Solo el dueño de la mascota puede subir fotos
CREATE POLICY "pet_photos_insert_own"
  ON public.pet_photos
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.pets
      WHERE pets.id = pet_photos.pet_id
        AND pets.owner_id = auth.uid()
    )
  );

-- Solo el dueño de la mascota puede eliminar fotos
CREATE POLICY "pet_photos_delete_own"
  ON public.pet_photos
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.pets
      WHERE pets.id = pet_photos.pet_id
        AND pets.owner_id = auth.uid()
    )
  );

-- ============================================================
-- Índices
-- ============================================================
CREATE INDEX idx_pets_owner_id  ON public.pets(owner_id);
CREATE INDEX idx_pets_status    ON public.pets(status);
CREATE INDEX idx_pets_type      ON public.pets(type);
CREATE INDEX idx_pet_photos_pet ON public.pet_photos(pet_id);
