# Contrato de la API (propuesta para acordar con el servidor Laravel)

Todas las rutas son JSON y llevan `Authorization: Bearer <token>` (menos `login`).
Las horas viajan en **UTC (ISO 8601)**; la app las muestra en America/Mexico_City.
Los nombres siguen el estilo en inglés del código actual del servidor.
Los archivos de `assets/mock/` (`my_day.json`, `settings.json`, `review.json`, `my_jobs.json`, `notifications.json`, `dispatch.json`, `products.json`) son ejemplos reales de este contrato.

## Errores generales (propuesta)

| Código | Cuándo | Qué hace la app |
|---|---|---|
| 401 | Token vencido o inválido | Muestra la pantalla de sesión expirada y pide volver a entrar. La cola local no se borra |
| 403 | El usuario no tiene el permiso (por ejemplo, `engineer`) | Avisa que no tiene permiso |
| 409 | El recurso ya cambió (por ejemplo, un trabajo que ya se validó) | Vuelve a pedir la lista |
| 422 | Datos inválidos | Muestra el mensaje del servidor |

Formato del error: `{ "message": "texto para mostrar", "code": "codigo_estable" }`.
En `POST /api/events`, un evento que el servidor no acepta no es un error HTTP: se informa en `rejected`.

## POST /api/login
Entrada: `{ "username": "pedro", "password": "..." }`
Salida:
```json
{
  "token": "…",
  "user": { "id": 7, "name": "Pedro", "phone": "3220000007",
            "role": "technician", "permissions": ["engineer", "dispatch"] }
}
```
`permissions` puede traer `engineer` (agrega Por validar) y `dispatch` (agrega Rutas).
`GET /api/me` devuelve el mismo objeto `user`.

## GET /api/settings
Parámetros que cambian por decisión de la empresa (tabla `settings`). La app los
descarga al iniciar el día y **nunca** los escribe fijos en el código.
```json
{
  "arrival_radius_m": 150, "arrival_dwell_s": 60,
  "wait_base_min": 10, "wait_per_km_min": 1,
  "min_client_contacts": 1, "min_office_calls": 1,
  "undo_seconds": 10, "credit_authorization_wait_min": 5,
  "photo_target_kb": 300, "video_max_s": 60,
  "office_phone": "3220000000",
  "password_min_length": 8,
  "office_lat": 20.6420, "office_lng": -105.2190,
  "routing_base_url": "https://router.project-osrm.org"
}
```
- `credit_authorization_wait_min`: el documento de requisitos dice 15 min en la
  sección 10.2 y 5 min en la 19. **Pendiente de confirmar cuál es.**
- Las familias de material que absorbe Telyser **no** se mandan a la app: el
  servidor marca el material absorbido y el técnico no ve ninguna etiqueta.
- `office_phone`: teléfono de la oficina. La app lo usa para el botón "Llamar a la oficina".
- `password_min_length`: largo mínimo de una contraseña nueva (la app lo revisa antes de enviarla; el servidor vuelve a validar).
- `office_lat`, `office_lng`: ubicación de la oficina (pueden faltar). La primera ruta del día sale de ahí.
- `routing_base_url`: dirección de un servidor de rutas por calles compatible con OSRM (la app pide `GET {url}/route/v1/driving/{lng},{lat};{lng},{lat}?overview=full&geometries=geojson`). Puede faltar: entonces el mapa dibuja líneas rectas. El servidor público de demostración de OSRM (`router.project-osrm.org`) no es para producción; conviene uno propio o un servicio de pago.

## GET /api/my-day?date=YYYY-MM-DD
Ruta del día del usuario, con todo lo necesario para trabajar sin señal.
```json
{
  "date": "2026-10-06",
  "generated_at": "2026-10-06T13:02:11Z",
  "technician": { "id": 7, "name": "Pedro" },
  "visits": [ { …visita… } ]
}
```

