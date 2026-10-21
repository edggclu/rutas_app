# Telyser · App de campo para técnicos

Documentación del proyecto de Ingeniería de Software

**Autor:** [Tu nombre] · **Fecha:** 20 de octubre de 2026 · **Versión de la app:** 0.1.0 (versión básica, Android)

## 1. Introducción

### 1.1 El problema

Telyser instala y da mantenimiento a sistemas de seguridad y tecnología: cámaras (CCTV), alarmas, redes, sonido, control de acceso y reparación de computadoras. Sus clientes son hoteles, restaurantes, condominios, casas y villas en Puerto Vallarta, Nuevo Vallarta, Bahía de Banderas y Punta de Mita.

Hoy el trabajo de campo se coordina por WhatsApp y de memoria. Eso provoca:

- técnicos que llegan sin el material o la herramienta correctos;
- trabajos detenidos sin que nadie sepa por qué ni quién debe resolverlos;
- extras que se hacen en sitio y nunca se cobran;
- material que sale del inventario y nunca se descuenta.

### 1.2 La solución

Una aplicación móvil para el día del técnico: qué le toca, en qué orden y con qué material; registrar lo que pasa en cada visita; y avisar a la persona correcta cuando algo lo detiene, sin mensajes aparte.

### 1.3 Criterio de “versión básica lista”

La versión básica estará lista cuando un técnico y el jefe de ruta hagan todas sus visitas en la app, sin anotar nada aparte, y se recorran de punta a punta cinco escenarios:

1. Instalación de varios días (por ejemplo, 8 cámaras en un hotel, en dos días).
2. Correctivo urgente (por ejemplo, un rayo quemó las cámaras de una casa).
3. Preventivo (mantenimiento programado por una póliza).
4. Garantía (algo que Telyser instaló falló).
5. Visita fallida (el técnico llegó y nadie abrió).

### 1.4 Alcance y estado actual

El servidor de Telyser (Laravel) todavía no tiene la API para esta app, por lo que la versión actual funciona con **datos de prueba**. La app ya está construida para conectarse después sin reescribir las pantallas.

| Módulo | Estado |
|---|---|
| Inicio de sesión, Mi día, Salida, tarjeta de visita | Implementado |
| Llegué manual con ubicación y “¿Ya te abrieron?” | Implementado |
| “No me abren”: cuenta regresiva, intentos de contacto y salida | Implementado |
| En sitio: fotos, extras y solicitudes para después | Implementado |
| Garantía y cierre: terminar, “Sigo otro día”, “No pude seguir” | Implementado |
| Funcionamiento sin señal (cola local y deshacer) | Implementado |
| Plan del trabajo y “Por validar” (ingeniero) | Pendiente; diseñado en Figma |
| Pantalla del jefe de ruta | Pendiente; diseñada en Figma |
| “Llegué” automático (geocerca) y notificaciones push | Pendiente |
| Conexión con la API real y envío de la cola | Pendiente |

## 2. Usuarios, roles y permisos

Es **una sola app**: lo que ve cada persona depende de su rol y sus permisos.

| Rol o permiso | Pestañas | Quién |
|---|---|---|
| Técnico | Mi día · Avisos | Técnicos de campo |
| + Ingeniero | agrega Por validar | Ingenieros |
| + Coordina rutas | agrega Rutas | Jefe de ruta |

Toño, jefe de ruta e ingeniero, tiene los tres y ve las cuatro pestañas. Administración, contabilidad y dirección usan la web interna y no esta app. Para las pruebas existen dos usuarios (con cualquier contraseña): `pedro`, técnico, y `tono`, técnico con los dos permisos. Las pestañas Rutas, Por validar y Avisos están diseñadas en el prototipo de Figma (40 pantallas) y se construirán en los pasos siguientes.

*Figura 1. [Captura: pestañas de Toño con sus cuatro opciones]*

## 3. Funcionalidad

Cada sección describe qué hace la pantalla y qué reglas del negocio aplica. Las líneas marcadas como “Figura” son para las capturas; la lista completa está en el Anexo A.

### 3.1 Inicio de sesión

