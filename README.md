
# Nexus AI Dashboard

A professional, local-first Desktop Application built with Flutter for Windows/macOS. Supports OpenAI, Gemini, Claude, and ElevenLabs with secure local storage.

## Features
- **Local-First Architecture**: All keys and chats stored locally using Hive.
- **Security**: Master Password encryption (AES-256) for API Keys.
- **Multi-Provider**: Switch between GPT-4, Claude 3, Gemini 1.5 Pro instantly.
- **Voice Synergy**: Text-to-Speech using ElevenLabs.
- **Export**: Save chat history as JSON to Desktop.

## Setup Instructions

### 1. Prerequisites
- Install [Flutter SDK](https://docs.flutter.dev/get-started/install).
- Enable Desktop support: 
  ```bash
  flutter config --enable-windows-desktop
  ```

### 2. Installation
Run the following commands in this directory:

```bash
# Get dependencies
flutter pub get

# Generate Hive Adapters (Important!)
flutter pub run build_runner build
```

### 3. Running Locally
```bash
flutter run -d windows
```

## How to Build .exe (Distribution)

To create the final executable file for Windows:

1.  Open Terminal in this project folder.
2.  Run the build command:
    ```bash
    flutter build windows --release
    ```
3.  Locate the `.exe` file in:
    `build\windows\runner\Release\`

You can zip this folder and share it. The `.exe` requires the accompanying `.dll` files in that folder to run.

## License
MIT