### Visita
| Campo | Tipo | Notas |
|---|---|---|
| `id` | int | |
| `order` | int | Orden sugerido. **La app ya no lo usa para ordenar la ruta**: la calcula ella con la visita más cercana, y el técnico elige con cuál empezar. Solo sirve de respaldo si falta una ubicación |
| `status` | `pending` · `en_route` · `on_site` · `done` | |
| `result` | `finished` · `continue` · `blocked` · `no_answer` · null | Solo si `status = done` |
| `scheduled_at` | UTC · null | Hora de cita, si existe |
| `day_number` | int · null | "Día N" **sin total** (el trabajo puede extenderse) |
| `responsible` | bool | false = acompañante: solo sube fotos y marca "Me retiro" |
| `companions` | `[{id, name}]` | |
| `arrived_at`, `left_at` | UTC · null | |
| `km_from_previous` | number · null | Desde la visita anterior; la primera del día, desde la oficina. Alimenta la espera de "No me abren" |
| `client` | `{id, name, overdue, tier}` | `overdue` = saldo vencido (sí o no, **sin montos**). `tier` = tipo de cliente `A`, `B` o `C` (puede faltar); el técnico lo ve en el mapa para decidir con cuál empezar |
| `place` | ver abajo | |
| `job` | ver abajo | |

### Lugar
`{ id, name, address, lat, lng, estimated_km_from_office, access_notes, contact }`
con `contact = { name, role, phone, authorized }`. `authorized` = puede pedir y aceptar extras.
`lat`, `lng` y `estimated_km_from_office` pueden ser null.

### Trabajo
| Campo | Tipo | Notas |
|---|---|---|
| `id`, `folio` | int, string | Folio `TEL-AAMM-NNN` |
| `type` | `installation` · `corrective` · `preventive` | |
| `priority` | `normal` · `urgent` | |
| `coverage` | `paid` · `warranty` · `policy` | Quién paga |
| `status` | `scheduled` · `in_progress` · `to_validate` · `done` | El bloqueo va aparte |
| `description` | string | |
| `plan_summary` | string · null | Resumen del plan (para la tarjeta) |
| `engineer` | `{id, name}` | Ingeniero a cargo |
| `close_mode` | `on_site` · `remote` | |
| `block` | `{reason, waiting_for, since}` · null | "Detenido" = bloqueo encima del estado real |
| `warranty_guide` | string · null | Texto editable desde la web |
| `plan` | objeto · null | Plan completo del ingeniero (ver abajo). Null si todavía no hay |

### Plan del trabajo (`job.plan`)
```json
{ "notes": "El cable entra por el plafón del pasillo…",
  "items": [{ "id": 1, "kind": "material", "text": "Cámaras IP", "quantity": 8, "product_id": 301 },
            { "id": 4, "kind": "tool", "text": "Escalera de 6 m", "quantity": 1, "product_id": null }],
  "sketch": { "image": "https://…/croquis.png", "aspect_ratio": 1.5,
              "pins": [{ "id": 1, "label": "C1", "x": 0.13, "y": 0.68, "note": "…" }] } }
```
- `items`: `kind` es `material` o `tool`. **La lista de salida de la visita sale de aquí** (no hay un campo `checklist` aparte).
- `sketch.image`: URL de la imagen. `aspect_ratio` = ancho / alto, para colocar los pines sin leer la imagen.
- `x` y `y` van de 0 a 1 sobre la imagen (0,0 = esquina superior izquierda), así no dependen del tamaño de pantalla.
- `PUT /api/jobs/{id}/plan` lo guarda el ingeniero (ver "Editar el plan").

## POST /api/events
Envía la cola de acciones **en orden**. El servidor ignora un `uuid` que ya recibió.
```json
{ "events": [
  { "uuid": "7d3c…", "type": "arrived", "visit_id": 101,
    "occurred_at": "2026-10-06T14:20:07Z", "tz": "America/Mexico_City",
    "payload": { "mode": "manual", "lat": 20.7002, "lng": -105.2943 } }
] }
```
Respuesta: `{ "accepted": ["7d3c…"], "duplicates": [], "rejected": [] }`