El técnico entra con usuario o teléfono y contraseña; el error se muestra en la misma pantalla. “¿Olvidaste tu contraseña?” explica que no hay recuperación automática y que debe contactar a Administración.

*Figura 2. [Captura: pantalla de inicio de sesión]*

### 3.2 Mi día

Muestra la ruta del día en el orden que puso el jefe. Cada tarjeta indica el lugar, el tipo de trabajo (instalación, correctivo o preventivo), si es urgente, la cobertura (garantía o póliza), el folio (TEL-AAMM-NNN), “Día N” en instalaciones de varios días y la hora de cita.

- El **estado del técnico** (En camino a…, En sitio en…, Libre) nunca lo marca nadie: se calcula del estado de sus visitas.
- Las visitas hechas se atenúan y pasan al final.
- Mientras todas estén por hacer, aparece “Preparar salida”.

*Figura 3. [Captura: Mi día con las tres visitas]*

### 3.3 Salida

Antes de salir, el técnico revisa la lista de material y herramienta de cada visita, tomada del plan del ingeniero o, si no hay plan, de la cotización. Si le falta algo, toca el renglón (queda en ámbar como “Me falta”) y el aviso llega a Axel y al jefe **antes** de que salga. Al deslizar “Llevo todo”, la primera visita pasa a En camino.

*Figura 4. [Captura: Salida con un renglón marcado como “Me falta”]*

### 3.4 Botones deslizables y deshacer

Todo lo que cambia el estado de una visita (Llevo todo, Llegué, No me atendieron, Terminé, No lo terminé, Sigo otro día) se confirma **deslizando**, para que no se active con el teléfono en la bolsa. Después hay **10 segundos para deshacer**, valor que viene de los parámetros del servidor. Si se deshace, el estado regresa solo.

*Figura 5. [Captura: barra “Marcaste Llegué · quedan 7 s · Deshacer”]*

### 3.5 Tarjeta de visita

Reúne lo necesario para llegar y saber qué hacer: dirección con botón para abrir Maps o Waze, contacto con botones de llamar y WhatsApp, notas de acceso, descripción del trabajo y resumen del plan. Si el cliente tiene saldo vencido muestra un aviso **sin montos**; si es garantía, la guía de garantía.

*Figura 6. [Captura: tarjeta de visita del Hotel Bahía]*

### 3.6 Llegué y “¿Ya te abrieron?”

Al deslizar “Llegué”, la app lee la ubicación **una sola vez**, guarda la hora y el lugar, y la visita pasa a En sitio. Si no hay GPS o permiso, la llegada se marca igual. Después pregunta si ya le abrieron: **Empezar** o **No me abren**.

*Figura 7. [Captura: panel “¿Ya te abrieron?”]*

### 3.7 “No me abren”

Avisa a la oficina (una sola vez) y arranca una cuenta regresiva de **10 minutos más 1 minuto por kilómetro** desde el lugar anterior; esos valores vienen del servidor. La cuenta se calcula siempre desde la hora de llegada guardada, nunca con un temporizador en memoria: si el teléfono se bloquea, sigue bien.

El técnico puede llamar o mandar WhatsApp al cliente y llamar a la oficina; cada toque queda registrado como intento. El deslizable **“No me atendieron”** se activa solo cuando se cumplen las tres condiciones: terminó la espera, intentó contactar al cliente y llamó a la oficina. Al deslizarlo, la visita queda hecha y la siguiente pasa a En camino.

*Figura 8. [Captura: pantalla “No me abren” con la cuenta regresiva y los tres requisitos]*

### 3.8 En sitio

Pantalla de trabajo durante la visita: hora de llegada, acompañantes, fotos de avance, botones de extras y solicitudes, la tarjeta de garantía (si aplica) y la barra de cierre. Las fotos se copian a una carpeta propia de la app y quedan pendientes de subir (reloj ámbar; nube verde cuando se suban). Solo el técnico **responsable** ve los botones de cierre; un acompañante solo sube fotos.

*Figura 9. [Captura: En sitio con fotos, extras y solicitudes]*

### 3.9 Extras y solicitudes para después

