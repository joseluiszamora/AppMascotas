-- ============================================================
-- Migración: Lectura pública de reportes comunitarios
-- ============================================================
-- Permite que visitantes sin sesión consulten reportes abiertos.
-- Crear, editar y eliminar reportes sigue restringido a authenticated.

CREATE POLICY "reports_select_public_visible"
  ON public.reports
  FOR SELECT
  TO anon
  USING (status IN ('active', 'under_review'));

CREATE POLICY "report_photos_select_public_visible"
  ON public.report_photos
  FOR SELECT
  TO anon
  USING (
    EXISTS (
      SELECT 1
      FROM public.reports
      WHERE reports.id = report_photos.report_id
        AND reports.status IN ('active', 'under_review')
    )
  );

CREATE POLICY "pets_select_public_lost_reports"
  ON public.pets
  FOR SELECT
  TO anon
  USING (
    status = 'lost'
    AND EXISTS (
      SELECT 1
      FROM public.reports
      WHERE reports.pet_id = pets.id
        AND reports.status IN ('active', 'under_review')
    )
  );
