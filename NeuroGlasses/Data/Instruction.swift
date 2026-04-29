import Foundation

struct Instruction: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var prompt: String
}

final class InstructionStore: ObservableObject {
    @Published var instructions: [Instruction] {
        didSet { save() }
    }

    private let key = "neuro_instructions"

    init() {
        if let data = UserDefaults.standard.data(forKey: "neuro_instructions"),
           let decoded = try? JSONDecoder().decode([Instruction].self, from: data) {
            instructions = decoded
        } else {
            instructions = Self.defaults
        }
    }

    private static let defaults: [Instruction] = [
        Instruction(title: "Summarize", prompt: "Please summarize the following in 2-3 sentences:"),
        Instruction(title: "Translate to Spanish", prompt: "Translate the following to Spanish:"),
        Instruction(title: "Translate to English", prompt: "Translate the following to English:"),
        Instruction(title: "Explain simply", prompt: "Explain the following in simple terms a 10-year-old would understand:"),
        Instruction(title: "Key points", prompt: "List the key points from the following:"),
        Instruction(title: "Grammar check", prompt: "Fix any grammar or spelling issues in the following text:"),
    ]

    private func save() {
        if let data = try? JSONEncoder().encode(instructions) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
