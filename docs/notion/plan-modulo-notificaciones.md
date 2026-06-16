# Plan para avanzar el modulo de notificaciones

## Objetivo

Evolucionar el modulo de notificaciones para que la app pueda avisar a usuarios especificos cuando ocurra un evento relevante, como un reporte generado, una mascota encontrada, una actualizacion de caso o una futura coincidencia. El sistema debe permitir segmentar destinatarios por ubicacion geografica, tipo de mascota, preferencias del usuario y reglas anti-spam.

El primer alcance debe mantener el MVP simple y seguro: notificaciones internas dentro de la app, generadas desde backend/Supabase, con historial por usuario y sin depender de que Flutter replique reglas criticas. La arquitectura debe quedar preparada para agregar push notifications y email en una fase posterior.

## Estado actual

Ya existe una base inicial:

- Tabla `public.notifications`.
- RLS para que cada usuario vea y marque sus propias notificaciones.
- Trigger `public.create_report_notifications()` al insertar reportes.
- Preferencias en `profiles`:
  - `notifications_enabled`.
  - `notification_radius_km`.
  - `notification_types`.
  - `pet_preferences`.
- Feature Flutter `notifications` con:
  - Provider.
  - Repository.
  - Use cases.
  - Cubit.
  - Pantalla de listado.

Limitaciones actuales:

- La segmentacion geografica todavia no calcula distancia real.
- No existe tabla para tokens de dispositivo.
- Solo se contemplan dos tipos: `nearby_lost_report` y `nearby_found_report`.
- No hay modelo explicito de eventos.
- No hay canal push/email.
- No hay control avanzado de frecuencia o silenciamiento.
- La generacion de notificaciones vive como trigger directo sobre `reports`, lo cual sirve para MVP, pero puede crecer con dificultad si se agregan mas eventos.

## Principios de implementacion

1. La logica de seleccion de destinatarios debe vivir en backend/Supabase, no en Flutter.
2. Flutter solo debe registrar preferencias, mostrar historial, marcar leidas y abrir el detalle relacionado.
3. Toda notificacion debe tener un evento disparador, destinatarios, canal, mensaje y condiciones.
4. No se debe notificar sin consentimiento del usuario.
5. No se deben incluir datos personales innecesarios en el mensaje.
6. El sistema debe evitar duplicados por usuario, evento y tipo.
7. La ubicacion usada para alertas debe ser aproximada y respetar privacidad.
8. El MVP debe priorizar notificaciones internas; push se agrega como canal adicional sin romper el modelo.
9. Las notificaciones comerciales deben estar separadas de las alertas comunitarias y requerir consentimiento explicito.

## Eventos a soportar

### Fase MVP ampliado

| Evento | Disparador | Destinatarios | Canal inicial | Condiciones |
| --- | --- | --- | --- | --- |
| Reporte perdido generado | `INSERT reports` con `type = 'lost'` | Usuarios cercanos con preferencias compatibles | Interno | Usuario con notificaciones activas, radio compatible, tipo de mascota compatible, no es el reportante |
| Reporte encontrado generado | `INSERT reports` con `type = 'found'` | Usuarios cercanos con preferencias compatibles | Interno | Usuario con notificaciones activas, radio compatible, tipo de mascota compatible, no es el reportante |
| Mascota encontrada / caso resuelto | `UPDATE reports.status` a `resolved` | Reportante, usuarios que recibieron alerta previa, usuarios relacionados por avistamientos | Interno | Evitar avisar al actor si fue quien resolvio |
| Nuevo avistamiento | `INSERT report_sightings` | Creador del reporte original | Interno | No notificar si el avistamiento lo creo el mismo reportante |

### Fase posterior

