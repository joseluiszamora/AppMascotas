# App Mascotas — Instrucciones para agentes IA

Plataforma móvil comunitaria para reportar y encontrar mascotas perdidas. Stack: **Flutter + Supabase + BLoC/Cubit + Clean Architecture**.

> El proyecto está actualmente en fase MVP (Etapa 1). Ver alcance en [docs/notion/funcionalidades-mvp.md](docs/notion/funcionalidades-mvp.md).

---

## Documentación funcional (leer antes de implementar)

| Archivo                                                                      | Contenido                                  |
| ---------------------------------------------------------------------------- | ------------------------------------------ |
| [docs/notion/proyecto-app-mascotas.md](docs/notion/proyecto-app-mascotas.md) | Descripción general y etapas del proyecto  |
| [docs/notion/funcionalidades-mvp.md](docs/notion/funcionalidades-mvp.md)     | Funcionalidades incluidas en MVP (Etapa 1) |
| [docs/notion/pantallas.md](docs/notion/pantallas.md)                         | Pantallas requeridas y sus componentes     |
| [docs/notion/reglas-negocio.md](docs/notion/reglas-negocio.md)               | Reglas de negocio por módulo               |
| [docs/notion/backlog.md](docs/notion/backlog.md)                             | Backlog priorizado                         |

---

## Arquitectura Flutter

```
lib/
  features/           # Un directorio por módulo/feature
    auth/
      data/           # Fuentes de datos, modelos, repositorios impl.
      domain/         # Entidades, casos de uso, interfaces repo
      presentation/   # BLoC/Cubit, páginas, widgets
    pets/
    reports/
    map/
    notifications/
  core/               # Shared: theme, router, constants, utils
  main.dart
supabase/
  migrations/         # Migraciones SQL numeradas
  functions/          # Edge Functions (Deno/TypeScript)
```

### Patrón de capas

```
Vista (Widget) → BLoC (Lógica) → Repository → Provider → API (Supabase/Dio)
```

- **Widget**: Solo UI. Consume estados del BLoC con `BlocBuilder` / `BlocListener`.
- **BLoC**: Maneja eventos y emite estados. Usar `Equatable` para comparación de estados.
- **Repository**: Orquesta llamadas a uno o más providers.
- **Provider**: Realiza llamadas a Supabase o almacenamiento local.
- **Model**: Clases de datos inmutables.

- Separar estrictamente `data / domain / presentation`.
- Widgets reutilizables van en `core/widgets/` o `core/components/`.
- **No poner lógica crítica de seguridad en el cliente.**

### Estructura de un feature (ejemplo: `pets`)

```
features/pets/
  presentation/
    pages/
      pets_page.dart              # Entry point
    screens/                      # Sub-pantallas
      new_pet.dart
    components/                   # Widgets específicos del feature
      pet_card.dart
    blocs/
      pet_form/
        pet_form_bloc.dart
        pet_form_event.dart
        pet_form_state.dart
```

### Convenciones de nombrado

| Elemento          | Convención             | Ejemplo                  |
| ----------------- | ---------------------- | ------------------------ |
| Archivos          | `snake_case.dart`      | `user_profile_page.dart` |
| Clases            | `PascalCase`           | `UserProfilePage`        |
| Variables/Métodos | `camelCase`            | `onLoginHandler`         |
| Constantes        | `camelCase` (estático) | `AppColors.primary`      |
| BLoC Events       | `PascalCase`           | `LoginSubmitted`         |
| BLoC States       | `PascalCase`           | `AuthenticationState`    |
| Privados          | Prefijo `_`            | `_buildSectionTitle()`   |

### Reglas de estilo

1. **Widgets auxiliares como métodos privados** (`_buildXxx()`), no como clases separadas, salvo que sean reutilizables.
2. Preferir `StatelessWidget` salvo que se necesite estado local o animaciones.
3. Usar `const` en constructores y widgets estáticos siempre que sea posible.
4. Usar `required` named parameters en constructores de widgets.
5. Usar trailing commas para facilitar el formato de Dart.
6. Composición sobre herencia.