Tipos de evento que manda la app:

| Área | Tipos |
|---|---|
| Salida | `departure_confirmed`, `missing_items`. `departure_confirmed` también se manda al salir hacia la siguiente visita: lleva el `visit_id` de la visita elegida |
| Llegada | `arrived` (automático o manual) |
| No me abren | `no_answer_reported`, `client_contacted`, `office_called`, `no_answer_confirmed` |
| En sitio y extras | `photo_added`, `extra_added`, `request_added`, `authorization_requested`, `route_delay_reported` |
| Cierre | `warranty_documented`, `finished`, `continue_tomorrow`, `blocked`, `left_site`, `help_requested`, `note_added` |

`photo_added`, `extra_added`, `request_added`, `authorization_requested`, `route_delay_reported` y `warranty_documented` **se agregan**: el documento de requisitos no los lista.

**Validar y regresar un trabajo no son eventos de la cola.** Necesitan señal y van directo a `POST /api/jobs/{id}/review` (ver "Por validar"). El servidor es quien registra el resultado.

El estado que ve el técnico es la ruta del servidor más los eventos que aún no se confirmaron. La app ignora con tolerancia un tipo de evento que no conoce.

## Otras rutas (de la sección 17 del documento de requisitos)
`POST /api/visits/{id}/media` · `/extras` · `/requests` · `/authorizations` ·
`GET /api/authorizations/{id}` · `GET /api/products/search?q=` · `GET /api/notifications` · `POST /api/notifications/read` ·
`PUT /api/jobs/{id}/plan` · `GET /api/review` · `GET /api/my-jobs` ·
`GET /api/dispatch/today|unassigned|decisions` · `POST /api/password` · `POST /api/password/forgot` · `POST /api/password/reset` · `POST /api/visits` · `PATCH /api/visits/{id}` ·
`POST /api/devices`.

### Datos (payload) de los eventos de extras

`extra_added`:
```json
{ "name": "Cámara IP 4 MP", "product_id": 301, "quantity": 1, "unit": "piece",
  "source": "own_stock", "reason": "client_asked",
  "requested_by": "authorized_contact", "requester_name": "Ing. Ramírez",
  "not_installed": false }
```
- `unit`: `piece` · `service` (no hay más unidades).
- `source`: `job_reserved` · `own_stock` · `bought_on_route`.
- `reason`: `client_asked` · `site_required`.
- `requested_by`: `authorized_contact`. Si lo pidió otra persona no se crea un extra: nace un `request_added`.
- El servidor marca como absorbido el cable, la canaleta y el tubo; la app no manda ese dato.

`request_added`: `description` y `origin` (`other_person` · `credit_hold` · `cannot_do_now`), más:
- si nació de un extra rechazado: los mismos datos del extra (`requested_by` = `authorized_contact` · `other`);
- si la creó el técnico con "Solicitud después": `requester_text` (nombre escrito a mano, opcional).

`route_delay_reported`: `{ "minutes": 120, "reason": "extra", "extra_name": "Cámara IP 4 MP" }`

### Datos (payload) de los eventos de cierre

`finished`: `{}` o, si hubo extras, `{ "extras_confirmed_by": "Ing. Ramírez", "extras_confirmed_role": "Mantenimiento" }`

`warranty_documented`: `{ "cause": "humidity_salt", "serial": "SN-77" }`
- `cause`: `defect` · `humidity_salt` · `impact` · `power_surge` · `tampering` · `unknown`.
- `serial` puede ser `null` si el técnico solo fotografió la etiqueta (archivo `warranty_serial`).

`continue_tomorrow`:
```json
{ "materials_used": [{ "id": 2, "text": "Cable UTP (m)", "planned": 120, "used": 70 }],
  "left_on_site": "4 cámaras en el cuarto de mantenimiento",
  "missing": "Cámaras del segundo piso y configurar el grabador",
  "laid_cable": true }
```
El servidor decide si propone una jornada el siguiente día hábil con el mismo técnico.

