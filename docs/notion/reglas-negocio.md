# Reglas de negocio

## Reglas generales

1. La app debe priorizar la recuperación de mascotas perdidas.
2. El MVP debe evitar funcionalidades que distraigan del flujo principal.
3. La app debe ser gratuita para usuarios finales en la Etapa 1.
4. La monetización no debe afectar la experiencia inicial.
5. La ubicación debe manejarse con cuidado para proteger la privacidad.
6. El usuario debe controlar qué datos de contacto desea mostrar.
7. Las notificaciones deben ser útiles y no invasivas.
8. Toda funcionalidad de IA debe considerarse de apoyo, no como verdad absoluta.

## Usuarios

1. Un usuario debe iniciar sesión con Google para usar las funciones principales.
2. Un usuario puede tener una o varias mascotas registradas.
3. Un usuario puede crear reportes de mascotas perdidas.
4. Un usuario puede crear reportes de mascotas encontradas.
5. Un usuario puede configurar sus preferencias de notificación.
6. Un usuario puede configurar su radio de alertas.
7. Un usuario puede cerrar sesión.

## Perfil de usuario

El perfil debe contener:

- Foto.
- Nombres.
- Apellidos.
- Teléfono.
- Preferencias de mascotas.
- Historial de reportes.
- Configuración de notificaciones.

Reglas:

1. El teléfono debe ser opcional.
2. El teléfono solo debe mostrarse a otros usuarios si el usuario lo autoriza.
3. Las preferencias de mascotas deben usarse para personalizar alertas y contenido.

## Mascotas

Una mascota debe tener:

- Nombre.
- Tipo.
- Raza.
- Sexo.
- Edad.
- Color predominante.
- Tamaño.
- Características distintivas.
- Fotos.
- Estado.

Estados permitidos:

- Normal.
- Perdida.
- Encontrada.

Reglas:

1. Una mascota pertenece a un usuario.
2. Una mascota puede tener múltiples fotos.
3. Una mascota registrada puede ser reportada como perdida.
4. Una mascota puede volver a estado normal cuando el caso se resuelve.
5. El número de chip debe ser opcional.
6. La información médica básica debe ser opcional en el MVP.

## Reportes

Tipos de reporte:

- Mascota perdida.
- Mascota encontrada.

Un reporte debe tener:

- Tipo.
- Ubicación.
- Fecha y hora.
- Descripción.
- Fotos.
- Estado del caso.
- Usuario creador.
- Datos visibles de contacto según autorización.

Estados del caso:

- Activo.
- En revisión.
- Resuelto.
- Cerrado.
- Reportado.

Reglas:

1. Un usuario puede crear un reporte de mascota perdida.
2. Un usuario puede crear un reporte de mascota encontrada aunque no sea dueño de la mascota.
3. Todo reporte debe tener ubicación aproximada.
4. Todo reporte debe tener fecha y hora aproximada.
5. Los reportes activos deben aparecer en el mapa.
6. Los reportes resueltos pueden mantenerse como historial.
7. Los reportes deben poder compartirse por WhatsApp, Facebook u otros canales.
8. Un reporte debe poder marcarse como resuelto.

## Geolocalización

Reglas:

1. La ubicación debe usarse para mostrar reportes cercanos.
2. La app debe permitir búsqueda por radio.
3. La ubicación exacta puede aproximarse para proteger privacidad.
4. El usuario debe poder navegar hacia la zona del reporte.
5. La app puede mostrar zonas de mayor incidencia.
6. El heatmap debe usarse como visualización general, no como ubicación exacta de domicilios.

## Notificaciones

Tipos de notificación:

- Nueva mascota perdida cercana.
- Nueva mascota encontrada cercana.
- Actualización de caso.
- Contacto recibido.
- Posible coincidencia por IA en Etapa 2.

Reglas:

1. El usuario debe poder activar o desactivar notificaciones.
2. El usuario debe poder configurar el radio de alertas.
3. La app debe evitar enviar notificaciones duplicadas.
4. Las alertas deben priorizar reportes cercanos.
5. Las notificaciones deben abrir el detalle del reporte relacionado.
6. Las notificaciones de IA solo deben activarse desde la Etapa 2.

## Contacto entre usuarios

Reglas:

1. El contacto directo completo pertenece a Etapa 2.
2. En el MVP puede existir contacto básico mediante teléfono o WhatsApp autorizado.
3. El usuario debe autorizar mostrar su teléfono.
4. Se debe permitir reportar usuarios sospechosos.
5. La app debe mostrar mensajes de seguridad antes de coordinar encuentros.

## Inteligencia artificial

Reglas:

1. La IA no pertenece al MVP.
2. La IA inicia en Etapa 2.
3. La IA debe usarse para sugerir coincidencias, no para confirmar identidad absoluta.
4. El sistema debe mostrar un score de similitud.
5. El usuario debe revisar manualmente las coincidencias.
6. Se deben evitar falsos positivos con notificaciones masivas.
7. La IA puede analizar:
   - Foto.
   - Raza aproximada.
   - Color predominante.
   - Características distintivas.
   - Tamaño.
   - Ubicación.
   - Fecha.

## Administración

Reglas:

1. El panel administrador pertenece a Etapa 2.
2. El administrador puede gestionar usuarios.
3. El administrador puede gestionar reportes.
4. El administrador puede moderar fotografías y contenido.
5. El administrador puede revisar denuncias.
6. El administrador puede cambiar estados de casos.
7. El administrador puede bloquear usuarios cuando corresponda.

## Monetización

Reglas:

1. No cobrar en Etapa 1.
2. No incluir publicidad invasiva en el MVP.
3. La monetización debe iniciar principalmente desde Etapa 3.
4. El modelo recomendado es B2B:
   - Veterinarias.
   - Tiendas de mascotas.
   - Peluquerías caninas.
   - Farmacias veterinarias.
   - Servicios de emergencia.
5. Los negocios podrán pagar por mayor visibilidad.
6. El marketplace debe dejarse para Etapa 5.

## Seguridad y privacidad

Reglas:

1. No exponer datos personales innecesarios.
2. No mostrar teléfono sin autorización.
3. Usar ubicación aproximada cuando sea necesario.
4. Permitir reportar contenido sospechoso.
5. Proteger imágenes y datos de usuarios.
6. Usar reglas de acceso en base de datos.
7. Cada usuario solo debe poder editar sus propios datos y mascotas.
