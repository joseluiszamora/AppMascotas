-- ============================================================
-- Migración 008: Notificaciones internas y alertas relevantes
-- ============================================================

CREATE TABLE public.notifications (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  report_id  UUID        NOT NULL REFERENCES public.reports(id) ON DELETE CASCADE,
  actor_id   UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type       TEXT        NOT NULL
               CHECK (type IN ('nearby_lost_report', 'nearby_found_report')),
  title      TEXT        NOT NULL,
  body       TEXT        NOT NULL,
  read_at    TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_notifications_unique_report_per_user_type
  ON public.notifications(user_id, report_id, type);

CREATE INDEX idx_notifications_user_created_at
  ON public.notifications(user_id, created_at DESC);

CREATE INDEX idx_notifications_unread
  ON public.notifications(user_id, read_at);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "notifications_select_own"
  ON public.notifications
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "notifications_update_own"
  ON public.notifications
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE OR REPLACE FUNCTION public.create_report_notifications()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_pet_type TEXT;
  v_title TEXT;
  v_body TEXT;
BEGIN
  IF NEW.type = 'lost' THEN
    SELECT p.type, COALESCE(p.name, 'Mascota perdida')
      INTO v_pet_type, v_title
      FROM public.pets p
     WHERE p.id = NEW.pet_id;

    v_body := v_title || ' fue reportada y coincide con tus preferencias de alertas.';
  ELSE
    v_pet_type := NEW.found_pet_type;
    v_title := CASE NEW.found_pet_type
      WHEN 'cat' THEN 'Gato encontrado cerca de tu interés'
      WHEN 'other' THEN 'Mascota encontrada cerca de tu interés'
      ELSE 'Perro encontrado cerca de tu interés'
    END;
    v_body := 'Se registró una mascota encontrada que coincide con tus preferencias. Revisa el detalle del reporte.';
  END IF;

  INSERT INTO public.notifications (
    user_id,
    report_id,
    actor_id,
    type,
    title,
    body
  )
  SELECT
    profile.id,
    NEW.id,
    NEW.reporter_id,
    CASE WHEN NEW.type = 'lost' THEN 'nearby_lost_report' ELSE 'nearby_found_report' END,
    CASE WHEN NEW.type = 'lost' THEN 'Nueva mascota perdida' ELSE 'Nueva mascota encontrada' END,
    v_body
  FROM public.profiles profile
  WHERE profile.id <> NEW.reporter_id
    AND profile.notifications_enabled = TRUE
    AND COALESCE((profile.notification_types ->> NEW.type)::BOOLEAN, TRUE) = TRUE
    AND (
      profile.pet_preferences = 'both'
      OR (profile.pet_preferences = 'dogs' AND v_pet_type = 'dog')
      OR (profile.pet_preferences = 'cats' AND v_pet_type = 'cat')
      OR (profile.pet_preferences = 'others' AND v_pet_type = 'other')
    )
  ON CONFLICT (user_id, report_id, type) DO NOTHING;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS reports_create_notifications ON public.reports;

CREATE TRIGGER reports_create_notifications
  AFTER INSERT ON public.reports
  FOR EACH ROW EXECUTE FUNCTION public.create_report_notifications();