`blocked`: `{ "reason": "incident", "incident_kind": "accident", "note": "…" }`
- `reason`: `missing_material` · `site_differs` · `cannot_solve` · `client` · `incident` · `other`.
- `incident_kind`: `safety` · `property_damage` · `accident` (solo con `incident`; si no, `null`).
- El servidor decide a quién avisar según `reason` (tabla de la sección 11 del documento de requisitos).

`help_requested`: `{}` (el técnico abrió WhatsApp con el ingeniero a cargo).

`note_added`: `{ "text": "Olvidé anotar el cable sobrante" }`. Nota que el técnico agrega a una visita ya cerrada. Solo se agrega: lo ya enviado no se edita. El servidor la liga a la visita (`visit_id`).

### Tipos de archivo (`kind`)
`progress` · `warranty` (falla) · `warranty_serial` (etiqueta) · `damage` · `request` · `cabling_video` (video, espera Wi-Fi).

## Por validar (ingeniero)

Requiere el permiso `engineer` (si no, 403). Todo necesita señal: **no pasa por la cola**.

### GET /api/review
Trabajos terminados por otros técnicos que esperan validación.
```json
{ "jobs": [{
  "id": 17, "folio": "TEL-2610-017", "type": "corrective", "coverage": "warranty",
  "client": "Restaurante El Faro", "place": "Restaurante El Faro", "technician": "Marco",
  "closed_at": "2026-10-07T19:10:00Z", "notes": "…",
  "photos": [{ "id": 4, "kind": "warranty", "src": "https://…/foto.jpg", "caption": "…" }],
  "extras": [{ "name": "Conector RJ45", "quantity": 3, "not_installed": false }],
  "warranty": { "cause": "unknown", "serial": "SN-77123", "verdict": null },
  "plan": null } ] }
```
- `photos[].kind`: los mismos tipos de archivo de arriba. `src` es una URL.
- `warranty` es `null` si el trabajo no es de garantía. `cause` es la causa que eligió el técnico y `verdict` el dictamen del ingeniero (`null` = todavía no).
- `plan` tiene el mismo formato que `job.plan` (o `null` si no existía).
- Una garantía con `cause = unknown` y `verdict = null` **no se puede validar** hasta dictaminarla.

### POST /api/jobs/{id}/review
Un solo endpoint, tres formas:
```json
{ "result": "validated" }
{ "result": "returned", "note": "Falta la foto del grabador grabando" }
{ "result": "verdict", "cause": "humidity_salt" }
```
- `returned` exige `note` no vacía (si no, 422). Al regresar, el servidor genera la solicitud de otra visita para el jefe de ruta.
- `verdict` usa los mismos valores de `cause` que `warranty_documented`. El trabajo sigue en la lista, ya dictaminado.
- `validated` sobre una garantía sin dictaminar responde 422.
- Si el trabajo ya no está pendiente (alguien más lo resolvió), responde 409 y la app vuelve a pedir la lista.


## Mis trabajos (técnico)

### GET /api/my-jobs
Trabajos que el técnico ya terminó y lo que el ingeniero decidió de cada uno. Solo lectura; necesita señal y **no pasa por la cola**. Cualquier usuario autenticado lo puede pedir (devuelve solo los suyos).
```json
{ "jobs": [{
  "id": 21, "folio": "TEL-2610-021", "type": "installation",
  "client": "Hotel Bahía", "place": "Hotel Bahía — lobby",
  "closed_at": "2026-10-08T20:15:00Z",
  "review_status": "returned",
  "engineer": "Tono", "reviewed_at": "2026-10-08T22:05:00Z",
  "engineer_note": "Falta la foto del grabador grabando…" } ] }
```
- `review_status`: `to_validate` · `validated` · `returned`. La app lee un valor desconocido como `to_validate`.
- `engineer_note`: la nota que escribió el ingeniero al regresar el trabajo (`POST /api/jobs/{id}/review` con `returned`). Es `null` si el trabajo no fue regresado.
- `engineer` y `reviewed_at` son `null` mientras el trabajo esté `to_validate`.
- La app ordena la lista: regresados, por validar y validados; dentro de cada grupo, lo más reciente primero. El servidor puede mandarla en cualquier orden y debe limitarla a un periodo razonable (por ejemplo, los últimos 30 días).

