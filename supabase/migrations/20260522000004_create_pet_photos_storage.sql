-- ============================================================
-- Migración 004: Storage para fotos de mascotas
-- ============================================================

-- Bucket público para servir imágenes mediante getPublicUrl().
INSERT INTO storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
VALUES (
  'pet-photos',
  'pet-photos',
  TRUE,
  5242880,
  ARRAY[
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/heic',
    'image/heif',
    'image/gif'
  ]
)
ON CONFLICT (id) DO UPDATE
SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

DROP POLICY IF EXISTS "pet_photos_storage_insert_own" ON storage.objects;
CREATE POLICY "pet_photos_storage_insert_own"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'pet-photos'
    AND (storage.foldername(name))[1] = (SELECT auth.uid()::text)
    AND EXISTS (
      SELECT 1
      FROM public.pets
      WHERE pets.id::text = (storage.foldername(name))[2]
        AND pets.owner_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "pet_photos_storage_update_own" ON storage.objects;
CREATE POLICY "pet_photos_storage_update_own"
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'pet-photos'
    AND (storage.foldername(name))[1] = (SELECT auth.uid()::text)
    AND EXISTS (
      SELECT 1
      FROM public.pets
      WHERE pets.id::text = (storage.foldername(name))[2]
        AND pets.owner_id = auth.uid()
    )
  )
  WITH CHECK (
    bucket_id = 'pet-photos'
    AND (storage.foldername(name))[1] = (SELECT auth.uid()::text)
    AND EXISTS (
      SELECT 1
      FROM public.pets
      WHERE pets.id::text = (storage.foldername(name))[2]
        AND pets.owner_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "pet_photos_storage_delete_own" ON storage.objects;
CREATE POLICY "pet_photos_storage_delete_own"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'pet-photos'
    AND (storage.foldername(name))[1] = (SELECT auth.uid()::text)
    AND EXISTS (
      SELECT 1
      FROM public.pets
      WHERE pets.id::text = (storage.foldername(name))[2]
        AND pets.owner_id = auth.uid()
    )
  );