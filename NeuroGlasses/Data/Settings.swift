import Foundation

struct NeuroSettings: Codable {
    var apiKey: String = ""
    var baseUrl: String = "https://api.openai.com/v1"
    var chatModel: String = "gpt-4o"
    var visionModel: String = "gpt-4o"
    var ttsVoice: String = "alloy"
    var ttsEnabled: Bool = true
    var streamingEnabled: Bool = true
    var maxDisplayChars: Int = 350
}

final class SettingsStore: ObservableObject {
    @Published var settings: NeuroSettings {
        didSet { save() }
    }

    private let key = "neuro_settings"

    init() {
        if let data = UserDefaults.standard.data(forKey: "neuro_settings"),
           let decoded = try? JSONDecoder().decode(NeuroSettings.self, from: data) {
            settings = decoded
        } else {
            settings = NeuroSettings()
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
