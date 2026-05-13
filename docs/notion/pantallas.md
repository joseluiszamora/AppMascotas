# Pantallas principales de la app

## Pantallas requeridas para el MVP

### 1. Pantalla de bienvenida / Login

Objetivo:
Permitir que el usuario ingrese rápidamente a la app.

Componentes:

- Logo de la app.
- Mensaje principal.
- Botón "Iniciar sesión con Google".
- Texto breve sobre el propósito de la app.
- Enlaces a términos y privacidad.

Acciones:

- Iniciar sesión con Google.
- Aceptar permisos básicos.
- Crear sesión persistente.

---

### 2. Pantalla de inicio

Objetivo:
Mostrar accesos rápidos a las funciones principales.

Componentes:

- Saludo al usuario.
- Acceso a "Mis mascotas".
- Botón "Reportar mascota perdida".
- Botón "Reportar mascota encontrada".
- Acceso al mapa.
- Resumen de reportes cercanos.
- Alertas recientes.

Acciones:

- Registrar mascota.
- Crear reporte.
- Ver mapa.
- Ver notificaciones.

---

### 3. Perfil de usuario

Objetivo:
Permitir que el usuario gestione sus datos básicos.

Componentes:

- Foto de perfil.
- Nombres.
- Apellidos.
- Teléfono.
- Preferencias de mascotas.
- Historial de reportes.
- Configuración de notificaciones.

Acciones:

- Editar datos.
- Cambiar preferencias.
- Activar o desactivar notificaciones.
- Cerrar sesión.

---

### 4. Mis mascotas

Objetivo:
Listar las mascotas registradas por el usuario.

Componentes:

- Lista de mascotas.
- Foto principal.
- Nombre.
- Tipo.
- Estado:
  - Normal.
  - Perdida.
  - Encontrada.
- Botón "Agregar mascota".

Acciones:

- Ver detalle de mascota.
- Editar mascota.
- Reportar como perdida.
- Agregar nueva mascota.

---

### 5. Crear o editar mascota

Objetivo:
Registrar o actualizar información de una mascota.

Componentes:

- Subida de fotos.
- Nombre.
- Tipo de mascota.
- Raza.
- Sexo.
- Edad.
- Color predominante.
- Tamaño.
- Características distintivas.
- Vacunación.
- Esterilización.
- Número de chip.
- Estado.

Acciones:

- Guardar mascota.
- Editar datos.
- Eliminar foto.
- Cancelar.

---

### 6. Reportar mascota perdida

Objetivo:
Permitir que el dueño publique rápidamente un reporte de pérdida.

Componentes:

- Selector de mascota registrada.
- Fotos de la mascota.
- Ubicación donde se perdió.
- Fecha y hora aproximada.
- Descripción del caso.
- Datos de contacto autorizados.
- Botón publicar.

Acciones:

- Seleccionar mascota.
- Marcar ubicación.
- Publicar reporte.
- Enviar alertas cercanas.
- Compartir reporte.

---

### 7. Reportar mascota encontrada

Objetivo:
Permitir que cualquier usuario reporte una mascota encontrada o vista en la calle.

Componentes:

- Subida de foto.
- Ubicación del avistamiento.
- Fecha y hora.
- Características visibles.
- Comentario opcional.
- Botón publicar.

Acciones:

- Subir foto.
- Marcar ubicación.
- Publicar reporte.
- Notificar usuarios cercanos.

---

### 8. Mapa de reportes

Objetivo:
Mostrar reportes de mascotas perdidas y encontradas geolocalizados.

Componentes:

- Mapa.
- Marcadores de mascotas perdidas.
- Marcadores de mascotas encontradas.
- Filtros:
  - Zona.
  - Barrio.
  - Ciudad.
  - Radio.
  - Tipo de mascota.
  - Raza.
  - Color.
  - Tamaño.
  - Estado.
- Botón para centrar ubicación actual.

Acciones:

- Ver reporte.
- Aplicar filtros.
- Navegar hacia ubicación.
- Compartir reporte.

---

### 9. Detalle de reporte

Objetivo:
Mostrar información completa de un reporte.

Componentes:

- Fotos.
- Estado del caso.
- Tipo de reporte:
  - Perdida.
  - Encontrada.
- Descripción.
- Ubicación aproximada.
- Fecha y hora.
- Datos de la mascota.
- Botón contactar.
- Botón compartir.
- Botón reportar contenido.

Acciones:

- Contactar.
- Compartir.
- Guardar.
- Reportar.
- Marcar como resuelto si corresponde.

---

### 10. Notificaciones

Objetivo:
Mostrar alertas y actualizaciones relevantes para el usuario.

Componentes:

- Lista de notificaciones.
- Tipo de notificación.
- Fecha y hora.
- Estado leído/no leído.
- Acceso al reporte relacionado.

Acciones:

- Abrir notificación.
- Marcar como leída.
- Ir al detalle del reporte.

---

### 11. Configuración

Objetivo:
Permitir configurar preferencias generales.

Componentes:

- Radio de alertas.
- Tipos de notificación.
- Preferencias de mascotas.
- Privacidad.
- Cierre de sesión.

Acciones:

- Cambiar radio.
- Activar/desactivar alertas.
- Cambiar privacidad.
- Cerrar sesión.

---

## Pantallas para Etapa 2

### 12. Contacto

Objetivo:
Facilitar la comunicación segura entre usuarios.

Componentes:

- Botón de WhatsApp.
- Botón de llamada si está autorizado.
- Formulario de contacto.
- Mensajes automáticos de seguridad.

### 13. Posibles coincidencias IA

Objetivo:
Mostrar coincidencias sugeridas entre mascotas perdidas y encontradas.

Componentes:

- Lista de coincidencias.
- Score de similitud.
- Fotos comparadas.
- Datos principales.
- Botón contactar.

### 14. Panel administrador

Objetivo:
Gestionar usuarios, mascotas, reportes y contenido.

Componentes:

- Dashboard.
- Gestión de reportes.
- Gestión de usuarios.
- Moderación de contenido.
- Denuncias.
- Estadísticas básicas.
