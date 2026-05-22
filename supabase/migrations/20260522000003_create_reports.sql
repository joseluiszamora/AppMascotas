-- ============================================================
-- Migración 003: Reportes, fotos de reportes y avistamientos
-- ============================================================

-- ============================================================
-- Tabla: reports
-- ============================================================
CREATE TABLE public.reports (
  id                   UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id          UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  -- pet_id es nullable: en reportes de "encontrada" puede no haber mascota registrada
  pet_id               UUID        REFERENCES public.pets(id) ON DELETE SET NULL,
  -- Tipo: lost | found
  type                 TEXT        NOT NULL
                         CHECK (type IN ('lost', 'found')),
  -- Ubicación aproximada (lat/lng decimales)
  latitude             DECIMAL(10, 7) NOT NULL,
  longitude            DECIMAL(10, 7) NOT NULL,
  -- Descripción textual de la zona (ej: "Parque Central, Bogotá")
  location_description TEXT,
  occurred_at          TIMESTAMPTZ NOT NULL,
  description          TEXT,
  -- Estado: active | under_review | resolved | closed | reported
  status               TEXT        NOT NULL DEFAULT 'active'
                         CHECK (status IN ('active', 'under_review', 'resolved', 'closed', 'reported')),
  -- Si el usuario autoriza mostrar datos de contacto públicamente
  show_contact         BOOLEAN     NOT NULL DEFAULT FALSE,
  -- Campos de mascota encontrada sin registro previo (desnormalizados para MVP)
  found_pet_type       TEXT        CHECK (found_pet_type IN ('dog', 'cat', 'other')),
  found_pet_color      TEXT,
  found_pet_size       TEXT        CHECK (found_pet_size IN ('small', 'medium', 'large', 'extra_large')),
  found_pet_description TEXT,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Trigger: actualizar updated_at automáticamente
CREATE TRIGGER reports_updated_at
  BEFORE UPDATE ON public.reports
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================
-- RLS: reports
-- ============================================================
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

-- Cualquier usuario autenticado puede ver reportes activos y bajo revisión
CREATE POLICY "reports_select_authenticated"
  ON public.reports
  FOR SELECT
  TO authenticated
  USING (TRUE);

-- Solo el reportante puede crear reportes propios
CREATE POLICY "reports_insert_own"
  ON public.reports
  FOR INSERT
  TO authenticated
  WITH CHECK (reporter_id = auth.uid());

-- Solo el reportante puede actualizar su reporte
CREATE POLICY "reports_update_own"
  ON public.reports
  FOR UPDATE
  TO authenticated
  USING (reporter_id = auth.uid())
  WITH CHECK (reporter_id = auth.uid());

-- Solo el reportante puede eliminar su reporte
CREATE POLICY "reports_delete_own"
  ON public.reports
  FOR DELETE
  TO authenticated
  USING (reporter_id = auth.uid());

-- ============================================================
-- Tabla: report_photos
-- ============================================================
CREATE TABLE public.report_photos (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  report_id  UUID        NOT NULL REFERENCES public.reports(id) ON DELETE CASCADE,
  url        TEXT        NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- RLS: report_photos
-- ============================================================
ALTER TABLE public.report_photos ENABLE ROW LEVEL SECURITY;

-- Cualquier usuario autenticado puede ver fotos de reportes
CREATE POLICY "report_photos_select_authenticated"
  ON public.report_photos
  FOR SELECT
  TO authenticated
  USING (TRUE);

-- Solo el creador del reporte puede agregar fotos
CREATE POLICY "report_photos_insert_own"
  ON public.report_photos
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.reports
      WHERE reports.id = report_photos.report_id
        AND reports.reporter_id = auth.uid()
    )
  );

-- Solo el creador del reporte puede eliminar fotos
CREATE POLICY "report_photos_delete_own"
  ON public.report_photos
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.reports
      WHERE reports.id = report_photos.report_id
        AND reports.reporter_id = auth.uid()
    )
  );

-- ============================================================
-- Tabla: report_sightings
-- Avistamientos de mascotas reportadas como perdidas
-- ============================================================
CREATE TABLE public.report_sightings (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  report_id   UUID        NOT NULL REFERENCES public.reports(id) ON DELETE CASCADE,
  reporter_id UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  latitude    DECIMAL(10, 7) NOT NULL,
  longitude   DECIMAL(10, 7) NOT NULL,
  description TEXT,
  occurred_at TIMESTAMPTZ NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- RLS: report_sightings
-- ============================================================
ALTER TABLE public.report_sightings ENABLE ROW LEVEL SECURITY;

-- Cualquier usuario autenticado puede ver avistamientos
CREATE POLICY "sightings_select_authenticated"
  ON public.report_sightings
  FOR SELECT
  TO authenticated
  USING (TRUE);

-- Solo usuarios autenticados pueden reportar avistamientos propios
CREATE POLICY "sightings_insert_own"
  ON public.report_sightings
  FOR INSERT
  TO authenticated
  WITH CHECK (reporter_id = auth.uid());

-- Solo el autor puede actualizar su avistamiento
CREATE POLICY "sightings_update_own"
  ON public.report_sightings
  FOR UPDATE
  TO authenticated
  USING (reporter_id = auth.uid())
  WITH CHECK (reporter_id = auth.uid());

-- Solo el autor puede eliminar su avistamiento
CREATE POLICY "sightings_delete_own"
  ON public.report_sightings
  FOR DELETE
  TO authenticated
  USING (reporter_id = auth.uid());

-- ============================================================
-- Índices
-- ============================================================
CREATE INDEX idx_reports_reporter_id  ON public.reports(reporter_id);
CREATE INDEX idx_reports_pet_id       ON public.reports(pet_id);
CREATE INDEX idx_reports_type         ON public.reports(type);
CREATE INDEX idx_reports_status       ON public.reports(status);
-- Índice espacial simple para consultas por área (lat/lng)
CREATE INDEX idx_reports_location     ON public.reports(latitude, longitude);

CREATE INDEX idx_report_photos_report ON public.report_photos(report_id);

CREATE INDEX idx_sightings_report     ON public.report_sightings(report_id);
CREATE INDEX idx_sightings_reporter   ON public.report_sightings(reporter_id);
CREATE INDEX idx_sightings_location   ON public.report_sightings(latitude, longitude);
