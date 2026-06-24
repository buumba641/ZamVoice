# ZamVoice 🎙️

**Offline Automatic Speech Recognition for Zambian Languages**

ZamVoice is a Flutter-based mobile application that performs **automatic speech recognition (ASR)** for Zambian languages — entirely offline. It is a key deliverable of a final year research project:

> **"Low-Resource Automatic Speech Recognition of Zambian Languages: A Comparative Analysis of Pretrained Models on Tonga, Nyanja and Bemba"**

The app demonstrates that fine-tuned pretrained models can achieve usable ASR accuracy on low-resource African languages, running directly on-device without internet connectivity. Translation to English is included as a bonus feature to showcase the practical application of the system.

## ✨ Features

- **Offline ASR** — Transcribe spoken Zambian languages (Nyanja, Bemba, Tonga) using a fine-tuned Whisper model running locally via C FFI
- **No Internet Required** — All inference runs on-device using quantized GGML models
- **Transcribe & Translate** — Toggle between native language transcription and English translation modes
- **Hold-to-Record** — Intuitive press-and-hold microphone button with visual progress arc
- **Audio File Upload** — Import existing audio files for transcription
- **Text-to-Speech Playback** — Optional English TTS via ElevenLabs API
- **Chat-Style UI** — Results displayed in a familiar chat bubble interface
- **Dark Theme** — Modern, sleek dark UI with green accent

## 🔬 Research Context

This application serves as a practical demonstration for the research project, which investigates:

- The effectiveness of **pretrained ASR models** (e.g., OpenAI Whisper) when fine-tuned on low-resource Zambian language datasets
- **Comparative performance** across Tonga, Nyanja, and Bemba
- The feasibility of deploying these models on **mobile devices** for real-world use in Zambia
- How **quantization** (GGML Q8_0) affects model accuracy vs. inference speed on consumer hardware

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
| ASR Model | Whisper.cpp (GGML, quantized Q8_0) |
| Native Bridge | Dart FFI → C → whisper.cpp |
| State Management | Riverpod |
| Audio Recording | `record` package (16kHz mono PCM WAV) |
| TTS | ElevenLabs API (optional) |
| Target Platform | Android (arm64-v8a) |

## 📋 Prerequisites

- Flutter SDK ≥ 3.5.0
- Android SDK with NDK (for native whisper.cpp compilation)
- Android device or emulator (minSdk 24)

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
Place the quantized Whisper model file in the assets directory:
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
2. **Record** — Long-press the microphone button and speak in a supported Zambian language
3. **Upload** — Tap the upload button to import an existing audio file
4. **Toggle Mode** — Switch between *Transcribe* (native language text) and *Translate* (English output) using the pill toggle
5. **Listen** — If TTS is configured, tap on a result to hear it spoken

## ⚙️ Configuration

- **TTS Settings** — Tap the settings icon to configure your ElevenLabs API key and voice selection
- **Max Recording** — Recordings are limited to 6 minutes

## 📄 License

This project is part of a final year research project at university.

## 👤 Author

**Buumba Chinjila** — [@buumba641](https://github.com/buumba641)