Un **extra** es algo que no estaba en el trabajo y se hizo en la visita. Al guardarlo, la app aplica las reglas del negocio:

| Situación | Resultado |
|---|---|
| Lo pide el contacto autorizado y el cliente está al corriente | Se hace y se anota como extra |
| Lo pide otra persona (por ejemplo, el guardia) | No se hace; queda como solicitud para después |
| El cliente tiene saldo vencido y el extra es equipo | No se agrega; queda como solicitud para después |
| Va a retrasar las siguientes visitas | Se registra y se avisa al jefe de ruta |
| Cable, canaleta o tubo | Se anota igual; el servidor lo marca como absorbido por Telyser |

Una **solicitud para después** es algo que el cliente pidió y no se puede hacer en esa visita; lleva descripción, quién la pidió y fotos, y administración la cotiza como trabajo nuevo. Al elegir un producto del catálogo se muestra su precio aproximado.

*Figura 10. [Captura: formulario “Agregar extra”]*

*Figura 11. [Captura: aviso “Se guardó como solicitud”]*

### 3.10 Garantía

En una visita de garantía el técnico documenta y **no le promete nada al cliente**: la causa (defecto, humedad o salitre, golpe, variación eléctrica, manipulación o “no se sabe”), una foto de la falla y el número de serie (escrito o en foto de la etiqueta). Si la causa es claramente externa (golpe o manipulación), la app indica llamar a la oficina antes de reparar, porque probablemente se cobre. Mientras no documente la garantía, el deslizable de terminar permanece bloqueado. Quién decide si procede queda fuera de la app.

*Figura 12. [Captura: pantalla de garantía]*

### 3.11 Cierre de la visita

- **Terminé el trabajo.** Si hubo extras, se muestra su lista y el contacto autorizado los confirma escribiendo su nombre. Sin extras, cierra directo.
- **No lo terminé** pregunta qué pasó:
  - **Sigo otro día:** material usado (la lista viene llena y se ajusta con + y −), qué se queda en el sitio, qué falta (obligatorio, para que otro técnico pueda continuar) y, si se tendió cable, un video del cableado antes de que lo tapen.
  - **No pude seguir:** algo lo detuvo y alguien debe resolverlo. Elige un motivo y escribe una nota. Elegir el motivo ya avisa a quien corresponde, sin mensajes aparte.

| Motivo | A quién se avisa |
|---|---|
| Falta material o herramienta | Axel y el jefe de ruta |
| El sitio no es como el plan | Ingeniero a cargo |
| No puedo resolverlo | Jefe, ingeniero y administración |
| Cliente: pago, garantía o inconformidad | Administración |
| Incidente: seguridad, daño o accidente | Administración |
| Otro | Jefe de ruta |

Casos especiales: en un **accidente** la app pide primero ayuda (emergencias u oficina); en **daño a la propiedad** exige fotos antes de enviar; en **“No puedo resolverlo”** ofrece pedir ayuda al ingeniero por WhatsApp con el mensaje ya escrito, porque eso puede ahorrar otra visita.

Por qué hay dos caminos: en “Sigo otro día” nadie tiene que hacer nada; en “No pude seguir” sí. Si ambos fueran “pausado”, el jefe vería diez pausados y no sabría cuáles resolver hoy.

*Figura 13. [Captura: confirmación de extras al terminar]*

*Figura 14. [Captura: pregunta “¿Qué pasó?” de No lo terminé]*

*Figura 15. [Captura: pantalla “Sigo otro día”]*

*Figura 16. [Captura: pantalla “No pude seguir” con los motivos]*

### 3.12 Funcionamiento sin señal

El técnico puede estar en una villa sin datos. Por eso la ruta del día queda guardada en el teléfono y **todo lo que hace se guarda primero en el teléfono**, con un identificador único y la hora real en que pasó, y se enviará en orden cuando haya señal. Si cierra la app o se apaga el teléfono, no se pierde nada, y el estado de las visitas se recalcula al volver a abrirla. En esta versión el envío al servidor aún no existe (ver sección 6).

## 4. Diseño de la base de datos

### 4.1 Enfoque

