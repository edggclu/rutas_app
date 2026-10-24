# Telyser · App de campo (Flutter)

App Android para técnicos e ingenieros de campo de Telyser (cámaras, alarmas, redes). Funciona completa con datos de prueba; la API real (Laravel) está pendiente.

**Qué hace hoy:** login, Mi día, salida con lista de material, llegada, "No me abren", En sitio (fotos, extras, garantía), cierre (Terminé, Sigo otro día, No pude seguir), plan del trabajo con croquis, Mis trabajos (estado de lo que terminó) y Por validar del ingeniero. Todo lo del técnico funciona sin señal y se manda en una cola.

## Índice
1. [Cómo arrancar](#cómo-arrancar)
2. [Modo demo](#modo-demo)
3. [Arquitectura](#arquitectura)
4. [Base de datos local](#base-de-datos-local-drift--sqlite)
5. [Cómo se mapea `GET /api/my-day`](#cómo-se-mapea-get-apimy-day)
6. [Cómo funciona una acción del técnico](#cómo-funciona-una-acción-del-técnico)
7. [Módulos](#módulos)
8. [Cómo agregar cosas](#cómo-agregar-cosas)
9. [Pruebas](#pruebas)
10. [Pendiente](#pendiente)

## Cómo arrancar
1. `flutter pub get`
2. `flutter test` (incluye que los archivos de `assets/mock/` cumplen el contrato)
3. `flutter run`

Después de cambiar una tabla de Drift: `dart run build_runner build --delete-conflicting-outputs`.

Usuarios de prueba:
- `pedro` / `pedro123`: técnico. Pestañas Mi día, Mis trabajos y Avisos.
- `tono` / `tono123`: técnico + ingeniero + coordina rutas. Pestañas Mi día, Mis trabajos, Rutas, Por validar y Avisos.

El contrato con el servidor está en `docs/contrato_api.md`.

## Modo demo

Con `kDemoMode = true`:
- La espera de "No me abren" es de 1 minuto (`wait_base_min: 1`, `wait_per_km_min: 0`).
- El repositorio de prueba pone la fecha de hoy a la ruta.
- El menú ⋮ de Mi día ofrece **Cerrar sesión** y **Reiniciar datos de demo** (borra la cola y las fotos).

"Reiniciar datos de demo" **no** restaura la lista de Por validar: esa vive en memoria del repositorio de prueba y vuelve a su estado inicial al cerrar la app por completo.

## Arquitectura

No es MVC clásico. Es una arquitectura por capas con estado reactivo (parecida a MVVM con Clean Architecture). Regla: las dependencias solo van hacia adentro. `test/architecture_test.dart` la vigila con 5 reglas.

```
features/     pantallas  ──►  providers/  ──►  application/  ──►  domain/
                                  │                 │
                                  └──────►  data/ ◄─┘   (data implementa contratos)
core/         widgets y utilidades genéricas, sin reglas del negocio
```

| Carpeta | Qué contiene | Qué NO puede importar |
|---|---|---|
| `domain/` | Modelos, eventos y reglas en Dart puro | Flutter, Drift, `dart:io`, ni ninguna otra capa |
| `application/` | Qué pasa cuando alguien hace algo (una clase por área) | Flutter, pantallas, providers |
| `data/` | Drift, repositorios (de prueba hoy, API mañana), ubicación | Pantallas |
| `providers/` | Conecta todo con Riverpod, un archivo por tema | — |
| `features/` | Pantallas y sus widgets | — |
| `core/` | Widgets compartidos, formato, tema, lanzadores | Reglas del negocio |

### Ideas que sostienen el diseño

- **El estado de una visita se calcula, no se guarda:** `ruta del servidor + eventos de la cola`. Por eso deshacer es borrar una fila y por eso el estado sobrevive a cerrar la app (es un event sourcing ligero).
- **Las pantallas nunca cambian el estado directamente.** Solo encolan eventos.
- **Flujo en un solo sentido:** pantallas → providers → application → domain. `data` implementa los contratos que define el dominio.
- **Cada evento lleva un UUID** generado en el teléfono, para que reintentar el envío no duplique nada.
- **Nada configurable va fijo en el código:** los parámetros (segundos para deshacer, radio de llegada, espera, etc.) vienen del servidor (`/api/settings`) y se guardan localmente.
- **Lectura tolerante:** un tipo de evento que la app no conoce se lee como `UnknownEvent` y no la rompe.
- **Lo que necesita señal no pasa por la cola.** Validar, regresar y dictaminar (ingeniero) van directo al servidor.

### Convenciones de pantalla

| Necesito... | Uso |
|---|---|
| Guardar una acción con "Deshacer" | `runUndoable(context, ref, action: (a) => a.<área>.<método>(...), message: ..., after: AfterSave.pop)` (`AfterSave.stay`, `pop` o `popToRoot`) |
| Un aviso corto | `messenger.toast('...')` (con el `messenger` guardado antes del `await`) |
| Una caja blanca con borde | `AppCard(child: ...)` |
| Mostrar un número (cantidad, km) | `formatNumber(valor)` |
| Un campo donde se escribe un número o texto corto | `inputFormatters: decimalInput` (cantidades), `integerInput` (minutos, piezas) o `shortText(max)`. `keyboardType` solo cambia el teclado: no impide pegar letras |
| Abrir mapa, llamar o WhatsApp | `openMap(...)`, `callPhone(...)`, `openWhatsApp(...)` |
| Mostrar una imagen de asset o URL | `AppImage(src: ...)` |
| Una pantalla larga | Una pantalla que solo **compone** secciones en `widgets/`; cada sección lee lo que necesita con `ref.watch` |

## Base de datos local (Drift / SQLite)

Archivo `telyser.sqlite` dentro del teléfono. Definida en `lib/data/local/app_database.dart`.

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
        string kind "progress | warranty | warranty_serial | damage | request | cabling_video"
        string local_path
        bool wifi_only "default false"
        string state "default pending"
        datetime created_at_utc
    }
```

| Tabla | Para qué sirve |
|---|---|
| `settings_kv` | Parámetros de `/api/settings`. Sin señal se leen de aquí |
| `cached_visits` | Ruta del día descargada, para verla sin señal |
| `outbox_events` | Cola de acciones por enviar, en orden (`seq`) y con `uuid` para evitar duplicados |
| `media_queue` | Fotos y videos pendientes de subir |

**Estados de `outbox_events.state`:** `grace` (segundos para deshacer, no enviable) → `pending` → `sending` → `failed` (se reintenta). Deshacer borra la fila.

**Notas:**
- Las relaciones por `visit_id` son lógicas. Drift no declara llaves foráneas reales en este esquema, así que la base no impide guardar un `visit_id` que no exista en `cached_visits`.
- `settings_kv` no se relaciona con las demás tablas.
- `media_queue` y `outbox_events` no se relacionan entre sí: las fotos y videos se suben por su propio camino (`POST /api/visits/{id}/media`).
- Las fotos se copian a `<documentos de la app>/media/visit_<id>/<uuid>.jpg`. La carpeta de la cámara es temporal y Android puede borrarla, por eso se copia.

## Cómo se mapea `GET /api/my-day`

Contrato completo en `docs/contrato_api.md`. Ejemplo real en `assets/mock/my_day.json`.

### Flujo

```mermaid
flowchart LR
    A["Servidor Laravel<br/>GET /api/my-day"] -->|JSON| B["VisitRepository.myDay()"]
    B -->|"fromJson (a mano)"| C["Modelos Dart<br/>DayRoute > Visit"]
    B -->|"guarda"| E[("cached_visits<br/>json + columnas")]
    E -->|"sin señal"| B
    C --> D["Pantallas<br/>(Riverpod)"]
    F[("outbox_events")] -->|"estado = JSON + cola"| D
```

Hoy el repositorio de prueba lee el JSON de `assets/mock/` en lugar del servidor. Lo demás (guardar la ruta, leerla sin señal y combinarla con la cola) ya funciona.

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
    Job --> Plan
    Plan --> "*" PlanItem
    Plan --> Sketch
    Sketch --> "*" SketchPin

    class DayRoute { date, visits }
    class Visit { id, order, status, result, scheduledAt, dayNumber, responsible, arrivedAt, kmFromPrevious }
    class Client { id, name, overdue }
    class Place { id, name, address, lat, lng, estimatedKmFromOffice, accessNotes }
    class Contact { name, role, phone, authorized }
    class Job { id, folio, type, priority, coverage, description, planSummary, warrantyGuide, plan }
    class Person { id, name }
    class Plan { notes, items, sketch }
    class PlanItem { id, kind, text, quantity, productId }
    class Sketch { image, aspectRatio, pins }
    class SketchPin { id, label, x, y, note }
```

Los modelos se parsean a mano con `fromJson`, con lectores tolerantes (`readString`, `readInt`, `readMaps`…): un campo faltante o de tipo raro no tumba la app.

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
| `job.engineer` | `Job.engineer` (`Person?`) | Para abrir WhatsApp con el ingeniero a cargo |
| `job.plan_summary`, `warranty_guide` | `planSummary`, `warrantyGuide` | Texto o nulo |
| `job.plan` | `Job.plan` (`Plan?`) | Notas, material, herramienta y croquis con pines. Nulo si todavía no hay |

### Qué se ignora todavía

Estos campos del contrato **no** se leen en el modelo actual:

| Campo | Se necesitará en |
|---|---|
| `generated_at`, `technician` (raíz) | Informativos |
| `visits[].left_at` | Visita hecha (C8) |
| `job.status`, `job.close_mode`, `job.block` | Vista del jefe de ruta (paso 6) |

El JSON completo de cada visita se guarda en `cached_visits.json`, así que agregar un campo después **no requiere migrar la base**: solo se amplía el modelo Dart.

### Cuando cambie el contrato

1. Actualizar `docs/contrato_api.md` y el archivo de `assets/mock/` que corresponda.
2. Ajustar el modelo en `lib/domain/`.
3. Correr `flutter test`. Las pruebas de modelos verifican que los mocks cumplen el contrato.

## Cómo funciona una acción del técnico

Ejemplo: Salida.

```mermaid
sequenceDiagram
    actor T as Técnico
    participant UI as Pantalla (DepartureScreen)
    participant A as DepartureActions
    participant O as outbox_events (cola)
    participant S as myDayProvider (applyEvents)

    T->>UI: desliza "Llevo todo"
    UI->>A: confirm() vía runUndoable
    A->>O: enqueue(missing_items) y enqueue(departure_confirmed), estado grace
    O-->>S: watchAll() emite la cola
    S-->>UI: visita 1 = En camino
    UI-->>T: barra "quedan 10 s · Deshacer"
    alt toca Deshacer antes de tiempo
        T->>A: undo()
        A->>O: borra las filas
        O-->>S: emite otra vez
        S-->>UI: visita 1 vuelve a Por hacer
    else pasan los segundos
        Note over O: sigue en grace. El enviador (paso 8) llama releaseExpired(), las pasa a pending y las manda en orden
    end
```

**Regla de oro:** las pantallas nunca cambian el estado de una visita directamente. Solo encolan eventos; el estado se **recalcula** como `ruta del servidor + eventos de la cola`.

La barra de deshacer calcula el tiempo restante desde una hora límite fija guardada con el evento (nunca desde un contador propio), así no se reinicia ni muestra el mensaje anterior.

### Reglas de `applyEvents`

`applyEvents` es una función pura con un `switch` sobre los eventos tipados, **sin `default`**: si agregas un evento nuevo, el compilador te obliga a decidir qué hace.

| Evento | Efecto en la ruta |
|---|---|
| `departure_confirmed` | La visita pasa de Por hacer a En camino |
| `arrived` | La visita pasa a En sitio y guarda la hora |
| `finished`, `continue_tomorrow`, `blocked`, `no_answer_confirmed` | La visita queda Hecha con su resultado y la siguiente por hacer pasa a En camino (salvo que ya haya una En camino o En sitio) |
| Los demás | No cambian el estado; solo viajan al servidor |

### Cuándo se puede marcar "Llegué"

`arrivalBlock(visit, visits)` decide si el deslizable está activo:

| Resultado | Cuándo | Qué ve el técnico |
|---|---|---|
| `routeNotStarted` | La visita todavía está Por hacer (no confirmó la salida) | Deslizable gris con el motivo |
| `anotherVisitInProgress` | Hay otra visita En camino o En sitio | Deslizable gris con el motivo |
| (ninguno) | La visita está En camino y no hay otra en curso | Deslizable activo |

## Módulos

### Salida y lista de material (C2)
`features/departure/` muestra la lista (sale de `job.plan.items`), los faltantes y el deslizable "Llevo todo". Acciones en `application/` (área `departure`).

### Llegada y "¿Ya te abrieron?"

```mermaid
sequenceDiagram
    actor T as Técnico
    participant D as VisitDetailScreen
    participant A as ArrivalActions.arrive()
    participant L as LocationService (GPS)
    participant O as outbox_events (cola)
    participant S as myDayProvider (applyEvents)

    T->>D: desliza "Llegué"
    D->>A: arrive(visitId)
    A->>L: currentPosition()
    L-->>A: lat/lng (o null si no hay GPS o permiso)
    A->>O: enqueue(arrived, {mode: manual, lat, lng}) en estado grace
    O-->>S: watchAll() emite la cola
    S-->>D: visita = En sitio, y aparece el panel "¿Ya te abrieron?"
    alt toca Deshacer antes de tiempo
        T->>A: undo()
        A->>O: borra la fila
        S-->>D: visita = En camino, vuelve el deslizable
    else toca Empezar
        D->>T: abre la pantalla En sitio
    end
```

| Archivo | Qué hace |
|---|---|
| `data/location_service.dart` | `LocationService` (contrato) y `DeviceLocationService` (GPS real). Lee la ubicación una sola vez. Si falla, devuelve `null` y Llegué se marca igual |
| `features/my_day/visit_detail_loader.dart` | Lee la visita actual y se la pasa a la tarjeta para que se redibuje sola |
| `features/my_day/arrival_panel.dart` | Panel "¿Ya te abrieron?" con Empezar y No me abren |

### "No me abren"

```mermaid
flowchart TD
    A["Técnico en el panel ¿Ya te abrieron?"] -->|"toca No me abren"| B["reportNoAnswer()<br/>encola no_answer_reported (una vez)"]
    B --> C["Pantalla C4: cuenta regresiva"]
    C -->|"Llamar o WhatsApp al cliente"| D["encola client_contacted"]
    C -->|"Llamar a la oficina"| E["encola office_called"]
    D & E & F["Pasa el tiempo de espera"] --> G{"computeNoAnswerStatus:<br/>¿las 3 condiciones?"}
    G -->|"sí"| H["Se activa el deslizable No me atendieron"]
    H --> I["confirmNoAnswer()<br/>encola no_answer_confirmed"]
    I --> J["Visita Hecha (no_answer) y la siguiente En camino"]
```

La espera es `wait_base_min + wait_per_km_min × km`, redondeada hacia arriba al minuto. Siempre se calcula desde la hora de llegada guardada; el reloj de la pantalla (`tickProvider`, cada segundo) solo la redibuja.

| Parámetro del servidor | Para qué |
|---|---|
| `wait_base_min`, `wait_per_km_min` | Cuánto espera el técnico |
| `min_client_contacts`, `min_office_calls` | Intentos mínimos antes de poder irse |
| `office_phone` | Teléfono del botón "Llamar a la oficina" |

### En sitio y fotos (C5)

`features/site/site_screen.dart` solo **compone** secciones de `features/site/widgets/`: `NoAnswerBanner`, `ArrivalInfo`, `WarrantySection`, `PhotosSection`, `ExtrasSection` y `CloseBar`.

| Regla | Dónde |
|---|---|
| Solo el responsable cierra la visita | `visit.responsible` en `SiteScreen`; los acompañantes no ven los botones de cierre |
| En garantía no se puede terminar sin el bloque de garantía | `isWarranty` deshabilita el deslizable |
| Las visitas En sitio abren directo C5 desde Mi día | `my_day_screen.dart` |

Las fotos y videos se guardan con `MediaRepository` (`addPhoto`, `addVideo`, `watchForVisit`, `clearAll`). Devuelve `MediaItem` con un `MediaKind`, para que las pantallas no conozcan Drift. `features/site/capture_photo.dart` abre la cámara.

### Extras y solicitudes para después

```mermaid
flowchart TD
    A["Formulario Agregar extra"] --> B{"decideExtra()"}
    B -->|"lo pidió otra persona"| C["request_added (origin: other_person)"]
    B -->|"saldo vencido + equipo"| D["request_added (origin: credit_hold)"]
    B -->|"cualquier otro caso"| E["extra_added"]
    E -->|"retrasa las siguientes visitas"| F["route_delay_reported (jefe)"]
    G["Botón Solicitud después"] --> H["request_added (origin: cannot_do_now)"]
```

`decideExtra` es la regla (pura, en `domain/`). `isEquipment` del producto alimenta la regla del saldo vencido. Pantallas: `features/extras/add_extra_screen.dart` (E1) y `add_request_screen.dart` (E4, con fotos). Solo existen dos unidades: pieza y servicio.

### Cierre de la visita

```mermaid
flowchart TD
    A["En sitio"] -->|"desliza Terminé"| B{"¿hubo extras?"}
    B -->|"no"| E["finished"]
    B -->|"sí"| C["Hoja: el contacto escribe su nombre"]
    C -->|"confirma"| E
    C -->|"cancela"| A
    A -->|"desliza No lo terminé"| D{"¿qué pasó?"}
    D -->|"Sigo otro día"| F["continue_tomorrow<br/>(material, qué falta, video si hubo cable)"]
    D -->|"No pude seguir"| G["blocked<br/>(motivo, nota, fotos)"]
    H["Visita de garantía"] -->|"documentar causa, foto y serial"| I["warranty_documented"]
    I -->|"habilita"| E
```

| Archivo | Qué hace |
|---|---|
| `features/site/warranty_*.dart` | Tarjeta y pantalla del bloque de garantía (G1 y G1b) |
| `features/closing/finish_sheet.dart` | C6: confirmación de extras |
| `features/closing/not_finished_sheet.dart` | C7: elegir entre las dos opciones |
| `features/closing/continue_screen.dart` | C7a: Sigo otro día |
| `features/closing/blocked_screen.dart` | C7b: No pude seguir (6 motivos, nota obligatoria, casos especiales de accidente y daño) |
| `core/widgets/choice_group.dart` | Grupo de chips compartido |

Reglas en `domain/`: `canSaveWarranty`, `canContinueTomorrow`, `canSendBlocked`.

### Plan del trabajo (D1)

El técnico ve el plan del ingeniero en solo lectura (el ingeniero también lo puede editar, ver abajo): notas, material, herramienta y un croquis con pines.

| Archivo | Qué hace |
|---|---|
| `features/plan/plan_screen.dart` | Pantalla D1 |
| `features/plan/widgets/sketch_view.dart` | El croquis con pines interactivos. Los pines usan `x` y `y` relativos (0 a 1), así no dependen del tamaño de pantalla |
| `core/widgets/app_image.dart` | Imagen de asset (pruebas) o de URL (API real). Si no carga, muestra un ícono |
| `assets/mock/croquis_hotel.png` | Croquis de ejemplo (Hotel Bahía) |

Se llega desde "Ver plan completo" en la tarjeta de la visita y desde "Ver plan del ingeniero" en En sitio.

#### Editar el plan (ingeniero)

Con el permiso `engineer`, la pantalla del plan muestra **Editar** (y la tarjeta de la visita ofrece **Crear plan** si el trabajo no tiene). El ingeniero cambia las notas, agrega, edita o quita material y herramienta, y en el croquis agrega puntos (tocando un lugar vacío), los mueve (arrastrando) y edita su etiqueta y nota. Guardar necesita señal y **no pasa por la cola**. La imagen del croquis no se cambia desde la app: se sube desde la web.

| Archivo | Qué hace |
|---|---|
| `features/plan/plan_edit_screen.dart` | Pantalla D2. Los cambios viven solo en la pantalla hasta tocar "Guardar plan" |
| `features/plan/widgets/sketch_editor.dart` | El croquis editable (agregar, elegir y arrastrar pines) |
| `domain/plan_rules.dart` | `canSavePlan` (sin renglones ni pines vacíos, cantidades positivas) y `nextLocalId` |
| `data/repositories.dart` | Interfaz `PlanRepository` |
| `data/mock/mock_repositories.dart` | `MockPlanRepository`: guarda en memoria en un `MockPlanStore`, que `MockVisitRepository` aplica a la ruta. Al cerrar la app por completo vuelve el plan original |
| `application/plan_actions.dart` | `PlanActions.save`. Después de guardar, la ruta se vuelve a pedir |
| `providers/plan_providers.dart` | `planActionsProvider` y `jobPlanProvider(jobId)` (el plan vigente) |

### Por validar (ingeniero)

El ingeniero revisa los trabajos terminados por otros técnicos y los valida, los regresa con nota o dictamina la causa de una garantía.

```mermaid
flowchart TD
    A["Lista: GET /api/review"] --> B["Detalle: notas, fotos, extras, plan"]
    B -->|"Validar"| C{"canValidate"}
    C -->|"sí"| D["POST review: validated"]
    C -->|"garantía sin dictaminar"| E["Dictaminar causa"]
    E -->|"POST review: verdict"| B
    B -->|"Regresar con nota"| F{"canReturnJob: nota no vacía"}
    F -->|"sí"| G["POST review: returned<br/>el servidor genera la solicitud para el jefe de ruta"]
```

**No pasa por la cola:** necesita señal, así que va directo al repositorio. Por eso no hay eventos nuevos ni casos nuevos en `applyEvents`.

| Archivo | Qué hace |
|---|---|
| `domain/models/review_models.dart` | `ReviewJob`, `ReviewPhoto`, `ReviewExtra`, `ReviewWarranty` |
| `domain/review_rules.dart` | `canValidate` (sin dictamen pendiente) y `canReturnJob` (nota obligatoria) |
| `data/repositories.dart` | Interfaz `ReviewRepository` |
| `data/mock/mock_repositories.dart` | `MockReviewRepository`: lee `assets/mock/review.json` y guarda los cambios en memoria |
| `application/review_actions.dart` | `validate`, `returnJob`, `submitVerdict`. Tras cada una, la lista se vuelve a pedir |
| `providers/review_providers.dart` | `reviewListProvider`, `reviewJobProvider(id)`, `reviewActionsProvider` |
| `features/review/` | Lista (F1), detalle (F2), nota al regresar (F2b), dictamen (F3) y `widgets/photo_strip.dart` |

### Mis trabajos (técnico)

El técnico ve los trabajos que ya terminó y qué decidió el ingeniero: **Por validar**, **Validado** o **Regresado**. En los regresados, la nota del ingeniero va en un recuadro rojo destacado. Es solo lectura y no pasa por la cola.

| Archivo | Qué hace |
|---|---|
| `domain/models/my_job_models.dart` | `MyJob`, `MyJobStatus` (un valor desconocido cae en Por validar) y `sortMyJobs` (regresados, por validar, validados; lo más reciente primero) |
| `data/repositories.dart` | Interfaz `MyJobsRepository` |
| `data/mock/mock_repositories.dart` | `MockMyJobsRepository`: lee `assets/mock/my_jobs.json` |
| `providers/my_jobs_providers.dart` | `myJobsProvider` (ya ordenado; se vuelve a pedir al cambiar de sesión o al jalar para actualizar) |
| `features/my_jobs/my_jobs_screen.dart` | Lista con etiqueta de estado y la nota destacada |

Los datos de prueba no cambian cuando el ingeniero valida o regresa en Por validar: son listas independientes hasta que exista la API.

## Cómo agregar cosas

### Un evento nuevo del técnico

1. **Nombre:** una constante en `EventTypes` (`domain/events/event_types.dart`).
2. **Clase:** una clase `...Event` en `domain/events/event_data.dart`, con sus datos tipados, `toPayload()` y `fromPayload()`; y una línea en `EventData.parse`.
3. **Estado:** el compilador marcará el `switch` de `applyEvents` hasta que agregues el caso (aunque sea "no cambia el estado").
4. **Regla** (si hay decisiones): una función pura en `domain/`, con su prueba.
5. **Ejemplo:** agrégalo a la lista de `test/events_test.dart` (la prueba "hay un ejemplo por cada tipo" avisa si falta).
6. **Acción:** un método en la clase del área en `application/` (`departure`, `arrival`, `noAnswer`, `extras` o `closing`), con `PendingEvent(MiEvento(...), visitId: ...)`. Usa `_writer.undoable([...])` para acciones deslizables o con formulario, y `_writer.instant(...)` para botones normales.
7. **Pantalla:** `runUndoable(context, ref, action: (a) => a.<área>.<método>(...), message: '...', after: AfterSave.pop)`.
8. **Contrato:** documenta los datos en `docs/contrato_api.md`.

Lo que se guarda y viaja al servidor es siempre el mapa de `toPayload()`; la app nunca reescribe lo ya guardado.

### Una acción que necesita señal (no pasa por la cola)

Como las del ingeniero en Por validar:

1. Un método en la interfaz del repositorio (`data/repositories.dart`) y su versión de prueba.
2. La regla en `domain/`, y el método en una clase de `application/` que la aplique.
3. Un provider que avise cuando algo cambió para volver a pedir la lista.
4. La pantalla guarda `messenger` y `navigator` antes del `await`, bloquea el botón mientras envía y avisa si no hay conexión.
5. Documenta la ruta en el contrato.

### Una pantalla nueva

Una pantalla que solo **compone** secciones; cada sección lee lo que necesita con `ref.watch`. Usa `AppCard`, `toast`, `formatNumber` y `AppImage` en lugar de repetir código.

## Pruebas

`flutter test` corre, entre otras:

| Prueba | Qué vigila |
|---|---|
| `models_test` | Que los mocks cumplen el contrato |
| `outbox_test` | La cola: `enqueue`, `undo`, `releaseExpired`, `nextBatch` |
| `settings_store_test`, `route_store_test` | Guardado local de parámetros y de la ruta |
| `visit_state_test`, `events_test` | `applyEvents` y los eventos tipados (un ejemplo por tipo) |
| `no_answer_test`, `extras_test`, `closing_test`, `arrival_rules_test` | Las reglas puras de cada área |
| `visit_actions_test`, `media_repository_test` | Las acciones y las fotos |
| `review_test` | Por validar: modelos, reglas y acciones |
| `my_jobs_test` | Mis trabajos: el mock, el estado desconocido y el orden |
| `plan_test` | Editar el plan: reglas, ida y vuelta del JSON y la acción de guardar |
| `format_test` | Formato de números |
| `input_formatters_test` | Los filtros de los campos descartan letras y signos, y respetan el largo |
| `architecture_test` | Las 5 reglas de dependencias por capa |

## Pendiente

- **Paso 6:** Jefe de ruta (Rutas).
- **Paso 7:** "Llegué" automático por geocerca y notificaciones push (Firebase).
- **Paso 8:** API real, envío de la cola, subida y compresión de fotos.
- **Pantallas sueltas:** Avisos, permisos de ubicación, sesión expirada.
- **Por confirmar con la empresa:** `credit_authorization_wait_min` (¿5 o 15 minutos?).
