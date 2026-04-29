# NeuroGlasses iOS

iOS companion app for [NeuroGlasses](https://github.com/Anezium/awesome-rokid) — an AI assistant for Rokid AR glasses.

Converted from the Android original. Replaces Android-specific components with iOS equivalents while preserving identical functionality.

## What it does

- **Voice input**: Record a question with the mic button; Whisper transcribes it.
- **Text input**: Type directly in the chat field.
- **Predefined instructions**: Tap the quote icon to apply a reusable prompt prefix (Summarize, Translate, Explain, etc.) — create your own.
- **Streaming AI responses**: GPT-4o streams text chunk-by-chunk to both the phone screen and connected glasses.
- **Glasses display**: A TCP server on port 8083 pushes `{"type":"chunk","text":"..."}` lines to any connected Rokid glasses client. Text resets every 350 characters (configurable) to avoid overflow.
- **TTS**: Each completed response is read aloud via OpenAI TTS-1, queued in segments for smooth playback.
- **Vision**: The chat API supports multimodal input — extend `NeuroViewModel` to attach image data.

## Android → iOS mapping

| Android | iOS |
|---------|-----|
| `BluetoothSppManager` | `GlassesStreamServer` (NWListener TCP :8083) |
| `WhisperService` | `OpenAIService.transcribe()` |
| `StreamingAudioPlayer` | `StreamingAudioPlayer` (AVAudioPlayer queue) |
| `InstructionAdapter` | `InstructionStore` + `InstructionsView` |
| `SettingsActivity` | `SettingsView` |
| `CxrApi` | NWListener TCP (no Rokid SDK needed) |

## Setup

1. Open `NeuroGlasses.xcodeproj` in Xcode 15+.
2. Set your team in Signing & Capabilities.
3. Build and run on an iPhone (iOS 17+).
4. Tap the gear icon and enter your OpenAI API key.
5. Connect Rokid glasses to the same Wi-Fi; point the glasses app at `<phone-ip>:8083`.

## Glasses protocol

Each message is a JSON object followed by `\n`:

```json
{"type":"clear"}
{"type":"chunk","text":"Hello "}
{"type":"chunk","text":"world!"}
{"type":"done"}
{"type":"error","message":"API key not set"}
```

## Requirements

- iOS 17+
- OpenAI API key
- Xcode 15+
