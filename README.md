# MAIA Test Endpoints App

App móvil de prueba para validar todos los endpoints de la API de MAIA. Diseñada para que el equipo de backend pueda probar sus endpoints sin necesidad de saber desarrollo móvil.

## Qué hace esta app

- **Login**: Prueba el endpoint de autenticación JWT
- **Gestión de Pacientes**: Lista y crea pacientes
- **Upload de Audio**: Sube archivos de audio con tipo (médico/recepción)
- **Notificaciones WebSocket**: Recibe notificaciones en tiempo real por email

## 📱 Instalación Rápida (Para Backend Devs)

### Opción 1: Usar APK Pre-compilado (MÁS FÁCIL)

Si alguien del equipo ya compiló la app, pídeles el archivo `.apk` y:

1. Transfiere el APK a tu teléfono Android
2. Abre el archivo APK en el teléfono
3. Android te pedirá permitir instalación de "fuentes desconocidas" - acepta
4. Instala la app
5. Listo! Salta a la sección "Cómo Usar la App"

### Opción 2: Instalar Flutter y Compilar (Toma 30 min)

#### Paso 1: Instalar Flutter

**Linux/Mac:**
```bash
# Descargar Flutter
cd ~
git clone https://github.com/flutter/flutter.git -b stable

# Agregar a PATH (añade esto a tu ~/.bashrc o ~/.zshrc)
export PATH="$PATH:$HOME/flutter/bin"

# Recargar terminal
source ~/.bashrc  # o source ~/.zshrc

# Verificar instalación
flutter doctor
```

**Windows:**
1. Descarga Flutter desde: https://docs.flutter.dev/get-started/install/windows
2. Extrae el ZIP en `C:\src\flutter`
3. Agrega `C:\src\flutter\bin` al PATH del sistema
4. Abre CMD y ejecuta: `flutter doctor`

#### Paso 2: Configurar Android (Solo si vas a probar en dispositivo físico)

**Opción A - USB Device (Recomendado):**
1. En tu teléfono Android:
   - Ve a Ajustes > Acerca del teléfono
   - Toca 7 veces en "Número de compilación" para activar modo desarrollador
   - Ve a Ajustes > Opciones de desarrollador
   - Activa "Depuración USB"
2. Conecta el teléfono con cable USB a tu PC
3. En el teléfono, acepta el mensaje de "Permitir depuración USB"
4. En la PC, verifica: `flutter devices` (debe aparecer tu teléfono)

**Opción B - Emulador Android:**
```bash
# Instalar Android Studio (necesario para el emulador)
# Descargar de: https://developer.android.com/studio

# Abrir Android Studio > Tools > Device Manager > Create Device
# Seleccionar cualquier teléfono (ej: Pixel 6)
# Descargar una imagen del sistema (recomendado: API 33)
# Crear y lanzar el emulador
```

#### Paso 3: Clonar y Ejecutar la App

```bash
# Clonar el repositorio
git clone https://github.com/MAIA-Health-Tech/test-endpoints-app.git
cd test-endpoints-app

# Instalar dependencias
flutter pub get

# Verificar que tu dispositivo está conectado
flutter devices

# Ejecutar la app (se instalará automáticamente en tu dispositivo)
flutter run
```

La primera vez tarda 2-5 minutos en compilar. Las siguientes veces es instantáneo con hot reload.

## 📲 Cómo Usar la App

### 1. Login

1. Abre la app
2. Verás la pantalla de login
3. Ingresa credenciales de prueba:
   - **Email**: demo@maiaesthetics.ai
   - **Password**: (pregunta al equipo)
4. Toca "Login"
5. Si funciona, verás la pantalla principal con 4 tabs

**Qué valida:**
- POST `http://maia.clinic/api/auth/login`
- Respuesta debe incluir: `accessToken`, `refreshToken`, `user.id`, `user.email`

### 2. Ver Pacientes

1. Ve al tab "Patients"
2. Verás la lista de pacientes existentes
3. Cada paciente muestra: nombre, email, teléfono

**Qué valida:**
- GET `http://maia.clinic/api/emr/patients`
- Header: `Authorization: Bearer <token>`

### 3. Crear Paciente

1. Ve al tab "Create Patient"
2. Llena el formulario:
   - Nombre
   - Email
   - Teléfono
3. Toca "Create Patient"
4. Si funciona, verás un mensaje de éxito

**Qué valida:**
- POST `http://maia.clinic/api/emr/patients`
- Header: `Authorization: Bearer <token>`
- Body: JSON con datos del paciente

### 4. Upload de Audio

1. Ve al tab "Upload"
2. Selecciona un paciente del dropdown
3. Selecciona el tipo de audio:
   - **Medical**: Consulta médica
   - **Reception**: Recepción/administrativa
