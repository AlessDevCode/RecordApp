# 📱 RecordApp - Gestión Inteligente de Misiones, Alarmas y Rutinas

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)

**RecordApp** es una aplicación móvil desarrollada en Flutter diseñada para transformar la gestión personal de tareas y hábitos en un sistema dinámico de **"Misiones"**. Combina la precisión de un sistema de alarmas nativo con la flexibilidad de recordatorios periódicos, tolerancias de tiempo inteligentes y modos de alerta personalizados.

---

## 🚀 Guía de Usuario (User Guide)

### 📌 ¿Qué es RecordApp?
RecordApp te ayuda a organizar tu día mediante misiones de una sola vez o rutinas recurrentes. Está pensada para garantizar que nunca pases por alto una tarea crucial o un compromiso recurrente.

### ⭐ Características Principales

* **⏰ Sistema Flex-Alarma:**
  * **Tipos de alerta:** Sonido, Vibración discreta o Silencioso.
  * **Duración personalizable:** Configura la duración exacta del sonido o la vibración.
  * **Repetición automática (Snooze/Intervalos):** Define cuántas veces debe reintentar sonar/vibrar la alarma y el intervalo en minutos entre cada intento.

* **📅 Frecuencias Adaptables:**
  * **Una sola vez:** Para eventos puntuales.
  * **Semanal / Especial:** Asigna días específicos o crea **bloques de horarios independientes** por día (ej. Lunes y Jueves a las 11:30 AM, Martes y Viernes a las 10:40 AM).

* **🚨 Ventana de Estado CRÍTICO (Tolerancia de 30 min):**
  * Si una rutina vence, entra automáticamente en estado **CRÍTICO** en rojo durante exactamente **30 minutos**.
  * Pasada la ventana de tolerancia, el estado crítico desaparece y la tarjeta se enfoca inmediatamente en la **siguiente ocurrencia futura**, evitando acumular alertas rojas molestas del pasado.

---

## 🛠️ Guía para Desarrolladores (Developer Guide)

### 🏗️ Arquitectura y Tecnologías

* **Framework:** Flutter (Dart)
* **Gestión de Estado:** Riverpod / Provider
* **Notificaciones & Alarmas Locales:** `flutter_local_notifications` + Android Native `AlarmManager` (`RTC_WAKEUP`)
* **Sincronización en Tiempo Real:** Stream & Clock Provider de actualización por minuto para refrescar la interfaz reactiva sin consumo excesivo de batería.

### 📂 Estructura del Proyecto

```text
lib/
├── models/         # Modelos de datos (Task, Mission, Routine, BlockSchedule)
├── providers/      # Proveedores de estado (TaskProviders, ClockProvider)
├── services/       # Servicios de notificaciones, persistencia local y filtros
├── ui/             # Interfaz de usuario
│   ├── screens/    # Pantallas principales y editor de misiones
│   └── widgets/    # Tarjetas de misiones, controles de tiempo y selectores
└── main.dart       # Punto de entrada de la aplicación
```

### 💻 Configuración del Entorno de Desarrollo

1. **Requisitos previos:**
   * Flutter SDK (Versión 3.x o superior)
   * Android SDK (API 21+) / Android Studio o VS Code
   * Dispositivo físico o emulador Android

2. **Clonar el repositorio:**
   ```bash
   git clone https://github.com/AlessDevCode/RecordApp.git
   cd RecordApp/recordapp
   ```

3. **Instalar dependencias:**
   ```bash
   flutter pub get
   ```

4. **Ejecutar en modo depuración (Debug):**
   ```bash
   flutter run
   ```

5. **Compilar APK Release:**
   ```bash
   flutter build apk --release
   ```
   El instalador se generará en: `build/app/outputs/flutter-apk/app-release.apk`

---

## 📜 Licencia

Este proyecto se distribuye bajo la licencia MIT.
---

## ☕ Apoya el Proyecto

**RecordApp** es un proyecto independiente, de código abierto y completamente gratuito para uso personal. Si la aplicación te resulta útil y deseas apoyar su desarrollo continuo, ¡cualquier contribución es enormemente apreciada!

<div align="center">

[![Ko-fi](https://img.shields.io/badge/Ko--fi-Buy%20me%20a%20coffee-FF5E5B?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/TU_USUARIO_KOFI)

<br/>

### 🇵🇪 Donaciones mediante Yape (Perú)

Puedes escanear el código QR directamente desde tu aplicación:

| Código QR Yape | Titular |
| :---: | :--- |
| <img src="QR.jpeg" width="180" alt="QR Yape"/> | **Nombre:** Alessandro<br/>**Moneda:** PEN (Soles) |

</div>