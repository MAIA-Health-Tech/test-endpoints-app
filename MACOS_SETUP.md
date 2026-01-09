# Guía de Instalación y Debug en macOS

Guía completa para instalar y debuggear la app MAIA Test Endpoints en macOS, diseñada para backend developers.

## ⚡ Instalación Rápida (30 minutos)

### Paso 1: Instalar Homebrew (si no lo tienes)

```bash
# Instalar Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Verificar instalación
brew --version
```

### Paso 2: Instalar Flutter

```bash
# Descargar Flutter
cd ~
git clone https://github.com/flutter/flutter.git -b stable

# Agregar Flutter al PATH
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.zshrc

# Recargar terminal
source ~/.zshrc

# Verificar instalación
flutter doctor
```

**Nota**: Verás algunos warnings en rojo. No te preocupes por todos, solo necesitamos configurar lo básico.

### Paso 3: Aceptar Licencias de Android

```bash
# Instalar herramientas de línea de comandos
flutter doctor --android-licenses

# Acepta todas las licencias presionando 'y' cuando te lo pida
```

### Paso 4: Clonar el Proyecto

```bash
# Clonar el repositorio
cd ~/Desktop  # o donde quieras trabajar
git clone https://github.com/MAIA-Health-Tech/test-endpoints-app.git
cd test-endpoints-app

# Instalar dependencias
flutter pub get
```

## 📱 Opciones para Ejecutar la App

### Opción A: Usando tu iPhone (Recomendado si tienes iPhone)

#### Requisitos:
- Mac con macOS 12.0 o superior
- iPhone con iOS 12.0 o superior
- Cable USB-C a Lightning (o Lightning a USB-A)
- Cuenta de Apple (gratis)

#### Pasos:

1. **Instalar Xcode** (esto toma tiempo, descarga de ~10GB):
```bash
# Opción 1: Desde App Store (recomendado)
# Abre App Store y busca "Xcode", instala

# Opción 2: Desde línea de comandos
xcode-select --install
```

2. **Configurar Xcode**:
```bash
# Una vez instalado Xcode
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch

# Aceptar licencias
sudo xcodebuild -license accept
```

3. **Configurar tu iPhone**:
   - Conecta el iPhone al Mac con el cable
   - En el iPhone: Ve a **Ajustes > Privacidad y Seguridad > Modo Desarrollador** → Actívalo
   - El iPhone se reiniciará
   - Después del reinicio, confirma que quieres activar Modo Desarrollador

4. **Confiar en tu Mac desde el iPhone**:
   - Conecta el iPhone al Mac
   - En el iPhone verás un mensaje "¿Confiar en esta computadora?"
   - Toca **Confiar** e ingresa tu PIN

5. **Verificar que Flutter ve tu iPhone**:
```bash
flutter devices
```

Deberías ver algo como:
```
iPhone de Felipe (mobile) • 00008030-001234567890ABCD • ios • iOS 17.1.1
```

6. **Ejecutar la app**:
```bash
cd ~/Desktop/test-endpoints-app
flutter run
```

La primera vez tomará 5-10 minutos compilando. Verás mucha salida en la terminal.

### Opción B: Usando Simulador de iOS (Sin iPhone físico)

```bash
# Abrir simulador
open -a Simulator

# O desde Flutter
flutter emulators --launch apple_ios_simulator

# Verificar que Flutter lo ve
flutter devices

# Ejecutar la app
flutter run
```

### Opción C: Usando Android (Si tienes teléfono Android)

1. **Instalar Android Studio**:
```bash
brew install --cask android-studio
```

2. **Abrir Android Studio** y:
   - Ve a **More Actions > SDK Manager**
   - Instala "Android SDK Command-line Tools"
   - Instala "Android SDK Platform-Tools"

3. **Configurar Android en tu teléfono**:
   - Ve a **Ajustes > Acerca del teléfono**
   - Toca 7 veces en "Número de compilación"
   - Ve a **Ajustes > Opciones de desarrollador**
   - Activa "Depuración USB"

4. **Conectar teléfono y ejecutar**:
```bash
# Verificar dispositivo
flutter devices

# Ejecutar app
flutter run
```

## 🔍 Cómo Ver Logs y Debug

### Ver Logs en Tiempo Real

Cuando ejecutas `flutter run`, automáticamente verás todos los logs en la terminal:

```bash
flutter run
```

