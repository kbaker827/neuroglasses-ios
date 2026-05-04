# NeuroGlasses iOS


> **🔵 Connectivity Update — May 2025**
> The glasses connection has been migrated from **raw TCP sockets** to
> **Bluetooth via the Rokid AI glasses SDK** (`pod 'RokidSDK' ~> 1.10.2`).
> No Wi-Fi port forwarding is needed. See **SDK Setup** below.

iOS companion app for [NeuroGlasses](https://github.com/Anezium/awesome-rokid) — an AI assistant for Rokid AR glasses.

Converted from the Android original. Replaces Android-specific components with iOS equivalents while preserving identical functionality.

## What it does

- **Voice input**: Record a question with the mic button; Whisper transcribes it.
- **Text input**: Type directly in the chat field.
- **Predefined instructions**: Tap the quote icon to apply a reusable prompt prefix (Summarize, Translate, Explain, etc.) — create your own.
- **Streaming AI responses**: GPT-4o streams text chunk-by-chunk to both the phone screen and connected glasses.
- **Glasses display**: A Bluetooth/RokidSDK sends `{"type":"chunk","text":"..."}` lines to any connected Rokid glasses client. Text resets every 350 characters (configurable) to avoid overflow.
- **TTS**: Each completed response is read aloud via OpenAI TTS-1, queued in segments for smooth playback.
- **Vision**: The chat API supports multimodal input — extend `NeuroViewModel` to attach image data.

## Android → iOS mapping

| Android | iOS |
|---------|-----|
| `BluetoothSppManager` | `GlassesStreamServer` (RokidSDK) |
| `WhisperService` | `OpenAIService.transcribe()` |
| `StreamingAudioPlayer` | `StreamingAudioPlayer` (AVAudioPlayer queue) |
| `InstructionAdapter` | `InstructionStore` + `InstructionsView` |
| `SettingsActivity` | `SettingsView` |
| `CxrApi` | RokidSDK |

## SDK Setup

The glasses now connect over **Bluetooth via the Rokid AI glasses SDK** — no Wi-Fi port or TCP server needed.

The only thing left for each app is filling in the three credential constants (`kAppKey`, `kAppSecret`, `kAccessKey`) from [account.rokid.com/#/setting/prove](https://account.rokid.com/#/setting/prove), then running `pod install`.

1. **Get credentials** at <https://account.rokid.com/#/setting/prove> and paste them into the glasses Swift file:
   ```swift
   private let kAppKey    = "YOUR_APP_KEY"
   private let kAppSecret = "YOUR_APP_SECRET"
   private let kAccessKey = "YOUR_ACCESS_KEY"
   ```

2. **Install CocoaPods dependencies** from the repo root:
   ```bash
   pod install
   open *.xcworkspace   # always open the .xcworkspace, not .xcodeproj
   ```

3. *(Glasses now connect automatically over Bluetooth — no TCP port needed.)*

## Setup

1. Open `NeuroGlasses.xcworkspace` in Xcode 15+ (after running `pod install`) 15+.
2. Set your team in Signing & Capabilities.
3. Build and run on an iPhone (iOS 17+).
4. Tap the gear icon and enter your OpenAI API key.
5. *(Glasses now connect automatically over Bluetooth — no TCP port needed.)*

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