El servidor de Telyser (el CRM en Laravel) es la **fuente de verdad** de clientes, lugares, trabajos, catálogo y cotizaciones. El teléfono **no replica** esas tablas: guarda lo mínimo para trabajar el día sin señal.

- Cada visita llega con su cliente, lugar, contacto, trabajo y lista de salida anidados en un JSON, y se guarda completa en una sola columna. Si el servidor agrega un campo, no hace falta migrar la base del teléfono.
- Lo que la app **genera** (llegadas, extras, cierres) se guarda en una cola de acciones.
- La base es SQLite (archivo `telyser.sqlite` dentro del teléfono), manejada con la librería Drift.

*Figura 17. [Diagrama entidad-relación de la base local]*

### 4.2 Tablas

**settings_kv**: parámetros que descarga la app.

| Columna | Descripción |
|---|---|
| key (clave primaria) | Nombre del parámetro |
| value | Valor guardado como JSON |

**cached_visits**: la ruta del día, para verla sin señal.

| Columna | Descripción |
|---|---|
| id (clave primaria) | Identificador de la visita |
| date | Fecha de la ruta (AAAA-MM-DD) |
| order_in_route | Orden en la ruta |
| status, result | Estado y resultado tal como los dio el servidor |
| json | La visita completa tal como llegó |
| arrived_at_utc, arrival_lat, arrival_lng | Hora y lugar de llegada |

**outbox_events**: la cola de acciones por enviar.

| Columna | Descripción |
|---|---|
| seq (clave primaria) | Número consecutivo; define el orden de envío |
| uuid (único) | Identificador generado en el teléfono; evita duplicados |
| type | Tipo de acción (llegué, terminé…) |
| visit_id | Visita a la que pertenece |
| occurred_at_utc, tz | Hora real en que pasó y zona horaria |
| payload_json | Datos de la acción |
| state | grace · pending · sending · failed |
| grace_until_utc | Fin de los segundos para deshacer |
| attempts, last_error | Reintentos y último error |

**media_queue**: fotos y videos pendientes de subir.

| Columna | Descripción |
|---|---|
| uuid (clave primaria) | Identificador del archivo |
| visit_id | Visita |
| kind | progress · warranty · warranty_serial · damage · request · cabling_video |
| local_path | Dónde quedó guardado en el teléfono |
| wifi_only | Los videos esperan Wi-Fi |
| state, created_at_utc | Estado de subida y hora en que se tomó |

Las relaciones por `visit_id` son lógicas: Drift no declara llaves foráneas en este esquema, así que la base no impide guardar un `visit_id` que no exista en `cached_visits`.

### 4.3 Ciclo de vida de una acción

1. **grace**: se guardó y hay 10 segundos para deshacer; todavía no se puede enviar. Deshacer es borrar la fila.
2. **pending**: pasó el tiempo y está lista para enviarse.
3. **sending**: va en camino al servidor.
4. **failed**: falló y se reintenta.

La cola respeta el orden: si una acción sigue en gracia, las que vienen después no se envían antes. Si el teléfono reintenta algo que sí había llegado, el servidor lo ignora por su `uuid`.

### 4.4 El estado se calcula, no se guarda

El estado de una visita es **el estado que dio el servidor más las acciones de la cola**, recalculado cada vez. Por eso deshacer es borrar una fila, el estado sobrevive a cerrar la app, y las pantallas nunca cambian el estado directamente: solo agregan acciones.

### 4.5 Parámetros del servidor

Las reglas que pueden cambiar por decisión de la empresa no están escritas en el código: se descargan al iniciar y se guardan en `settings_kv`.

| Parámetro | Valor inicial |
|---|---|
| Segundos para deshacer | 10 |
| Espera de “No me abren” | 10 min + 1 min por km |
| Intentos mínimos: cliente y oficina | 1 y 1 |
| Radio y permanencia para “Llegué” automático | 150 m y 60 s |
| Tamaño de foto y duración máxima de video | unos 300 KB y 60 s |

### 4.6 Tipos de acción que guarda la cola

