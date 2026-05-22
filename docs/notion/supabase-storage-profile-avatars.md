# Storage de avatares de perfil

La app espera un bucket de Supabase Storage llamado profile-avatars.

## Qué hace la migración

- Crea o actualiza el bucket profile-avatars como público.
- Limita tipos MIME permitidos a imágenes comunes.
- Crea políticas sobre storage.objects para que cada usuario solo pueda subir, actualizar o eliminar archivos dentro de su propia carpeta.

## Estructura esperada de archivos

Cada avatar se guarda con esta ruta:

- user_id/timestamp.extension

Ejemplo:

- 2f8c.../1747935512345.jpg

## Cómo aplicar

1. Ejecutar supabase db push.
2. Si trabajas en local y quieres reconstruir todo desde cero, usar supabase db reset.
3. Verificar en Supabase que exista el bucket profile-avatars.

## Verificaciones manuales

1. Ir a editar perfil desde la app.
2. Seleccionar una foto jpg, png o webp.
3. Guardar cambios.
4. Confirmar que se actualiza public.profiles.avatar_url.
5. Confirmar que el archivo aparece en Storage dentro de la carpeta user_id.
6. Cambiar la foto por otra para validar reemplazo y limpieza del archivo anterior.
7. Quitar la foto para validar la política de borrado.

## Nota de implementación

El cliente Flutter usa getPublicUrl(), por eso el bucket está configurado como público.
