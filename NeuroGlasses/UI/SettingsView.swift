import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: SettingsStore

    private let voices = ["alloy", "echo", "fable", "onyx", "nova", "shimmer"]
    private let models = ["gpt-4o", "gpt-4o-mini", "gpt-4-turbo", "gpt-3.5-turbo"]

    var body: some View {
        Form {
            Section("API") {
                SecureField("OpenAI API Key", text: $store.settings.apiKey)
                    .textContentType(.password)
                TextField("Base URL", text: $store.settings.baseUrl)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
            }

            Section("Chat Model") {
                Picker("Chat Model", selection: $store.settings.chatModel) {
                    ForEach(models, id: \.self) { Text($0).tag($0) }
                }
                Picker("Vision Model", selection: $store.settings.visionModel) {
                    ForEach(models, id: \.self) { Text($0).tag($0) }
                }
                Toggle("Streaming", isOn: $store.settings.streamingEnabled)
            }

            Section("TTS") {
                Toggle("Text-to-Speech", isOn: $store.settings.ttsEnabled)
                Picker("Voice", selection: $store.settings.ttsVoice) {
                    ForEach(voices, id: \.self) { Text($0.capitalized).tag($0) }
                }
            }

            Section("Glasses Display") {
                Stepper("Max chars: \(store.settings.maxDisplayChars)", value: $store.settings.maxDisplayChars, in: 100...1000, step: 50)
                    .monospacedDigit()
                Text("Text scrolls on glasses after this many characters.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Settings")
    }
}