| Evento | Disparador | Destinatarios | Canal | Condiciones |
| --- | --- | --- | --- | --- |
| Coincidencia por IA | Funcion de matching en Etapa 2 | Dueno/reporter del caso compatible | Interno + push opcional | Score minimo, revision de umbral, anti-spam |
| Contacto recibido | Mensaje/contacto futuro | Usuario contactado | Interno + push opcional | Solo si el canal de contacto esta habilitado |
| Reporte cerca de zona guardada | Insercion de reporte | Usuarios con zonas guardadas | Interno + push opcional | Zona activa y radio compatible |
| Oferta comercial relevante | Campana creada por negocio/admin | Usuarios que aceptaron promociones y coinciden con la segmentacion | Interno + push/email opcional | Consentimiento comercial activo, frecuencia limitada, segmento compatible |
| Promocion por ubicacion | Campana geolocalizada | Usuarios cercanos a veterinaria/tienda/servicio | Interno + push opcional | Consentimiento comercial activo, radio de campana compatible, horario permitido |
| Beneficio para recuperacion de mascota | Campana asociada a reportes activos | Usuarios con reportes activos o recientes | Interno + email opcional | No debe interferir con alertas urgentes ni exponer datos sensibles |

## Modelo de segmentacion

La segmentacion debe combinar filtros obligatorios y filtros opcionales.

### Filtros obligatorios

- Usuario autenticado con perfil existente.
- `profiles.notifications_enabled = true`.
- Usuario distinto al actor del evento.
- Tipo de evento habilitado en `profiles.notification_types`.
- Notificacion no duplicada para el mismo `user_id`, `event_id`/`report_id` y `type`.

### Filtros por tipo de mascota

Usar `profiles.pet_preferences`:

- `both`: recibe perros y gatos; evaluar si tambien debe recibir `other` o si conviene crear `all`.
- `dogs`: solo `dog`.
- `cats`: solo `cat`.
- `others`: solo `other`.

Recomendacion: migrar en una fase posterior a un arreglo o JSONB mas flexible, por ejemplo `preferred_pet_types: ['dog', 'cat', 'other']`, porque el valor `both` no representa bien mascotas de tipo `other`.

### Filtros por ubicacion geografica

Para MVP se puede empezar con calculo SQL usando latitud/longitud y formula Haversine. Luego, si el volumen crece, migrar a PostGIS.

Datos necesarios:

- Latitud/longitud aproximada del evento, ya disponible en `reports`.
- Ubicacion preferida del usuario para alertas, que actualmente no existe.
- Radio de notificacion del usuario, ya disponible como `profiles.notification_radius_km`.

Opciones para ubicacion del usuario:

1. Agregar a `profiles` campos `notification_latitude`, `notification_longitude` y `notification_location_description`.
2. Crear tabla `notification_zones` para permitir multiples zonas por usuario.

Recomendacion para MVP: usar campos en `profiles` para una zona principal. Recomendacion para Etapa 2: migrar a `notification_zones`.

### Filtros por estado del reporte

Solo deben disparar alertas masivas los reportes que se encuentren en estados visibles:

- `active`.
- `under_review`, si se decide que aun debe alertar.

No disparar alertas nuevas para:

- `resolved`.
- `closed`.
- `reported`, salvo que sea una notificacion interna de moderacion futura.

### Filtros comerciales

Las notificaciones comerciales deben usar un flujo separado de consentimiento y segmentacion. No deben enviarse solo porque el usuario activo alertas comunitarias.

Filtros sugeridos:

- `profiles.marketing_notifications_enabled = true`.
- Segmentos de interes seleccionados por el usuario, por ejemplo:
  - Veterinarias.
  - Alimento.
  - Peluqueria.
  - Accesorios.
  - Emergencias.
  - Adopcion o bienestar.
- Tipo de mascota compatible con la oferta.
- Ubicacion compatible con la cobertura del negocio o campana.
- Frecuencia maxima por usuario.
- Horarios permitidos.
- Campana activa, aprobada y no expirada.

Regla importante: las preferencias de alertas de mascotas perdidas no deben mezclarse automaticamente con preferencias comerciales. El usuario puede querer recibir alertas comunitarias sin recibir promociones.

## Cambios de base de datos propuestos

### 1. Ampliar `notifications`

