# Telyser · App de campo (Flutter)

**Login, Mi día y tarjeta de visita, con datos de prueba.**

## Cómo arrancar
1. `flutter pub get`
2. `flutter test` (prueba que `assets/mock/my_day.json` cumple el contrato y demas tests)
3. `flutter run`

Usuarios de prueba (cualquier contraseña):
- `pedro` (o cualquier otro): técnico. Pestañas Mi día y Avisos.
- `tono`: técnico + ingeniero + coordina rutas. Pestañas Mi día, Rutas, Por validar y Avisos.

## Estructura
```
lib/
  core/        tema (colores de Figma), hora UTC -> México, widgets (deslizable, etiquetas…)
  domain/      modelos del contrato my-day, enums, estado del técnico (calculado)
    data/        repositories.dart (interfaces) + mock/ (datos de prueba) + local/ (base Drift y cola) + providers.dart
  features/    auth · shell (pestañas por permisos) · my_day (lista y tarjeta de visita)
assets/mock/   JSON de ejemplo: my_day, sesión de técnico y de jefe, settings
docs/          contrato_api.md y base_local_drift.dart.txt (para el paso 2)
```

## Base de datos local (Drift / SQLite)

Archivo `telyser.sqlite` dentro del teléfono. Definida en `lib/data/local/app_database.dart`.
Después de cambiar una tabla: `dart run build_runner build --delete-conflicting-outputs`.

```mermaid
erDiagram
    CACHED_VISITS ||--o{ OUTBOX_EVENTS : "visit_id"
    CACHED_VISITS ||--o{ MEDIA_QUEUE : "visit_id"

    SETTINGS_KV {
        string key PK
        string value "JSON del valor"
    }

    CACHED_VISITS {
        int id PK
        string date "YYYY-MM-DD"
        int order_in_route
        string status "pending | en_route | on_site | done"
        string result "nullable"
        string json "visita completa tal como llegó"
        datetime arrived_at_utc "nullable"
        double arrival_lat "nullable"
        double arrival_lng "nullable"
    }

    OUTBOX_EVENTS {
        int seq PK "autoincremental, define el orden de envío"
        string uuid UK "generado en el teléfono"
        string type "arrived, finished, ..."
        int visit_id FK "nullable"
        datetime occurred_at_utc "hora en que pasó"
        string tz "America/Mexico_City"
        string payload_json "default {}"
        string state "grace | pending | sending | failed"
        datetime grace_until_utc "nullable, fin de los segundos para deshacer"
        int attempts "default 0"
        string last_error "nullable"
    }

    MEDIA_QUEUE {
        string uuid PK
        int visit_id FK
        string kind "progress | warranty | damage | closing | cabling_video"
        string local_path
        bool wifi_only "default false"
        string state "default pending"
        datetime created_at_utc
    }
```

| Tabla | Para qué sirve |
|---|---|
| `settings_kv` | Parámetros de `/api/settings` (10 s para deshacer, 150 m, etc.). Sin señal se leen de aquí |
| `cached_visits` | Ruta del día descargada, para verla sin señal |
| `outbox_events` | Cola de acciones por enviar, en orden (`seq`) y con `uuid` para evitar duplicados |
| `media_queue` | Fotos y videos pendientes de subir |

**Estados de `outbox_events.state`:** `grace` (10 s para deshacer, no enviable) → `pending` → `sending` → `failed` (se reintenta). Deshacer borra la fila.

**Nota:** las relaciones por `visit_id` son lógicas. Drift no declara llaves foráneas reales en este esquema, así que la base no impide guardar un `visit_id` que no exista en `cached_visits`.




## Cómo se mapea `GET /api/my-day`

Contrato completo en `docs/contrato_api.md`. Ejemplo real en `assets/mock/my_day.json`.

### Flujo

```mermaid
flowchart LR
    A["Servidor Laravel<br/>GET /api/my-day"] -->|JSON| B["VisitRepository.myDay()"]
    B -->|"fromJson (a mano)"| C["Modelos Dart<br/>DayRoute > Visit"]
    C --> D["Pantallas<br/>(Riverpod)"]
    B -.->|"bloque 4"| E[("cached_visits<br/>json + columnas")]
    E -.->|"sin señal"| B
    F[("outbox_events")] -.->|"bloque 4: estado = JSON + cola"| D
```

Las líneas punteadas están **pendientes** (bloque 4). Hoy el repositorio de prueba lee el JSON de `assets/mock/` y lo convierte directo en modelos.

### Estructura del JSON y su modelo Dart

```mermaid
classDiagram
    DayRoute "1" --> "*" Visit
    Visit --> Client
    Visit --> Place
    Visit --> Job
    Visit --> "*" Person : companions
    Place --> Contact
    Job --> Person : engineer

    class DayRoute { date, visits }
    class Visit { id, order, status, result, scheduledAt, dayNumber, responsible, arrivedAt, kmFromPrevious }
    class Client { id, name, overdue }
    class Place { id, name, address, lat, lng, estimatedKmFromOffice, accessNotes }
    class Contact { name, role, phone, authorized }
    class Job { id, folio, type, priority, coverage, description, planSummary, warrantyGuide }
    class Person { id, name }
```

Todos los modelos están en `lib/domain/models.dart` y se parsean a mano con `fromJson`.

### Campo por campo

| JSON | Modelo Dart | Notas |
|---|---|---|
| `date` | `DayRoute.date` | |
| `visits[]` | `DayRoute.visits` | Se ordena por `order` al parsear |
| `visits[].status` | `Visit.status` (`VisitStatus`) | `pending`, `en_route`, `on_site`, `done`. Un valor desconocido cae en `pending` |
| `visits[].result` | `Visit.result` (`VisitResult?`) | `finished`, `continue`, `blocked`, `no_answer`. Nulo si no está `done` |
| `scheduled_at`, `arrived_at` | `scheduledAt`, `arrivedAt` | Se convierten a UTC. Se muestran en America/Mexico_City con `formatClock` |
| `day_number` | `dayNumber` | "Día N" sin total |
| `responsible` | `responsible` | `false` = acompañante |
| `companions[]` | `List<Person>` | |
| `km_from_previous` | `kmFromPrevious` | Alimenta la espera de "No me abren" |
| `client` | `Client` | `overdue` es solo sí/no, nunca montos |
| `place` | `Place` | `lat`, `lng` y `estimated_km_from_office` pueden ser nulos |
| `place.contact` | `Contact?` | `authorized` = puede pedir extras |
| `job.type` | `Job.type` (`JobType`) | `installation`, `corrective`, `preventive` |
| `job.priority` | `Job.priority` (`Priority`) | `normal`, `urgent` |
| `job.coverage` | `Job.coverage` (`Coverage`) | `paid`, `warranty`, `policy` |
| `job.engineer` |




## Qué falta (siguientes pasos)
2. Salida ("Llevo todo"), Llegué manual, cola local con Drift y 10 s para deshacer.
3. No me abren (espera, llamadas, "No me atendieron").
4. Extras, solicitudes y garantía.
5. Plan y Por validar (ingeniero).
6. Pantalla del jefe de ruta.
7. Llegué automático (geocerca) y notificaciones push.
8. API real y pruebas sin señal.

## Aviso
Si `flutter run` o `flutter analyze` marcan errores, probablemente sean detalles menores
de sintaxis o de versión de paquetes.