4. Toca "Pick Audio File"
5. Selecciona un archivo de audio de tu teléfono
6. Toca "Upload"
7. Verás el progreso de upload
8. Si funciona, recibirás un `jobId`

**Qué valida:**
- POST `http://maia.clinic/api/patients/upload-conversation`
- Header: `Authorization: Bearer <token>`
- Content-Type: `multipart/form-data`
- Campos:
  - `patientId`: ID del paciente
  - `type`: "medical" o "reception"
  - `file`: archivo de audio (audio/mpeg)

### 5. Notificaciones WebSocket

1. Ve al tab "Notifications"
2. Verás el estado de conexión WebSocket
3. Si está verde "Connected to <email>", funciona correctamente
4. Las notificaciones aparecerán automáticamente aquí cuando el backend las envíe

**Qué valida:**
- WebSocket: `ws://maia.clinic/ws`
- Mensaje de suscripción:
  ```json
  {
    "action": "subscribe",
    "channel": "demo@maiaesthetics.ai",
    "token": "<jwt-token>"
  }
  ```
- Respuesta esperada:
  ```json
  {
    "ok": true,
    "action": "subscribed",
    "channel": "demo@maiaesthetics.ai"
  }
  ```

**Para probar notificaciones**, el backend debe enviar:
```json
{
  "action": "notification",
  "type": "transcription_complete",
  "patientId": "patient-123",
  "data": "{\"status\":\"completed\",\"jobId\":\"job-456\"}"
}
```

## 🔧 Troubleshooting

### "No devices found"
- **USB**: Verifica que depuración USB esté activada y cable conectado
- **Emulador**: Verifica que el emulador esté corriendo (`flutter devices` debe mostrarlo)

### "Gradle build failed"
```bash
# Limpiar y volver a compilar
flutter clean
flutter pub get
flutter run
```

### "Network error" / "Connection refused"
- Verifica que el backend esté corriendo
- Verifica que la URL en el código sea correcta:
  - `lib/services/auth_service.dart` - línea 6: `baseUrl`
  - `lib/services/patient_service.dart` - línea 5: `baseUrl`
  - `lib/services/upload_service.dart` - línea 6: `baseUrl`
  - `lib/services/websocket_service.dart` - línea 8: `wsUrl`

### "WebSocket connection failed"
- Verifica que el servidor WebSocket acepte conexiones desde cualquier origen
- Verifica que el token JWT sea válido

### Ver logs completos
```bash
# Ver todos los logs de la app
flutter run --verbose

# O en otra terminal mientras la app corre
adb logcat | grep flutter
```

## 📝 Ver Requests/Responses

La app imprime todo en consola. Cuando ejecutas `flutter run`, verás:

```
🔌 WebSocket: Sending subscribe message: {"action":"subscribe",...}
🔵 RAW WebSocket message: {"ok":true,"action":"subscribed",...}
📱 ✅ Notification patientId saved: patient-123
```

## 🔄 Hot Reload (Cambios Instantáneos)

Si modificas el código mientras la app corre:
- Presiona `r` en la terminal para hot reload
- Presiona `R` para hot restart (reinicio completo)
- Los cambios se aplican en < 1 segundo

## 📂 Estructura del Código (Para Modificar URLs)

```
lib/
├── main.dart                          # Punto de entrada
├── models/
│   └── patient.dart                   # Modelo de datos de paciente
├── screens/
│   ├── login_screen.dart             # Pantalla de login
│   ├── home_screen.dart              # Pantalla principal con tabs
│   ├── patients_tab.dart             # Tab de lista de pacientes
│   ├── create_patient_tab.dart       # Tab de crear paciente
│   ├── upload_tab.dart               # Tab de upload de audio
│   └── notifications_tab.dart        # Tab de notificaciones
└── services/
    ├── auth_service.dart             # 🔧 Login y tokens (URL: línea 6)
    ├── patient_service.dart          # 🔧 CRUD pacientes (URL: línea 5)
    ├── upload_service.dart           # 🔧 Upload audio (URL: línea 6)
    └── websocket_service.dart        # 🔧 WebSocket (URL: línea 8)
```

## 🚀 Compilar APK para Compartir

Si quieres compartir la app con el equipo sin que instalen Flutter:

```bash
# Compilar APK
flutter build apk --release

# El APK estará en:
# build/app/outputs/flutter-apk/app-release.apk

# Compártelo por Slack/Email/Drive
```

## 🆘 Ayuda

Si tienes problemas:
1. Ejecuta `flutter doctor` y resuelve los warnings
2. Revisa los logs con `flutter run --verbose`
3. Pregunta a Felipe

---

**Desarrollado por Felipe Lara** (felipe@lara.ac)

**Repo**: https://github.com/MAIA-Health-Tech/test-endpoints-app