| Tipo | Cuándo | ¿Cambia el estado? |
|---|---|---|
| departure_confirmed | Confirma la salida | Primera visita: En camino |
| missing_items | Marca lo que le falta al salir | No |
| arrived | Marca Llegué | En sitio |
| no_answer_reported | Toca “No me abren” | No |
| client_contacted | Llama o manda WhatsApp al cliente | No |
| office_called | Llama a la oficina | No |
| no_answer_confirmed | Desliza “No me atendieron” | Hecha (no atendieron) |
| finished | Termina el trabajo | Hecha (terminada) |
| continue_tomorrow | “Sigo otro día” | Hecha (continúa) |
| blocked | “No pude seguir” | Hecha (detenida) |
| extra_added | Registra un extra | No |
| request_added | Solicitud para después | No |
| route_delay_reported | Un extra retrasa las visitas | No |
| warranty_documented | Documenta la garantía | No (habilita terminar) |
| help_requested | Pide ayuda al ingeniero | No |

Las horas se guardan en UTC y se muestran en hora del centro de México.

## 5. Arquitectura

### 5.1 Visión general

App nativa para Android escrita en **Flutter (Dart)**. Usa **Riverpod** para el estado, **Drift/SQLite** para la base local, `geolocator` para la ubicación, `image_picker` para fotos y video y `url_launcher` para abrir Maps, el teléfono y WhatsApp. El servidor será el Laravel de Telyser, con una API JSON.

### 5.2 ¿Es MVC?

**No es MVC clásico.** Es una **arquitectura en capas con flujo de datos unidireccional y estado reactivo**, más cercana a MVVM y a una Clean Architecture simplificada. La razón: en Flutter las pantallas son declarativas (se redibujan solas cuando cambia el estado), así que no existe un controlador que actualice la vista a mano.

Si la materia pide relacionarlo con MVC, esta es la equivalencia aproximada:

| MVC | En esta app | Qué hace |
|---|---|---|
| Modelo | `domain/` y `data/` | Modelos, reglas del negocio y persistencia |
| Vista | `features/` y `core/` | Pantallas y widgets |
| Controlador | `application/` y `providers/` | Reciben lo que hace el técnico y exponen el estado a las pantallas (el papel de un ViewModel) |

Diferencias importantes: la vista **no modifica el estado**, solo pide una acción y observa el resultado; las reglas del negocio viven en `domain/` y no en el controlador; y el flujo siempre va en una dirección.

### 5.3 Capas y regla de dependencias

Las dependencias solo van hacia adentro: pantallas → providers → acciones → dominio. La capa de datos implementa contratos del dominio.

| Capa | Qué contiene | No puede depender de |
|---|---|---|
| `domain/` | Modelos, eventos y reglas en Dart puro | Flutter, Drift ni otra capa |
| `application/` | Qué pasa cuando el técnico hace algo, una clase por área | Pantallas, Flutter, providers |
| `data/` | Drift, repositorios (de prueba hoy, API mañana) | Pantallas, providers, application |
| `providers/` | Conecta todo con Riverpod, un archivo por tema | — |
| `features/` | Pantallas y sus widgets | Drift ni `data/` |
| `core/` | Widgets y utilidades genéricas | El negocio |

*Figura 18. [Diagrama de capas y dependencias]*

Esta regla no es solo una convención: hay pruebas automáticas que revisan los imports de cada capa y fallan si alguien la rompe.

### 5.4 Ejemplo: qué pasa al deslizar “Llegué”

1. La pantalla llama a una acción y no cambia nada por su cuenta.
2. La acción de llegada lee la ubicación una vez.
3. Se guarda el evento “llegué” en la cola, con su UUID, su hora y el estado de gracia.
4. La base de datos avisa que la cola cambió.
5. El estado de la ruta se recalcula: ruta del servidor más acciones de la cola.
6. La pantalla se redibuja sola: la visita está En sitio y aparece “¿Ya te abrieron?”.
7. Si el técnico toca Deshacer, se borra la fila, se recalcula y todo regresa.

### 5.5 Patrones y decisiones de diseño

