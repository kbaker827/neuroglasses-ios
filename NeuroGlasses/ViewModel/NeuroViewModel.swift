import Foundation
import AVFoundation

@MainActor
final class NeuroViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isRecording = false
    @Published var isStreaming = false
    @Published var statusText = "Ready"
    @Published var glassesConnected = false
    @Published var glassesClientCount = 0
    @Published var currentStreamText = ""
    @Published var selectedInstruction: Instruction?

    let settingsStore: SettingsStore
    let instructionStore: InstructionStore

    private let openAI = OpenAIService()
    private let recorder = AudioRecorder()
    private let audioPlayer = StreamingAudioPlayer()
    private let glassesServer = GlassesStreamServer()
    private var streamBuffer = ""

    init(settingsStore: SettingsStore, instructionStore: InstructionStore) {
        self.settingsStore = settingsStore
        self.instructionStore = instructionStore
        startGlassesServer()
    }

    private func startGlassesServer() {
        glassesServer.onClientConnected = { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                glassesClientCount = glassesServer.clientCount
                glassesConnected = glassesClientCount > 0
            }
        }
        glassesServer.onClientDisconnected = { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                glassesClientCount = glassesServer.clientCount
                glassesConnected = glassesClientCount > 0
            }
        }
        glassesServer.start()
    }

    // MARK: - Recording

    func toggleRecording() {
        if isRecording {
            finishRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        do {
            try recorder.startRecording()
            isRecording = true
            statusText = "Recording..."
        } catch {
            statusText = "Mic error: \(error.localizedDescription)"
        }
    }

    private func finishRecording() {
        guard let audioData = recorder.stopRecording() else {
            isRecording = false
            statusText = "No audio captured"
            return
        }
        isRecording = false
        statusText = "Transcribing..."
        Task {
            await transcribeAndChat(audioData: audioData)
        }
    }

    private func transcribeAndChat(audioData: Data) async {
        let s = settingsStore.settings
        guard !s.apiKey.isEmpty else {
            statusText = "API key not set"
            return
        }

        guard let transcript = await openAI.transcribe(audioData: audioData, apiKey: s.apiKey, baseUrl: s.baseUrl) else {
            statusText = "Transcription failed"
            return
        }

        await chat(userText: transcript)
    }

    // MARK: - Text chat

    func sendText(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        Task { await chat(userText: text) }
    }

    private func chat(userText: String) async {
        let s = settingsStore.settings
        guard !s.apiKey.isEmpty else { statusText = "API key not set"; return }

        let instructionPrefix = selectedInstruction.map { $0.prompt + " " } ?? ""
        let fullText = instructionPrefix + userText

        let userMsg = ChatMessage(role: "user", content: userText)
        messages.append(userMsg)
        statusText = "Thinking..."
        isStreaming = true
        streamBuffer = ""
        currentStreamText = ""
        glassesServer.broadcastClear()

        var history: [[String: Any]] = messages.dropLast().map { ["role": $0.role, "content": $0.content] }
        history.append(["role": "user", "content": fullText])

        if s.streamingEnabled {
            await withCheckedContinuation { continuation in
                openAI.streamChat(
                    messages: history,
                    model: s.chatModel,
                    apiKey: s.apiKey,
                    baseUrl: s.baseUrl,
                    onChunk: { [weak self] chunk in
                        Task { @MainActor [weak self] in
                            self?.handleChunk(chunk)
                        }
                    },
                    onComplete: { [weak self] full in
                        Task { @MainActor [weak self] in
                            self?.handleComplete(full, settings: s)
                            continuation.resume()
                        }
                    }
                )
            }
        } else {
            let result = await openAI.chat(prompt: fullText, imageData: nil, model: s.chatModel, apiKey: s.apiKey, baseUrl: s.baseUrl)
            let reply = result ?? "No response"
            messages.append(ChatMessage(role: "assistant", content: reply))
            glassesServer.broadcastChunk(reply)
            glassesServer.broadcastDone()
            if s.ttsEnabled {
                await speakText(reply)
            }
            isStreaming = false
            statusText = "Ready"
        }
    }

    private func handleChunk(_ chunk: String) {
        streamBuffer += chunk
        currentStreamText += chunk

        let maxChars = settingsStore.settings.maxDisplayChars
        if currentStreamText.count > maxChars {
            glassesServer.broadcastClear()
            currentStreamText = chunk
        }
        glassesServer.broadcastChunk(chunk)
    }

    private func handleComplete(_ full: String, settings: NeuroSettings) {
        messages.append(ChatMessage(role: "assistant", content: full.isEmpty ? streamBuffer : full))
        glassesServer.broadcastDone()
        currentStreamText = ""
        isStreaming = false
        statusText = "Ready"

        if settings.ttsEnabled && !streamBuffer.isEmpty {
            let textToSpeak = full.isEmpty ? streamBuffer : full
            Task { await speakText(textToSpeak) }
        }
        streamBuffer = ""
    }

    private func speakText(_ text: String) async {
        let s = settingsStore.settings
        let chunks = splitForTTS(text)
        for chunk in chunks {
            if let data = await openAI.speak(text: chunk, voice: s.ttsVoice, apiKey: s.apiKey, baseUrl: s.baseUrl) {
                audioPlayer.enqueue(data)
            }
        }
    }

    private func splitForTTS(_ text: String, maxLength: Int = 200) -> [String] {
        guard text.count > maxLength else { return [text] }
        var chunks: [String] = []
        var current = ""
        for sentence in text.components(separatedBy: CharacterSet(charactersIn: ".!?")) {
            let s = sentence.trimmingCharacters(in: .whitespaces)
            if s.isEmpty { continue }
            if (current + s).count > maxLength && !current.isEmpty {
                chunks.append(current.trimmingCharacters(in: .whitespaces))
                current = s + ". "
            } else {
                current += s + ". "
            }
        }
        if !current.trimmingCharacters(in: .whitespaces).isEmpty {
            chunks.append(current.trimmingCharacters(in: .whitespaces))
        }
        return chunks.isEmpty ? [text] : chunks
    }

    func clearHistory() {
        messages.removeAll()
        streamBuffer = ""
        currentStreamText = ""
        glassesServer.broadcastClear()
    }

    func stopAudio() {
        audioPlayer.stop()
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: String
    let content: String

    var isUser: Bool { role == "user" }
}
