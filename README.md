# App Mascotas

Plataforma comunitaria en Flutter para reportar y encontrar mascotas perdidas.

## Ejecutar en desarrollo

La app usa variables de entorno de Dart para inicializar Supabase. Crea un
archivo `.env` en la raiz del proyecto con:

```env
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_ANON_KEY=tu_anon_key
```

Ejecuta la app pasando ese archivo a Flutter:

```bash
flutter run --dart-define-from-file=.env
```

Si corres desde Android Studio o IntelliJ, agrega este argumento en la
configuracion de ejecucion:

```text
--dart-define-from-file=.env
```

Sin esas variables, el selector de Google puede abrirse, pero Supabase no puede
completar el inicio de sesion.
