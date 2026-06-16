# Publicacion de App Mascotas en Google Play Store

Guia operativa para publicar la app Android (Flutter) en Google Play.

## 1. Prerrequisitos

- Cuenta de desarrollador de Google Play activa.
- Acceso a Play Console del proyecto.
- JDK 17 y Android SDK instalados.
- Flutter instalado y funcional.
- Keystore de release seguro (no perderlo).
- Politica de privacidad publicada en una URL publica.

## 2. Datos actuales del proyecto (verificados)

- Nombre app (Android label): Mis mascotas.
- Application ID: com.jzamoradev.pets_app_mobile.
- Version actual en Flutter: 1.0.0+2.
- Build Android release firmado con signingConfig release en android/app/build.gradle.kts.
- Google Services habilitado (plugin com.google.gms.google-services).

## 3. Seguridad antes de publicar (obligatorio)

1. Validar que el keystore y credenciales no esten expuestos en git.
2. Agregar a .gitignore (si aun no esta):

```gitignore
android/key.properties
*.jks
*.keystore
```

3. Guardar copia del keystore y credenciales en un gestor seguro (1Password, Vault, etc.).
4. Si las credenciales ya estuvieron expuestas, rotarlas antes de publicar.

## 4. Configurar version para release

Editar pubspec.yaml:

```yaml
version: 1.0.1+3
```

Reglas:

- build-name = versionName (ejemplo 1.0.1)
- build-number = versionCode (ejemplo 3)
- versionCode siempre debe incrementar en cada release.

## 5. Variables de entorno para produccion

La app usa dart-define para Supabase.

1. Crear archivo de produccion (ejemplo .env.prod):

```env
SUPABASE_URL=https://TU-PROYECTO.supabase.co
SUPABASE_ANON_KEY=TU_ANON_KEY
```

2. No subir este archivo si contiene secretos.
3. Verificar que la URL de Supabase sea de produccion.

## 6. Compilar Android App Bundle (AAB)

Desde la raiz del proyecto:

```bash
flutter clean
flutter pub get
flutter build appbundle --release --dart-define-from-file=.env.prod
```

Salida esperada:

- build/app/outputs/bundle/release/app-release.aab

## 7. Verificaciones tecnicas previas

1. Instalar y probar build release localmente:

```bash
flutter build apk --release --dart-define-from-file=.env.prod
```

2. Probar flujo minimo MVP:

- Inicio de sesion (incluyendo Google).
- Crear reporte de mascota perdida.
- Subir imagen.
- Mapa y geolocalizacion.
- Notificaciones principales del MVP.

3. Confirmar que permisos declarados coincidan con uso real:

- INTERNET
- ACCESS_COARSE_LOCATION
- ACCESS_FINE_LOCATION

4. Revisar textos de permisos y privacidad en la app y en Play Console.

## 8. Preparar ficha en Play Console

En Google Play Console, crear la app y completar:

1. Configuracion principal:

- Nombre de la app.
- Idioma principal.
- Categoria (Social/Comunidad, o la que corresponda).

2. Store Listing:

- Titulo corto y descripcion corta.
- Descripcion completa.
- Icono 512x512.
- Feature graphic 1024x500.
- Minimo 2 capturas de pantalla de telefono.

3. Politicas y formularios:

- Politica de privacidad (URL).
- Data safety (declarar recoleccion/uso de datos).
- Clasificacion de contenido (cuestionario).
- App access (si se requiere login, proveer acceso de prueba).

4. Ads:

- Declarar si muestra anuncios o no.

## 9. Crear release en testing (recomendado)

1. Ir a Testing > Internal testing (o Closed testing).
2. Crear release y subir app-release.aab.
3. Completar notas de version.
4. Agregar testers.
5. Publicar en el track de testing y validar:

- Instalacion desde Play.
- Upgrade desde version anterior.
- Login, reportes, mapas, fotos.

Nota: algunos tipos de cuenta nueva requieren pruebas cerradas previas antes de produccion. Validar requisito vigente en Play Console.

## 10. Publicar a produccion

1. Ir a Production > Create new release.
2. Usar App Signing de Google Play (recomendado).
3. Subir AAB aprobado en testing.
4. Completar release notes.
5. Revisar warnings de policy/compliance.
6. Enviar a revision.

## 11. Post-publicacion

1. Monitorear Android vitals (crashes, ANR).
2. Revisar feedback y rating inicial.
3. Validar logs de autenticacion y errores de Supabase.
4. Planificar hotfix si aparecen errores criticos.

## 12. Checklist rapido de salida

- [ ] versionCode incrementado.
- [ ] build AAB firmado correctamente.
- [ ] Politica de privacidad publicada y enlazada.
- [ ] Data safety completado.
- [ ] Ficha de tienda completa (textos + imagenes).
- [ ] Pruebas en Internal/Closed testing ok.
- [ ] Notas de version redactadas.
- [ ] Release enviado a revision.

## Comandos utiles

```bash
# Generar firma SHA1/SHA256 de la key de subida
keytool -list -v -keystore /ruta/a/tu/upload-key.jks -alias tu_alias

# Build AAB release
flutter build appbundle --release --dart-define-from-file=.env.prod

# Build APK release (prueba local)
flutter build apk --release --dart-define-from-file=.env.prod
```

---

Sugerencia operativa: crear un workflow de CI (GitHub Actions) para construir el AAB en cada tag de release y estandarizar el proceso de publicacion.
