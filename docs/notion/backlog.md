# Backlog del proyecto

## Etapa 1 — MVP base

### Épica 1: Autenticación

#### Tarea 1.1 — Login con Google

Prioridad: Alta

Como usuario quiero iniciar sesión con Google para acceder rápidamente a la app.

Criterios de aceptación:

- El usuario puede iniciar sesión con Google.
- La sesión queda persistente.
- Si el usuario ya inició sesión, entra directamente al inicio.

#### Tarea 1.2 — Cierre de sesión

Prioridad: Alta

Criterios de aceptación:

- El usuario puede cerrar sesión.
- Al cerrar sesión vuelve a la pantalla de bienvenida.

---

### Épica 2: Perfil de usuario

#### Tarea 2.1 — Crear perfil de usuario

Prioridad: Alta

Campos:

- Foto.
- Nombres.
- Apellidos.
- Teléfono.
- Preferencias de mascotas.

Criterios de aceptación:

- El perfil se crea después del primer login.
- El usuario puede editar sus datos.
- El teléfono puede quedar vacío.

#### Tarea 2.2 — Configuración de notificaciones

Prioridad: Alta

Criterios de aceptación:

- El usuario puede activar o desactivar notificaciones.
- El usuario puede configurar radio de alertas.
- El usuario puede elegir tipos de alertas.

---

### Épica 3: Gestión de mascotas

#### Tarea 3.1 — Registrar mascota

Prioridad: Alta

Campos:

- Nombre.
- Tipo.
- Raza.
- Sexo.
- Edad.
- Color predominante.
- Tamaño.
- Características distintivas.
- Fotos.
- Vacunación.
- Esterilización.
- Número de chip.

Criterios de aceptación:

- El usuario puede registrar una mascota.
- La mascota queda asociada al usuario.
- Se puede subir más de una foto.

#### Tarea 3.2 — Editar mascota

Prioridad: Alta

Criterios de aceptación:

- El usuario puede editar mascotas propias.
- El usuario no puede editar mascotas de otros usuarios.

#### Tarea 3.3 — Cambiar estado de mascota

Prioridad: Alta

Estados:

- Normal.
- Perdida.
- Encontrada.

Criterios de aceptación:

- Al reportar pérdida, la mascota cambia a "perdida".
- Al resolver caso, puede volver a "normal".

---

### Épica 4: Reportes de mascotas perdidas

#### Tarea 4.1 — Crear reporte de mascota perdida

Prioridad: Alta

Criterios de aceptación:

- El usuario puede seleccionar una mascota registrada.
- Puede indicar ubicación.
- Puede agregar fecha y hora aproximada.
- Puede agregar descripción.
- Puede publicar el reporte.
- El reporte aparece en el mapa.
- Se envían alertas cercanas.

#### Tarea 4.2 — Compartir reporte

Prioridad: Media

Criterios de aceptación:

- El usuario puede compartir el reporte por WhatsApp.
- El usuario puede compartir el reporte por Facebook u otros canales compatibles.

---

### Épica 5: Reportes de mascotas encontradas

#### Tarea 5.1 — Crear reporte de mascota encontrada

Prioridad: Alta

Criterios de aceptación:

- El usuario puede subir foto.
- Puede indicar ubicación.
- Puede indicar fecha y hora.
- Puede completar características visibles.
- El reporte aparece en mapa.
- Se envían alertas cercanas.

---

### Épica 6: Mapa y filtros

#### Tarea 6.1 — Mostrar reportes en mapa

Prioridad: Alta

Criterios de aceptación:

- El mapa muestra mascotas perdidas.
- El mapa muestra mascotas encontradas.
- El usuario puede abrir el detalle del reporte desde un marcador.

#### Tarea 6.2 — Filtros de reportes

Prioridad: Alta

Filtros:

- Zona.
- Barrio.
- Ciudad.
- Radio de distancia.
- Tipo de mascota.
- Raza.
- Color.
- Tamaño.
- Estado.

