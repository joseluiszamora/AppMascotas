# App Mascotas - Instrucciones para Codex

Este proyecto es una app para mascotas usando Flutter, Supabase, IA, Notion y Git.

## Documentación funcional

Antes de implementar cualquier funcionalidad, revisar:

- docs/notion/proyecto-app-mascotas.md
- docs/notion/funcionalidades-mvp.md
- docs/notion/pantallas.md
- docs/notion/reglas-negocio.md
- docs/notion/backlog.md

Estos archivos son la fuente funcional del proyecto.

## Reglas generales

- Trabajar por modulos.
- No modificar produccion directamente.
- Todo cambio de base de datos debe ir en migraciones de Supabase.
- Toda tabla publica debe tener RLS.
- Todo cambio importante debe actualizar documentacion.
- Antes de implementar, revisar la estructura existente del proyecto.
- Despues de implementar, revisar errores, tipos y consistencia.
- No crear dependencias innecesarias.
- Mantener arquitectura limpia y codigo mantenible.

# Diseño UI/UX

Antes de generar pantallas, componentes o layouts,
Codex debe revisar:

- docs/design/ui-ux-design-system.md

La aplicación debe seguir estrictamente:

- estética premium
- colores pastel
- componentes redondeados
- sombras suaves
- mucho espacio visual
- estilo iOS moderno
- diseño tipo startup premium

## Agentes disponibles

- Product Manager Agent: [docs/agents/product-manager.md](docs/agents/product-manager.md)
- UX/UI Agent: [docs/agents/ux-ui.md](docs/agents/ux-ui.md)
- Supabase Database Agent: [docs/agents/supabase-database.md](docs/agents/supabase-database.md)
- Backend / Edge Functions Agent: [docs/agents/backend-edge-functions.md](docs/agents/backend-edge-functions.md)
- Flutter Frontend Agent: [docs/agents/flutter-frontend.md](docs/agents/flutter-frontend.md)
- AI Matching Agent: [docs/agents/ai-matching.md](docs/agents/ai-matching.md)
- Notifications Agent: [docs/agents/notifications.md](docs/agents/notifications.md)
- QA / Testing Agent: [docs/agents/qa-testing.md](docs/agents/qa-testing.md)
- Security & RLS Agent: [docs/agents/security-rls.md](docs/agents/security-rls.md)
- Documentation Agent: [docs/agents/documentation.md](docs/agents/documentation.md)
- Release / DevOps Agent: [docs/agents/release-devops.md](docs/agents/release-devops.md)