- **Repositorio**: las pantallas nunca hablan con la API; usan interfaces con una implementación de prueba y otra real, intercambiables. Conectar el servidor es cambiar unas líneas.
- **Cola de salida (outbox)**: nada se envía directo; se guarda y otro proceso lo envía. Es la base del funcionamiento sin señal.
- **Estado derivado de eventos**: el estado es servidor más eventos, parecido a event sourcing ligero. Hace trivial deshacer y recuperarse tras cerrar la app.
- **Eventos tipados**: cada evento es una clase con sus datos, y el cálculo del estado usa un `switch` sin caso por defecto: si se agrega un evento nuevo, el compilador obliga a decidir qué hace con el estado.
- **Un caso de uso por área**: salida, llegada, “No me abren”, extras y cierre, con un ayudante común que guarda en la cola.
- **Idempotencia**: el UUID evita duplicados al reintentar.
- **Parámetros externos**: nada que la empresa pueda cambiar está fijo en el código.
- **Lectura tolerante**: un evento desconocido o incompleto nunca rompe la ruta.

### 5.6 Calidad y pruebas

El proyecto tiene pruebas automatizadas de: modelos y contrato de datos, reglas del negocio (extras, “No me abren”, cierre, estado de la visita), eventos (cada evento genera exactamente el JSON esperado y se lee de vuelta), la cola (gracia, deshacer y orden), el almacenamiento local (parámetros, ruta y fotos, con una base en memoria), las acciones del técnico y la arquitectura. Hay además una prueba de widget del inicio de sesión.

Al crecer, el código se refactorizó en pasos pequeños, cada uno con las pruebas en verde: se separaron los providers por tema, las acciones por área y los eventos en clases, y se eliminó el esqueleto de “guardar y deshacer” que estaba copiado en nueve pantallas.

## 6. Limitaciones y trabajo futuro

| Paso | Qué falta |
|---|---|
| 5 | Plan del trabajo (con croquis y pines) y “Por validar” del ingeniero: validar, regresar con nota y dictamen de causa |
| 6 | Pantalla del jefe de ruta: decisiones, “Hoy”, “Por asignar”, crear y mover visitas |
| 7 | “Llegué” automático con geocerca y notificaciones push |
| 8 | API real de Laravel, envío de la cola y subida de fotos, y pruebas sin señal en campo |

También faltan: la pantalla de permisos, avisos, “Mis trabajos”, notas de voz y la autorización de administración por saldo vencido (necesita servidor).

**Preguntas abiertas para la empresa:** qué más capturar en la garantía; cómo expresar el cable si el catálogo solo maneja pieza y servicio; si la espera por saldo vencido son 5 o 15 minutos (el documento de requisitos dice ambos); si el técnico necesita buscar productos y precios sin señal; y si hay un mínimo de fotos por tipo de trabajo.

## Anexo A. Lista de capturas

| Figura | Pantalla | Cómo llegar |
|---|---|---|
| 1 | Pestañas de Toño | Entrar como `tono` |
| 2 | Inicio de sesión | Abrir la app sin sesión |
| 3 | Mi día | Entrar como `pedro` |
| 4 | Salida | “Preparar salida”; tocar “Escalera de 6 m” |
| 5 | Barra de deshacer | Deslizar cualquier botón |
| 6 | Tarjeta de visita | Tocar el Hotel Bahía |
| 7 | “¿Ya te abrieron?” | Deslizar “Llegué” |
| 8 | “No me abren” | Tocar “No me abren” en el panel |
| 9 | En sitio | “Empezar”, con una foto tomada |
| 10 | Agregar extra | “+ Extra” |
| 11 | Aviso de solicitud | Guardar un extra pedido por “Otra persona” |
| 12 | Garantía | Visita del restaurante (garantía) |
| 13 | Confirmación de extras | Deslizar “Terminé” con un extra registrado |
| 14 | ¿Qué pasó? | Deslizar “No lo terminé” |
| 15 | Sigo otro día | Opción “Sigo otro día” |
| 16 | No pude seguir | Opción “No pude seguir” |
| 17 | Base de datos | Diagrama entidad-relación |
| 18 | Capas | Diagrama de arquitectura |

Para capturar desde la computadora: `adb exec-out screencap -p > captura.png`. En el teléfono: botón de encendido + bajar volumen.

