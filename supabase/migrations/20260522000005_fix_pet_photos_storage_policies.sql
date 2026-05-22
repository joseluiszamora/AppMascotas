-- ============================================================
-- Migración 005: Ajuste de políticas de Storage para fotos
-- ============================================================

-- La propiedad de la mascota ya se valida al insertar en public.pet_photos.
-- En storage.objects solo restringimos bucket y carpeta del usuario.

DROP POLICY IF EXISTS "pet_photos_storage_insert_own" ON storage.objects;
CREATE POLICY "pet_photos_storage_insert_own"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'pet-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
    AND (storage.foldername(name))[2] IS NOT NULL
  );

DROP POLICY IF EXISTS "pet_photos_storage_update_own" ON storage.objects;
CREATE POLICY "pet_photos_storage_update_own"
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'pet-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
    AND (storage.foldername(name))[2] IS NOT NULL
  )
  WITH CHECK (
    bucket_id = 'pet-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
    AND (storage.foldername(name))[2] IS NOT NULL
  );

DROP POLICY IF EXISTS "pet_photos_storage_delete_own" ON storage.objects;
CREATE POLICY "pet_photos_storage_delete_own"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'pet-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
    AND (storage.foldername(name))[2] IS NOT NULL
  );