Criterios de aceptación:

- El usuario puede aplicar filtros.
- Los resultados del mapa cambian según los filtros.

#### Tarea 6.3 — Ubicación aproximada

Prioridad: Media

Criterios de aceptación:

- La app puede mostrar ubicación aproximada para proteger privacidad.
- No se expone ubicación exacta sensible innecesariamente.

---

### Épica 7: Notificaciones

#### Tarea 7.1 — Push notifications

Prioridad: Alta

Criterios de aceptación:

- El usuario recibe notificaciones si las tiene activadas.
- La notificación abre el detalle del reporte.

#### Tarea 7.2 — Alertas cercanas

Prioridad: Alta

Criterios de aceptación:

- Al crear un reporte, se identifican usuarios cercanos.
- Se envía alerta según radio configurado.
- Se evita duplicar alertas innecesarias.

---

## Etapa 2 — IA, contacto y administración

### Épica 8: IA de reconocimiento visual

#### Tarea 8.1 — Comparación automática de imágenes

Prioridad: Media

Criterios de aceptación:

- El sistema compara fotos de mascotas perdidas y encontradas.
- Se genera score de similitud.

#### Tarea 8.2 — Matching de reportes

Prioridad: Media

Criterios de aceptación:

- Se sugieren posibles coincidencias.
- El usuario puede revisar coincidencias antes de contactar.

---

### Épica 9: Contacto entre usuarios

#### Tarea 9.1 — Botón contactar

Prioridad: Media

Criterios de aceptación:

- El usuario puede contactar al dueño si existe autorización.
- Se puede abrir WhatsApp o llamada.
- Se muestran mensajes de seguridad.

#### Tarea 9.2 — Reportar usuario sospechoso

Prioridad: Media

Criterios de aceptación:

- El usuario puede reportar conducta sospechosa.
- El administrador puede revisar la denuncia.

---

### Épica 10: Panel administrador

#### Tarea 10.1 — Gestión de reportes

Prioridad: Media

Criterios de aceptación:

- El administrador puede ver reportes.
- Puede cambiar estado.
- Puede moderar contenido.

#### Tarea 10.2 — Gestión de usuarios

Prioridad: Media

Criterios de aceptación:

- El administrador puede revisar usuarios.
- Puede bloquear usuarios cuando corresponda.

---

## Etapa 3 — Monetización

### Épica 11: Publicidad segmentada

Tareas:

- Crear anuncios por ubicación.
- Crear anuncios por tipo de mascota.
- Medir clics.
- Medir impresiones.
- Gestionar campañas.

### Épica 12: Directorio de servicios

Tareas:

- Registrar veterinarias.
- Registrar tiendas de mascotas.
- Registrar peluquerías caninas.
- Registrar farmacias veterinarias.
- Registrar servicios de emergencia.
- Mostrar botón llamar.
- Mostrar botón WhatsApp.
- Permitir calificaciones y reseñas.

### Épica 13: Analíticas

Tareas:

- Medir mascotas registradas.
- Medir reportes activos.
- Medir mascotas recuperadas.
- Medir zonas con más pérdidas.
- Medir usuarios activos.
- Medir notificaciones enviadas.

---

## Etapa 4 — Comunidad

Tareas:

- Publicaciones de mascotas.
- Fotos y videos.
- Likes.
- Comentarios.
- Seguidores.
- Historias.
- Comunidades por zona.
- Puntos por reportar avistamientos.
- Insignias por ayudar.
- Ranking de colaboradores.

---

## Etapa 5 — Marketplace e IA avanzada

Tareas:

- Marketplace de productos.
- Servicios veterinarios.
- Reservas.
- Pagos online.
- Delivery.
- Comisiones.
- Chatbot veterinario.
- Recomendaciones inteligentes.
- Reconocimiento facial animal avanzado.
- Generación automática de descripción del reporte.
