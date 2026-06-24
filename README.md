# ZamVoice 🎙️

**Offline Nyanja-to-English Voice Translation App**

A Flutter-based mobile application that translates spoken Nyanja (Chichewa) into English text — entirely offline. Built as a final year research project exploring on-device speech recognition for low-resource African languages.

## ✨ Features

- **Offline Speech Recognition** — Powered by a fine-tuned Whisper model running locally via C FFI, no internet required
- **Translate & Transcribe** — Toggle between Nyanja→English translation and Nyanja transcription modes
- **Hold-to-Record** — Intuitive press-and-hold microphone button with visual progress arc
- **Audio File Upload** — Import existing audio files for translation
- **Text-to-Speech Playback** — Optional English TTS via ElevenLabs API
- **Chat-Style UI** — Translations displayed in a familiar chat bubble interface
- **Dark Theme** — Modern, sleek dark UI with green accent

## 🏗️ Architecture

The app follows **Clean Architecture** with **Riverpod** state management:

```
lib/
├── main.dart                     # Entry point
└── src/
    ├── app/                      # MaterialApp configuration
    ├── audio/                    # Recording, format conversion, upload
    ├── core/                     # Constants & configuration
    ├── inference/                # Whisper FFI bindings & service
    ├── models/                   # Data models (ChatMessage)
    ├── orchestration/            # Whisper task queue
    ├── presentation/             # UI screens & widgets
    │   ├── screens/              # Splash, Home, Chat, Settings
    │   └── widgets/              # RecordingFab, ChatBubble, etc.
    ├── state/                    # Riverpod controllers & state
    ├── storage/                  # Secure storage service
    ├── tts/                      # ElevenLabs TTS integration
    └── validation/               # Audio validation
```

## 🛠️ Tech Stack

| Component | Technology |
|---|---|
| Framework | Flutter (Dart) |
| Speech Model | Whisper.cpp (GGML, quantized Q8_0) |
| Native Bridge | Dart FFI → C → whisper.cpp |
| State Management | Riverpod |
| Audio Recording | `record` package (16kHz mono PCM WAV) |
| TTS | ElevenLabs API (optional) |
| Target Platform | Android (arm64-v8a) |

## 📋 Prerequisites

- Flutter SDK ≥ 3.5.0
- Android SDK with NDK (for native whisper.cpp compilation)
- Android device or emulator (minSdk 23)

## 🚀 Getting Started

### 1. Clone the repository
```bash
git clone https://github.com/buumba641/ZamVoice.git
cd ZamVoice
```

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Add the Whisper model
Place the quantized Nyanja Whisper model file in the assets directory:
```
assets/models/nyanja-whisper-q8_0.gguf
```
> **Note:** The `.gguf` model file is not included in the repository due to its size (~36 MB). Contact the project author for the model file.

### 4. Build & Run
```bash
flutter run
```

## 📱 Usage

1. **Launch** — The app shows a splash screen with the ZamVoice branding
2. **Record** — Long-press the microphone button and speak in Nyanja
3. **Upload** — Tap the upload button to import an audio file instead
4. **Toggle Mode** — Switch between *Translate* (Nyanja→English) and *Transcribe* (Nyanja→Nyanja) using the pill toggle
5. **Listen** — If TTS is configured, tap on a translation to hear it spoken in English

## ⚙️ Configuration

- **TTS Settings** — Tap the settings icon to configure your ElevenLabs API key and voice selection
- **Max Recording** — Recordings are limited to 6 minutes

## 📄 License

This project is part of a final year research project.

## 👤 Author

**Buumba Chinjila** — [@buumba641](https://github.com/buumba641)
