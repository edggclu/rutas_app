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
  data/        repositories.dart (interfaces) + mock/ (datos de prueba) + providers.dart
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