## Editar el plan (ingeniero)

### PUT /api/jobs/{id}/plan
Reemplaza el plan completo del trabajo. Requiere el permiso `engineer` (si no, 403). Necesita señal: **no pasa por la cola**.
```json
{ "notes": "El cable entra por el plafón del pasillo…",
  "items": [{ "id": 1, "kind": "material", "text": "Cámaras IP", "quantity": 8, "product_id": 301 },
            { "id": 9, "kind": "tool", "text": "Escalera de 6 m", "quantity": 1, "product_id": null }],
  "sketch": { "image": "https://…/croquis.png", "aspect_ratio": 1.5,
              "pins": [{ "id": 1, "label": "C1", "x": 0.13, "y": 0.68, "note": "…" }] } }
```
- El cuerpo tiene el mismo formato que `job.plan`. `notes` y `sketch` pueden ser `null`.
- La app manda el plan **completo**: lo que no venga se borra. Los renglones y pines nuevos llevan un `id` temporal (mayor que los existentes); el servidor lo ignora y asigna los suyos.
- La app no cambia `sketch.image` ni `aspect_ratio`: reenvía los que recibió. La imagen se sube desde la web.
- Respuesta: el plan tal como quedó, con el mismo formato.
- 422 si algún renglón o pin trae el texto vacío, o una cantidad menor o igual a cero.
- Después de guardar, la app vuelve a pedir `GET /api/my-day` para que todos los dispositivos vean el plan nuevo.

## Avisos

### GET /api/notifications
Los avisos del usuario, de los más nuevos a los más viejos (la app los reordena de todos modos). Necesita señal: **no pasa por la cola**. Las notificaciones push (paso 7) avisan que hay uno nuevo, y esta lista es la fuente.
```json
{ "notifications": [{
  "id": 5, "type": "job_returned",
  "title": "Regresaron un trabajo",
  "body": "TEL-2610-021 (Clínica Santa Fe): falta la foto del grabador grabando.",
  "created_at": "2026-10-24T14:05:00Z",
  "read": false, "visit_id": null } ] }
```
- `type`: `route_changed` · `job_returned` · `job_validated` · `plan_updated`. Cualquier otro valor la app lo muestra igual, con un ícono genérico.
- `title` y `body` ya vienen escritos por el servidor, listos para mostrar.
- `visit_id` es la visita a la que se refiere el aviso, o `null`.
- Se recomienda limitar la lista a un periodo razonable (por ejemplo, los últimos 30 días).

### POST /api/notifications/read
Marca avisos como leídos. Entrada: `{ "ids": [5, 4] }`. Respuesta: `{ "updated": 2 }`. Un id que no existe o que ya estaba leído se ignora.

## Sesión expirada
Cualquier ruta que responda 401 hace que la app salga a la pantalla de login con el aviso "Tu sesión expiró". La cola de acciones no se borra: se manda cuando **el mismo usuario** vuelva a entrar (`user.id` igual al de la sesión que expiró). Si entra otra cuenta, la app rechaza esa sesión.

## Cambiar la contraseña

### POST /api/password
Cambia la contraseña del usuario con sesión. Necesita señal: **no pasa por la cola**. No lo hace administración.
```json
{ "current_password": "…", "new_password": "…" }
```
- Respuesta: 204 (sin cuerpo).
- 422 con `code: "wrong_password"` si la actual no es correcta. La app lo muestra como "La contraseña actual no es correcta".
- 422 con `code: "weak_password"` si la nueva no cumple las reglas (largo mínimo `password_min_length` de `/api/settings`, y distinta de la actual). La app ya revisa esto antes de enviar, pero el servidor es quien decide.
- Después de cambiarla, la sesión actual sigue valiendo; las demás sesiones del usuario pueden invalidarse (responderán 401).