### Al manejar errores

1. Capturar `DioException` y `catch` genérico por separado.
2. Usar `switch (e.type)` para diferenciar tipos de error Dio.
3. Emitir estados de error descriptivos en español, amigables y orientados al usuario.

### Al registrar BLoCs

- BLoCs globales → registrar en `service_locator.dart`.
- BLoCs locales → proveer con `BlocProvider` en la página correspondiente.

### Qué NO hacer

- **No** usar `setState` para lógica de negocio; usar BLoC.
- **No** hacer llamadas HTTP/Supabase directamente desde widgets.
- **No** hardcodear colores, tamaños ni textos.
- **No** crear archivos fuera de la estructura de carpetas definida.
- **No** usar `print()` en producción; usar `debugPrint()` solo para debugging.

---

## Base de datos (Supabase)

- Todo cambio estructural → migración en `supabase/migrations/`.
- Toda tabla pública → **RLS habilitado**.
- PK: UUID. Columnas obligatorias: `created_at`, `updated_at`.
- Toda FK importante → índice.
- Nunca modificar la DB directamente desde el dashboard.

Comandos frecuentes:

```bash
supabase migration new <nombre>
supabase db reset
supabase db push
supabase gen types typescript --local > lib/core/supabase_types.dart
```

Ver guía completa en [docs/agents/supabase-database.md](docs/agents/supabase-database.md).

---

## Diseño UI/UX

Antes de crear pantallas, componentes o layouts → revisar [docs/design/ui-ux-design-system.md](docs/design/ui-ux-design-system.md).

Principios obligatorios: colores pastel · componentes redondeados · sombras suaves · mucho espacio visual · estilo iOS moderno / startup premium.

Tokens visuales en: [colors.md](docs/design/colors.md) · [typography.md](docs/design/typography.md) · [spacing.md](docs/design/spacing.md) · [components.md](docs/design/components.md).

---

## Reglas generales

- Trabajar por módulos; no mezclar features en un mismo PR/tarea.
- No modificar producción directamente.
- Todo cambio importante debe actualizar la documentación correspondiente.
- Revisar estructura existente antes de crear archivos nuevos.
- Revisar errores, tipos y consistencia después de implementar.
- No crear dependencias innecesarias.

---

## Seguridad

- Secretos y claves → variables de entorno, nunca en el frontend.
- No saltarse RLS sin justificación documentada.
- El teléfono del usuario es privado por defecto (mostrar solo si el usuario lo autoriza).
- La ubicación exacta de reportes debe proteger la privacidad del usuario.

---

## Agentes especializados

| Agente                   | Archivo                                                                        |
| ------------------------ | ------------------------------------------------------------------------------ |
| Product Manager          | [docs/agents/product-manager.md](docs/agents/product-manager.md)               |
| UX/UI                    | [docs/agents/ux-ui.md](docs/agents/ux-ui.md)                                   |
| Supabase Database        | [docs/agents/supabase-database.md](docs/agents/supabase-database.md)           |
| Backend / Edge Functions | [docs/agents/backend-edge-functions.md](docs/agents/backend-edge-functions.md) |
| Flutter Frontend         | [docs/agents/flutter-frontend.md](docs/agents/flutter-frontend.md)             |
| AI Matching              | [docs/agents/ai-matching.md](docs/agents/ai-matching.md)                       |
| Notifications            | [docs/agents/notifications.md](docs/agents/notifications.md)                   |
| QA / Testing             | [docs/agents/qa-testing.md](docs/agents/qa-testing.md)                         |
| Security & RLS           | [docs/agents/security-rls.md](docs/agents/security-rls.md)                     |
| Documentation            | [docs/agents/documentation.md](docs/agents/documentation.md)                   |
| Release / DevOps         | [docs/agents/release-devops.md](docs/agents/release-devops.md)                 |
