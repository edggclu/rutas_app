# Contrato de la API (propuesta para acordar con el servidor Laravel)

Todas las rutas son JSON y llevan `Authorization: Bearer <token>` (menos `login`).
Las horas viajan en **UTC (ISO 8601)**; la app las muestra en America/Mexico_City.
Los nombres siguen el estilo en inglés del código actual del servidor.
El archivo `assets/mock/my_day.json` es un ejemplo real de este contrato.

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
  "photo_target_kb": 300, "video_max_s": 60
}
```
- `credit_authorization_wait_min`: el documento de requisitos dice 15 min en la
  sección 10.2 y 5 min en la 19. Hay que confirmar cuál es.
- Las familias de material que absorbe Telyser **no** se mandan a la app: el
  servidor marca el material absorbido y el técnico no ve ninguna etiqueta.

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
| `order` | int | Orden en la ruta (lo pone el jefe) |
| `status` | `pending` · `en_route` · `on_site` · `done` | |
| `result` | `finished` · `continue` · `blocked` · `no_answer` · null | Solo si `status = done` |
| `scheduled_at` | UTC · null | Hora de cita, si existe |
| `day_number` | int · null | "Día N" **sin total** (el trabajo puede extenderse) |
| `responsible` | bool | false = acompañante: solo sube fotos y marca "Me retiro" |
| `companions` | `[{id, name}]` | |
| `arrived_at`, `left_at` | UTC · null | |
| `km_from_previous` | number · null | Desde la visita anterior; la primera del día, desde la oficina. Alimenta la espera de "No me abren" |
| `client` | `{id, name, overdue}` | `overdue` = saldo vencido (sí o no, **sin montos**) |
| `place` | ver abajo | |
| `job` | ver abajo | |

### Lugar
`{ id, name, address, lat, lng, estimated_km_from_office, access_notes, contact }`
con `contact = { name, role, phone, authorized }`. `authorized` = puede pedir y aceptar extras.

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

### Pendiente para el paso 2 (se agrega a la visita)
- `checklist`: `{ source: "plan"|"quote"|"none", items: [{id, kind: "material"|"tool", text, quantity, product_id}] }`
  para la pantalla Salida (sale del plan del ingeniero; si no hay, de la cotización).
  La unidad (pieza o servicio) sale del producto del catálogo.
- `plan` completo (material, herramienta, notas, croquis con pines y adjuntos PDF) para el paso 5.
- `history`: visitas anteriores del lugar.

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

Tipos de evento: `departure_confirmed`, `missing_items`, `arrived` (automático o manual),
`no_answer_reported`, `client_contacted`, `office_called`, `no_answer_confirmed`,
`finished`, `continue_tomorrow`, `blocked`, `left_site`, `help_requested`.
**Se agregan** (el documento de requisitos no los lista): `photo_added`, `extra_added`,
`request_added`, `authorization_requested`, `validated`, `returned`.

## Otras rutas (de la sección 17 del documento de requisitos)
`POST /api/visits/{id}/media` · `/extras` · `/requests` · `/authorizations` ·
`GET /api/authorizations/{id}` · `GET /api/products/search?q=` · `GET /api/notifications` ·
`PUT /api/jobs/{id}/plan` · `GET /api/review` · `POST /api/jobs/{id}/review` ·
`GET /api/dispatch/today|unassigned|decisions` · `POST /api/visits` · `PATCH /api/visits/{id}` ·
`POST /api/devices`.