Agregar campos que permitan soportar mas eventos y canales:

- `event_key TEXT`: identificador estable del evento.
- `channel TEXT`: `in_app`, `push`, `email`.
- `entity_type TEXT`: `report`, `pet`, `sighting`, `match`.
- `entity_id UUID`: id principal relacionado.
- `metadata JSONB`: informacion no sensible para renderizar acciones.
- `delivered_at TIMESTAMPTZ`.
- `failed_at TIMESTAMPTZ`.
- `failure_reason TEXT`.

Mantener `report_id` mientras el MVP depende de reportes, pero preparar el modelo para entidades futuras. Si se usa `entity_type/entity_id`, `report_id` puede quedar nullable o reemplazarse en una migracion controlada.

### 2. Agregar ubicacion de alertas al perfil

Campos sugeridos:

- `notification_latitude DECIMAL(10,7)`.
- `notification_longitude DECIMAL(10,7)`.
- `notification_location_description TEXT`.

Regla: si el usuario no configura una ubicacion de alertas, no debe recibir alertas segmentadas por distancia, salvo que exista una decision explicita de usar su ultima ubicacion autorizada.

### 3. Crear tabla de eventos de notificacion

Tabla propuesta: `notification_events`.

Campos:

- `id UUID PRIMARY KEY`.
- `event_key TEXT UNIQUE`.
- `type TEXT`.
- `actor_id UUID`.
- `entity_type TEXT`.
- `entity_id UUID`.
- `latitude DECIMAL(10,7)`.
- `longitude DECIMAL(10,7)`.
- `pet_type TEXT`.
- `payload JSONB`.
- `created_at TIMESTAMPTZ`.
- `processed_at TIMESTAMPTZ`.

Beneficio: desacopla "ocurrio algo" de "a quienes notifico". Tambien permite reprocesar, auditar y depurar.

Para MVP se puede mantener trigger directo y pasar luego a eventos. Si se implementa ahora, conviene que los triggers solo creen eventos y una funcion `process_notification_event(event_id)` genere notificaciones.

### 4. Crear tabla para tokens push en fase posterior

Tabla propuesta: `device_tokens`.

Campos:

- `id UUID PRIMARY KEY`.
- `user_id UUID REFERENCES profiles(id)`.
- `platform TEXT`: `ios`, `android`, `web`.
- `token TEXT UNIQUE`.
- `provider TEXT`: `fcm`, `apns`, `expo`.
- `enabled BOOLEAN`.
- `last_seen_at TIMESTAMPTZ`.
- `created_at TIMESTAMPTZ`.
- `updated_at TIMESTAMPTZ`.

RLS:

- El usuario solo puede ver, insertar, actualizar o desactivar sus propios tokens.

### 5. Agregar consentimiento y preferencias comerciales

Campos sugeridos en `profiles`:

- `marketing_notifications_enabled BOOLEAN NOT NULL DEFAULT FALSE`.
- `marketing_categories JSONB NOT NULL DEFAULT '{}'::jsonb`.
- `marketing_quiet_hours JSONB`.
- `marketing_last_opt_in_at TIMESTAMPTZ`.
- `marketing_last_opt_out_at TIMESTAMPTZ`.

El valor por defecto debe ser `false`. El usuario debe activar explicitamente las promociones.

### 6. Crear estructura para campanas comerciales

Tabla propuesta: `commercial_campaigns`.

Campos:

- `id UUID PRIMARY KEY`.
- `business_id UUID` o referencia futura a negocio/partner.
- `title TEXT`.
- `body TEXT`.
- `category TEXT`.
- `pet_types JSONB`.
- `latitude DECIMAL(10,7)`.
- `longitude DECIMAL(10,7)`.
- `radius_km INTEGER`.
- `starts_at TIMESTAMPTZ`.
- `ends_at TIMESTAMPTZ`.
- `status TEXT`: `draft`, `pending_review`, `approved`, `active`, `paused`, `ended`, `rejected`.
- `metadata JSONB`.
- `created_at TIMESTAMPTZ`.
- `updated_at TIMESTAMPTZ`.

