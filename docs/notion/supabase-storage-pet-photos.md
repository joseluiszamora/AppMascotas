# Storage de fotos de mascotas

La app espera un bucket de Supabase Storage llamado pet-photos.

## Qué hace la migración

- Crea o actualiza el bucket pet-photos como público.
- Limita tipos MIME permitidos a imágenes comunes.
- Crea políticas sobre storage.objects para que cada usuario solo pueda subir, actualizar o eliminar archivos dentro de su propia carpeta y para mascotas que le pertenecen.

## Estructura esperada de archivos

Cada imagen se guarda con esta ruta:

- user_id/pet_id/timestamp.extension

Ejemplo:

- 2f8c.../f6ab.../1747921012345.jpg

## Cómo aplicar

1. Ejecutar supabase db push.
2. Si trabajas en local y quieres reconstruir todo desde cero, usar supabase db reset.
3. Verificar en Supabase que exista el bucket pet-photos.

## Verificaciones manuales

1. Crear una mascota nueva desde la app.
2. Adjuntar una foto jpg, png o webp.
3. Confirmar que se inserta un registro en public.pet_photos.
4. Confirmar que el archivo aparece en Storage dentro de la carpeta user_id/pet_id.
5. Editar la mascota y subir otra foto para validar la política de inserción.
6. Eliminar una foto para validar la política de borrado.

## Nota de implementación

El cliente Flutter usa getPublicUrl(), por eso el bucket está configurado como público.
