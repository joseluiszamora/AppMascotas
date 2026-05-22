-- ============================================================
-- Migración 006: RPC para crear reportes de mascota perdida
-- ============================================================

CREATE OR REPLACE FUNCTION public.create_lost_report(
  p_pet_id UUID,
  p_latitude DECIMAL,
  p_longitude DECIMAL,
  p_location_description TEXT,
  p_occurred_at TIMESTAMPTZ,
  p_description TEXT,
  p_show_contact BOOLEAN
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_report_id UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Usuario no autenticado';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.pets
    WHERE id = p_pet_id
      AND owner_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'La mascota seleccionada no pertenece al usuario autenticado';
  END IF;

  INSERT INTO public.reports (
    reporter_id,
    pet_id,
    type,
    latitude,
    longitude,
    location_description,
    occurred_at,
    description,
    status,
    show_contact
  )
  VALUES (
    auth.uid(),
    p_pet_id,
    'lost',
    p_latitude,
    p_longitude,
    p_location_description,
    p_occurred_at,
    p_description,
    'active',
    COALESCE(p_show_contact, FALSE)
  )
  RETURNING id INTO v_report_id;

  INSERT INTO public.report_photos (report_id, url)
  SELECT v_report_id, pet_photos.url
  FROM public.pet_photos
  WHERE pet_photos.pet_id = p_pet_id;

  UPDATE public.pets
  SET
    status = 'lost',
    updated_at = NOW()
  WHERE id = p_pet_id
    AND owner_id = auth.uid();

  RETURN v_report_id;
END;
$$;