Tabla propuesta: `commercial_campaign_deliveries`.

Campos:

- `id UUID PRIMARY KEY`.
- `campaign_id UUID REFERENCES commercial_campaigns(id)`.
- `user_id UUID REFERENCES profiles(id)`.
- `notification_id UUID REFERENCES notifications(id)`.
- `channel TEXT`.
- `status TEXT`: `queued`, `sent`, `failed`, `skipped`.
- `reason TEXT`.
- `created_at TIMESTAMPTZ`.
- `sent_at TIMESTAMPTZ`.

Beneficio: permite auditar a quien se le envio una promocion, evitar duplicados y medir resultados sin contaminar la tabla principal de eventos comunitarios.

## Backend Supabase

### Fase 1: Notificaciones internas robustas

1. Crear migracion para nuevos tipos de notificacion.
2. Agregar funcion SQL `distance_km(lat1, lon1, lat2, lon2)`.
3. Actualizar funcion de generacion de notificaciones para:
   - Filtrar por radio geografico.
   - Filtrar por preferencias de mascota.
   - Filtrar por tipos habilitados.
   - Evitar duplicados.
   - Guardar metadata minima.
4. Crear trigger para `report_sightings`.
5. Crear trigger para cambio de estado a `resolved`.

### Fase 2: Eventos desacoplados

1. Crear `notification_events`.
2. Cambiar triggers para insertar eventos.
3. Crear funcion `process_notification_event`.
4. Agregar logs de procesamiento.
5. Preparar una Edge Function para procesar eventos si se necesita control externo.

### Fase 3: Push notifications

1. Elegir proveedor:
   - Firebase Cloud Messaging para Android.
   - APNs via FCM para iOS, si se unifica con Firebase.
2. Agregar registro de tokens desde Flutter.
3. Crear Edge Function `send-push-notification`.
4. Procesar notificaciones pendientes con estado `channel = 'push'`.
5. Registrar `delivered_at` o `failed_at`.

### Fase 4: Notificaciones comerciales

1. Agregar consentimiento comercial en perfil.
2. Crear estructura de campanas comerciales.
3. Crear flujo de aprobacion de campanas antes de enviarlas.
4. Crear funcion `process_commercial_campaign(campaign_id)` para segmentar usuarios.
5. Generar notificaciones internas con tipo comercial.
6. Agregar limites de frecuencia por usuario y categoria.
7. Agregar metricas basicas:
   - Entregadas.
   - Leidas.
   - Clicks/aperturas.
   - Cancelaciones de suscripcion.
8. Preparar push/email solo para usuarios que aceptaron esos canales.

## Cambios Flutter propuestos

### Domain

Ampliar `AppNotificationType`:

- `nearbyLostReport`.
- `nearbyFoundReport`.
- `reportResolved`.
- `newSighting`.
- `possibleMatch` para Etapa 2.
- `contactReceived` para Etapa 2.
- `commercialOffer` para promociones futuras.
- `commercialReminder` para recordatorios comerciales no urgentes.

Actualizar `AppNotificationEntity` con campos opcionales:

- `entityType`.
- `entityId`.
- `metadata`.
- `channel`.

### Data

Actualizar `AppNotificationModel.fromJson` para mapear nuevos tipos y campos.

Actualizar `NotificationProvider`:

- Mantener `getMyNotifications`.
- Mantener `getUnreadCount`.
- Agregar paginacion en una fase posterior.
- Agregar `markAllAsRead` si se requiere UX.

### Presentation

Actualizar `NotificationsPage`:

- Mostrar icono y color segun tipo.
- Abrir la pantalla relacionada:
  - Reporte: detalle de reporte.
  - Avistamiento: detalle de reporte.
  - Caso resuelto: detalle de reporte.
  - Coincidencia futura: pantalla de coincidencias.
- Mantener soporte light/dark usando `context.appColors`.

Actualizar perfil/configuracion:

- Permitir activar/desactivar notificaciones.
- Permitir seleccionar tipos: perdidas, encontradas, actualizaciones.
- Permitir seleccionar radio.
- Permitir configurar ubicacion base de alertas.
- En una fase posterior, permitir activar/desactivar promociones por separado.
- En una fase posterior, permitir seleccionar categorias comerciales.

### Push posterior

Agregar servicio local:

- Solicitar permisos de notificacion.
- Registrar token.
- Renovar token cuando cambie.
- Desactivar token al cerrar sesion.

## Seguridad y privacidad

1. No incluir telefono, email o direccion exacta en el cuerpo de una notificacion.
2. Usar solo descripcion general de zona.
3. No notificar al usuario que genero el evento.
4. No exponer tokens de dispositivo.
5. Mantener RLS estricta en `notifications`, `notification_events` y `device_tokens`.
6. Evitar que el cliente pueda crear notificaciones arbitrarias para otros usuarios.
7. Los triggers o Edge Functions deben operar con `SECURITY DEFINER` solo cuando sea necesario y con `search_path` fijo.
8. Las promociones deben requerir opt-in explicito y permitir opt-out simple.
9. Las campanas comerciales deben ser aprobadas antes de enviarse a usuarios.
10. No usar datos sensibles, reportes privados o telefono del usuario para segmentacion comercial.
11. Separar metricas comerciales de datos personales identificables siempre que sea posible.

## Anti-spam y duplicados

Reglas iniciales:

- Una notificacion por usuario, tipo y entidad.
- No reenviar alerta de reporte si ya existe una notificacion para ese reporte.
- Para actualizaciones de caso, usar tipos distintos para que no choquen con alerta inicial.
- No enviar alertas masivas para reportes cerrados o resueltos.

Reglas futuras:

- Limite por usuario por hora.
- Modo silencio por horario.
- Agrupacion diaria para eventos de baja prioridad.
- Prioridad alta solo para mascotas perdidas cercanas.
- Limite independiente para promociones, por ejemplo maximo 1 promocion diaria y 3 semanales por usuario.
- En promociones, evitar reintentos agresivos si falla push/email.
- Cancelar campanas expiradas antes de procesarlas.
- No mezclar promociones en agrupaciones de alertas urgentes.

## Priorizacion de notificaciones

Se recomienda clasificar las notificaciones por prioridad:

- `critical`: mascota perdida cercana, actualizacion importante de caso.
- `high`: nuevo avistamiento o posible coincidencia.
- `normal`: reportes encontrados, recordatorios utiles.
- `low`: promociones, ofertas comerciales, contenido editorial.

Reglas:

- Las notificaciones `critical` y `high` tienen preferencia visual y de envio.
- Las promociones deben usar prioridad `low`.
- Una promocion nunca debe desplazar o ocultar una alerta de mascota perdida.
- En la UI se puede separar "Alertas" y "Promociones" cuando el volumen comercial exista.

## Orden recomendado de implementacion

### Paso 1: Definir alcance del MVP de notificaciones

Decidir si en esta iteracion se implementa solo notificacion interna o tambien push. Recomendacion: primero interna robusta.

Entregables:

- Tipos de notificacion definitivos para MVP.
- Reglas de segmentacion validadas.
- Campos de perfil necesarios para ubicacion de alertas.

### Paso 2: Migraciones de Supabase

Crear una migracion para:

- Ampliar tipos permitidos en `notifications`.
- Agregar metadata/canal si se decide hacerlo ya.
- Agregar ubicacion base de alertas en `profiles`.
- Crear funcion de distancia.
- Actualizar trigger de reportes.
- Agregar triggers para avistamientos y resolucion.

### Paso 3: Actualizar dominio Flutter

Actualizar entidad/modelo/tipos para soportar los nuevos eventos sin cambiar aun la UI profundamente.

### Paso 4: Actualizar UI de notificaciones

Agregar renderizado por tipo y navegacion correcta al tocar cada notificacion.

### Paso 5: Configuracion de preferencias

