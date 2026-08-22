# Roblox .rbxl Uploader

Aplicación Flutter para Android que permite subir archivos `.rbxl` (places de Roblox) directamente a Roblox utilizando la **Roblox Open Cloud API**.

## ✨ Características

- 🔐 **Almacenamiento seguro** de la API Key usando `flutter_secure_storage`
- 📁 **Selector de archivos** `.rbxl` con `file_picker`
- 📤 **Subida con progreso** visual en tiempo real
- ✅ **Manejo de errores** con mensajes claros
- 🎨 **Interfaz moderna** con Material 3

## 🚀 Uso

1. Ingresa tu **x-api-key** de Roblox Open Cloud
2. Ingresa el **Place ID** del lugar donde quieres publicar
3. Selecciona tu archivo `.rbxl`
4. Toca **"Publicar / Subir a Roblox"**

## 🔧 Configuración del proyecto

### Requisitos previos
- Flutter SDK >= 3.0.0
- Android SDK
- Java 17

### Instalación local

```bash
# Clonar el repositorio
git clone <tu-repo>.git
cd roblox_rbxl_uploader

# Instalar dependencias
flutter pub get

# Ejecutar en modo debug
flutter run

# Compilar APK release
flutter build apk --release
```

## 🔑 Obtener tu API Key de Roblox

1. Ve a [Roblox Creator Dashboard](https://create.roblox.com/)
2. Navega a **Settings > Open Cloud**
3. Crea una nueva **API Key**
4. Asegúrate de otorgar permisos para **Place Publishing**
5. Copia la key y pégala en la app

## 🔄 CI/CD con GitHub Actions

El repositorio incluye un workflow (`.github/workflows/build_apk.yml`) que:

- Se ejecuta automáticamente en cada `push` a `main`
- También puede ejecutarse manualmente desde la pestaña **Actions**
- Compila el APK en modo release
- Sube el artefacto descargable desde GitHub Actions

### Descargar el APK desde Actions

1. Ve a la pestaña **Actions** en tu repositorio de GitHub
2. Selecciona el workflow **Build APK**
3. Abre la ejecución más reciente
4. En la sección **Artifacts**, descarga `app-release-apk`

## 📁 Estructura del proyecto

```
roblox_rbxl_uploader/
├── android/app/build.gradle
├── lib/
│   └── main.dart
├── .github/
│   └── workflows/
│       └── build_apk.yml
├── pubspec.yaml
└── README.md
```

## 📄 Licencia

MIT
