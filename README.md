# Telyser · App de campo (Flutter)

Paso 1 del orden de construcción: **Login, Mi día y tarjeta de visita, con datos de prueba.**

## Cómo arrancar
1. Dentro de esta carpeta, genera los archivos de Android (no sobrescribe `lib/`):
   ```
   flutter create --platforms=android --project-name telyser_app .
   ```
2. `flutter pub get`
3. `flutter test` (prueba que `assets/mock/my_day.json` cumple el contrato)
4. `flutter run`

Usuarios de prueba (cualquier contraseña):
- `pedro` (o cualquier otro): técnico. Pestañas Mi día y Avisos.
- `tono`: técnico + ingeniero + coordina rutas. Pestañas Mi día, Rutas, Por validar y Avisos.

## Android: lo que hay que agregar a mano
En `android/app/src/main/AndroidManifest.xml`, dentro de `<manifest>` y fuera de `<application>`,
para que `url_launcher` pueda abrir mapas, teléfono y WhatsApp en Android 11 o más:
```xml
<queries>
  <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="https"/></intent>
  <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="geo"/></intent>
  <intent><action android:name="android.intent.action.DIAL"/><data android:scheme="tel"/></intent>
</queries>
```
La fuente Inter no está incluida: agrega los `.ttf` en `assets/fonts/`, decláralos en
`pubspec.yaml` y pon `fontFamily: 'Inter'` en `lib/core/theme/app_theme.dart`.

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
**Regla de arquitectura:** las pantallas nunca llaman a la API. Usan los repositorios; conectar
la API real es cambiar dos líneas en `lib/data/providers.dart`.

## Qué falta (siguientes pasos)
2. Salida ("Llevo todo"), Llegué manual, cola local con Drift y 10 s para deshacer.
3. No me abren (espera, llamadas, "No me atendieron").
4. Extras, solicitudes y garantía.
5. Plan y Por validar (ingeniero).
6. Pantalla del jefe de ruta.
7. Llegué automático (geocerca) y notificaciones push.
8. API real y pruebas sin señal.

## Aviso
Este código se escribió sin poder compilarlo (no había SDK de Flutter disponible).
Si `flutter run` o `flutter analyze` marcan errores, probablemente sean detalles menores
de sintaxis o de versión de paquetes: pásalos tal cual para corregirlos.