**Salida que verás:**

```
Launching lib/main.dart on iPhone de Felipe in debug mode...
Running Xcode build...
✓ Built build/ios/iphoneos/Runner.app.

🔌 WebSocket: Sending subscribe message: {"action":"subscribe","channel":"demo@maiaesthetics.ai","token":"eyJ..."}
🔵 RAW WebSocket message: {"ok":true,"action":"subscribed","channel":"demo@maiaesthetics.ai"}
📱 ✅ Notification patientId saved: patient-123
```

### Ver Solo Logs Importantes

Los logs de la app tienen emojis para identificarlos fácilmente:

```bash
# Filtrar solo logs con emojis (notificaciones, WebSocket, etc)
flutter run | grep -E "🔌|🔵|📱|⚠️|❌"
```

### Ver Logs Más Detallados

```bash
# Modo verbose - muestra TODO
flutter run --verbose

# Ver logs del dispositivo iOS
flutter logs

# En otra terminal mientras la app corre (iOS)
flutter logs | grep -E "🔌|🔵|📱"
```

### Ver Logs de Dispositivo Android (si usas Android)

```bash
# Instalar Android Debug Bridge
brew install android-platform-tools

# Ver logs completos
adb logcat

# Filtrar solo logs de Flutter
adb logcat | grep flutter

# Filtrar logs con emojis
adb logcat | grep -E "🔌|🔵|📱|⚠️|❌"
```

## 🐛 Debug Avanzado

### Hot Reload (Cambios Instantáneos)

Mientras la app corre, puedes hacer cambios al código y ver los resultados inmediatamente:

```bash
# En la terminal donde corre flutter run:
r  # Hot reload - aplica cambios sin reiniciar
R  # Hot restart - reinicia la app completamente
q  # Quit - cierra la app
```

### Inspeccionar Network Requests

Todos los requests HTTP se logean automáticamente. Verás:

```
POST http://maia.clinic/api/auth/login
Status: 200
Response: {"data":{"accessToken":"eyJ...","refreshToken":"...","user":{...}}}
```

### Inspeccionar WebSocket Messages

Verás todos los mensajes WebSocket con el emoji 🔵:

```
🔌 WebSocket: Sending subscribe message: {"action":"subscribe",...}
🔵 RAW WebSocket message: {"ok":true,"action":"subscribed",...}
🔵 Decoded message keys: [ok, action, channel]
📱 ✅ Notification patientId saved: patient-123
```

### Usar DevTools (Inspector Visual)

Flutter incluye herramientas de debug visuales:

```bash
# Ejecutar la app
flutter run

# En otra terminal, abrir DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

Abre en el navegador: http://127.0.0.1:9100

**DevTools te permite:**
- Ver el árbol de widgets (estructura de la UI)
- Inspector de red (todos los requests)
- Timeline (performance)
- Memory profiler
- Debugger (breakpoints)

### Breakpoints en VSCode

Si usas VSCode:

1. Instala la extensión "Flutter" de Dart Code
2. Abre el proyecto en VSCode
3. Pon breakpoints haciendo click a la izquierda del número de línea
4. Presiona F5 o ve a Run > Start Debugging
5. La app se ejecutará y se detendrá en los breakpoints

### Cambiar URLs del Backend

Para apuntar a un servidor diferente (local, staging, etc):

```bash
# Editar archivos de servicio
cd ~/Desktop/test-endpoints-app/lib/services

# Cambiar URL de autenticación
nano auth_service.dart
# Línea 6: final String baseUrl = 'http://maia.clinic/api';
# Cámbiala a: final String baseUrl = 'http://localhost:8081/api';

# Cambiar URL de pacientes
nano patient_service.dart
# Línea 5: Cambiar baseUrl

# Cambiar URL de upload
nano upload_service.dart
# Línea 6: Cambiar baseUrl