## Rutas (jefe de ruta)

Requieren el permiso `dispatch` (si no, 403). Necesitan señal: **no pasan por la cola**. La app arma el tablero con cuatro lecturas. Por ahora solo se leen; crear, mover y reordenar visitas (`POST /api/visits`, `PATCH /api/visits/{id}`) es el paso siguiente.

### GET /api/dispatch/decisions
Lo que requiere la decisión del jefe. El servidor escribe el título y el detalle.
```json
{ "decisions": [{
  "id": 2, "kind": "blocked", "job_folio": "TEL-2610-017",
  "title": "Detenido: Restaurante El Faro",
  "detail": "Falta el grabador. Se espera a Axel. Lleva 2 días.",
  "created_at": "2026-10-28T16:00:00Z" }] }
```
- `kind`: `urgent` · `blocked` · `continue_proposed` · `returned` · `route_delay` · `out_of_order`. La app lee un valor desconocido como "otro" y lo muestra igual. Las urgencias van arriba; el resto, de lo más nuevo a lo más viejo.

### GET /api/dispatch/today?date=YYYY-MM-DD
Las rutas de todos los técnicos en un día (sin `date`, hoy; "Mañana" usa el día siguiente).
```json
{ "technicians": [{
  "id": 7, "name": "Pedro",
  "visits": [{ "id": 101, "status": "done", "result": "continue", "day_number": 1,
               "client": "Hotel Bahía", "place": "Hotel Bahía — torre 2",
               "scheduled_at": "2026-10-29T14:00:00Z" }] }] }
```
- `visits` va en el orden que decidió el técnico. `status` y `result` son los de `my-day`. La app calcula el estado del técnico ("En sitio en…", "En camino a…", "Libre") con sus visitas.

### GET /api/dispatch/unassigned
Trabajos aprobados sin visita, con el semáforo.
```json
{ "unassigned": [{
  "id": 42, "folio": "TEL-2610-042", "type": "installation", "priority": "normal",
  "client": "Colegio Horizonte", "place": "Colegio Horizonte — dirección",
  "lights": { "client_confirmed": "ok", "deposit_paid": "blocked", "balance": "ok",
              "material_ready": "ok", "access": "warning" },
  "can_schedule": false }] }
```
- `lights`: cinco luces con valor `ok` · `warning` · `blocked`. Una luz que falta o un valor desconocido se lee como `warning`.
- `can_schedule`: si el trabajo ya se puede programar (por ejemplo, un anticipo en `blocked` no deja). Si no viene, la app solo lo bloquea cuando alguna luz está en `blocked`.

### Recuperar la contraseña (sin sesión)

No llevan `Authorization`. Tampoco pasan por la cola.

**POST /api/password/forgot** — `{ "login": "pedro" }` (usuario o teléfono). El servidor manda un código al teléfono registrado. **Siempre responde igual**, exista o no el usuario, para no revelar quién tiene cuenta.
```json
{ "code_length": 6, "password_min_length": 8 }
```
- La app usa estos dos números para validar lo que se escribe (no los escribe fijos). El código vence a los pocos minutos y hay que limitar los intentos por usuario y por teléfono.
- "Reenviar código" vuelve a llamar esta ruta.

**POST /api/password/reset** — `{ "login": "pedro", "code": "123456", "new_password": "…" }`
- 204 si todo está bien. El servidor invalida el código y las sesiones abiertas del usuario.
- 422 con `code: "invalid_reset_code"` si el código no es correcto, ya venció o el usuario no existe (la misma respuesta en los tres casos). La app dice "El código no es correcto o ya venció" y deja pedir otro.
- 422 con `code: "weak_password"` si la contraseña nueva no cumple las reglas.