Extender Profile Page para permitir:

- Activar/desactivar notificaciones.
- Elegir tipos de alerta.
- Ajustar radio.
- Definir ubicacion de alerta.

Para promociones, dejar preparado el modelo pero no mezclarlo con esta pantalla hasta que exista el modulo comercial. Cuando se implemente, agregar:

- Activar/desactivar promociones.
- Seleccionar categorias comerciales.
- Configurar horarios silenciosos.
- Ver politica breve de uso de datos para promociones.

### Paso 6: Pruebas

Pruebas necesarias:

- Crear reporte perdido y verificar destinatarios.
- Crear reporte encontrado y verificar destinatarios.
- Validar que el reportante no reciba su propia alerta.
- Validar que usuarios fuera del radio no reciban alerta.
- Validar que usuarios con tipo de mascota no compatible no reciban alerta.
- Validar que `notifications_enabled = false` no reciba alerta.
- Validar que no se creen duplicados.
- Marcar notificacion como leida desde Flutter.
- Abrir detalle desde notificacion.

## Criterios de aceptacion

1. Al crear un reporte perdido, se crean notificaciones solo para usuarios compatibles.
2. Al crear un reporte encontrado, se crean notificaciones solo para usuarios compatibles.
3. La compatibilidad considera al menos:
   - Tipo de mascota.
   - Radio geografico.
   - Preferencias de tipos de alerta.
   - Notificaciones activadas.
4. El usuario creador del evento no recibe notificacion propia.
5. No se generan notificaciones duplicadas.
6. Las notificaciones aparecen en la pantalla actual.
7. Al tocar una notificacion se abre el detalle correspondiente.
8. La solucion no depende de que Flutter calcule destinatarios.
9. RLS impide leer notificaciones de otros usuarios.
10. El plan queda preparado para push sin obligar a implementarlo en esta primera fase.
11. El plan diferencia alertas comunitarias de promociones comerciales.
12. Las promociones futuras requieren consentimiento separado.
13. Las promociones futuras tienen limites de frecuencia propios.

## Riesgos y decisiones pendientes

### Uso de ubicacion

Decision pendiente: usar una ubicacion base configurada por el usuario o usar ultima ubicacion conocida. Por privacidad, se recomienda ubicacion base explicita.

### `pet_preferences`

El valor actual `both` no representa de forma clara si incluye `other`. Se recomienda decidir si:

- `both` significa solo perros y gatos.
- Se agrega `all`.
- Se migra a un arreglo JSONB.

### Push notifications

Push requiere configurar proveedor, permisos nativos, tokens y secretos. Debe tratarse como una fase separada para no bloquear la mejora interna.

### Notificaciones comerciales

Las promociones pertenecen a una fase posterior vinculada a monetizacion. Antes de implementarlas se debe definir:

- Si habra negocios/partners registrados en la app.
- Quien aprueba las campanas.
- Que categorias comerciales se permitiran.
- Limites de frecuencia por usuario.
- Politica de consentimiento y baja.
- Si se usara solo notificacion interna o tambien push/email.

La recomendacion es no activar promociones en el MVP inicial de alertas, pero si disenar el modelo de notificaciones para que las soporte sin cambios disruptivos.

### Volumen de usuarios

La formula Haversine en SQL es suficiente para MVP. Si hay muchos usuarios o reportes, conviene usar PostGIS e indices geoespaciales.

## Propuesta de primera iteracion

Implementar en esta primera iteracion:

1. Notificaciones internas por reporte perdido/encontrado con distancia real.
2. Notificaciones internas por nuevo avistamiento.
3. Notificacion al resolver caso.
4. Preferencias de notificacion editables desde perfil.
5. Navegacion desde notificacion al detalle de reporte.

Dejar para una segunda iteracion:

1. Push notifications.
2. Multiples zonas de alerta.
3. Cola de eventos desacoplada completa.
4. Coincidencias por IA.
5. Email.
6. Notificaciones comerciales, promociones y ofertas.