# Cambiar URL de WebSocket
nano websocket_service.dart
# Línea 8: final String wsUrl = 'ws://maia.clinic/ws';
# Cámbiala a: final String wsUrl = 'ws://localhost:8081/ws';
```

Después de cambiar URLs:
```bash
# Presiona 'R' en la terminal donde corre flutter run para reiniciar
R
```

## 📊 Monitorear Requests HTTP

### Opción 1: Logs de la App

Ya está implementado, solo ejecuta:
```bash
flutter run
```

Verás cada request:
```
POST http://maia.clinic/api/auth/login
Response: 200 OK
```

### Opción 2: Usar Proxy (Charles, Proxyman)

1. **Instalar Proxyman** (gratis para desarrollo):
```bash
brew install --cask proxyman
```

2. **Configurar Proxyman**:
   - Abre Proxyman
   - Ve a Certificate > Install Certificate on iOS > Simulator
   - Reinicia la app

3. **Ver todos los requests** en tiempo real en la UI de Proxyman

## 🔧 Troubleshooting en macOS

### Error: "xcrun: error: SDK not found"

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
```

### Error: "Could not find an option named 'android-licenses'"

```bash
flutter doctor --android-licenses
# Si no funciona, instala Android Studio primero
brew install --cask android-studio
```

### Error: "No devices found"

```bash
# Para iOS Simulator
open -a Simulator

# Para verificar dispositivos
flutter devices

# Si no aparece tu iPhone
# 1. Desconecta y vuelve a conectar el cable
# 2. En el iPhone: Ajustes > Privacidad > Modo Desarrollador > ON
# 3. Reinicia el iPhone
# 4. flutter devices
```

### Error: "CocoaPods not installed"

```bash
# Instalar CocoaPods
sudo gem install cocoapods
pod setup

# Actualizar pods del proyecto
cd ~/Desktop/test-endpoints-app/ios
pod install
cd ..
flutter run
```

### Error: "Gradle build failed" (Android)

```bash
flutter clean
flutter pub get
flutter run
```

### App muy lenta en Debug

Es normal. La versión debug incluye muchas herramientas. Para probar rendimiento real:

```bash
# Compilar en modo release (mucho más rápido)
flutter run --release
```

**Nota**: En release no verás logs en la terminal.

## 📱 Compilar APK para Android

Si quieres compartir con equipo que tiene Android:

```bash
# Compilar APK
flutter build apk --release

# El APK estará en:
# build/app/outputs/flutter-apk/app-release.apk

# Compartir por email/slack/drive
open build/app/outputs/flutter-apk/
```

## 📝 Comandos Útiles de Referencia Rápida

```bash
# Ver dispositivos disponibles
flutter devices

# Ejecutar app
flutter run

# Ejecutar con logs verbose
flutter run --verbose

# Ejecutar en dispositivo específico
flutter run -d "00008030-001234567890ABCD"

# Ver logs en tiempo real
flutter logs

# Limpiar proyecto (si hay problemas)
flutter clean
flutter pub get

# Hot reload (mientras corre)
r

# Hot restart (mientras corre)
R

# Quit app (mientras corre)
q

# Verificar instalación de Flutter
flutter doctor

# Ver versión de Flutter
flutter --version

# Actualizar Flutter
flutter upgrade

# Listar emuladores disponibles
flutter emulators

# Lanzar emulador específico
flutter emulators --launch apple_ios_simulator

# Compilar APK para Android
flutter build apk --release

# Abrir DevTools
flutter pub global run devtools
```

## 🎯 Flujo Típico de Testing

```bash
# 1. Abrir terminal
cd ~/Desktop/test-endpoints-app

# 2. Conectar iPhone o abrir Simulator
open -a Simulator

# 3. Verificar dispositivo
flutter devices

# 4. Ejecutar app (verás logs automáticamente)
flutter run

# 5. En otra terminal, filtrar logs importantes
flutter logs | grep -E "🔌|🔵|📱|⚠️|❌"

# 6. Usar la app en el dispositivo y observar logs en tiempo real

# 7. Si necesitas cambiar código:
#    - Edita el archivo
#    - Presiona 'r' en la terminal para hot reload

# 8. Para cerrar
#    - Presiona 'q' en la terminal
```

## 🆘 Ayuda

**Si algo no funciona:**

1. Ejecuta `flutter doctor` y lee los mensajes
2. Ejecuta `flutter clean && flutter pub get`
3. Revisa los logs con `flutter run --verbose`
4. Pregunta a Felipe

**Recursos útiles:**
- Flutter Docs: https://docs.flutter.dev
- Flutter DevTools: https://docs.flutter.dev/tools/devtools
- Dart Docs: https://dart.dev/guides

---

**Desarrollado por Felipe Lara** (felipe@lara.ac)

**Repo**: https://github.com/MAIA-Health-Tech/test-endpoints-app
