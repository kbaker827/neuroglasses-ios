import Foundation
import AVFoundation

struct StreamChunk {
    let text: String
    let isDone: Bool
}

final class OpenAIService {
    private let session = URLSession.shared

    // MARK: - Whisper STT

    func transcribe(audioData: Data, apiKey: String, baseUrl: String) async -> String? {
        let url = URL(string: "\(baseUrl.trimmingCharacters(in: .init(charactersIn: "/")))/audio/transcriptions")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let boundary = UUID().uuidString
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        func field(_ name: String, _ value: String) {
            body.append("--\(boundary)\r\nContent-Disposition: form-data; name=\"\(name)\"\r\n\r\n\(value)\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)\r\nContent-Disposition: form-data; name=\"file\"; filename=\"audio.wav\"\r\nContent-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        field("model", "whisper-1")
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        req.httpBody = body

        guard let data = try? await session.data(for: req).0,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let text = json["text"] as? String else { return nil }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Chat completion (streaming)

    func streamChat(
        messages: [[String: Any]],
        model: String,
        apiKey: String,
        baseUrl: String,
        onChunk: @escaping (String) -> Void,
        onComplete: @escaping (String) -> Void
    ) {
        let url = URL(string: "\(baseUrl.trimmingCharacters(in: .init(charactersIn: "/")))/chat/completions")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["model": model, "stream": true, "messages": messages]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        var fullText = ""
        let task = URLSession.shared.dataTask(with: req)
        // Use simple non-streaming for compatibility
        URLSession.shared.dataTask(with: req) { data, _, _ in
            guard let data,
                  let raw = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async { onComplete("") }
                return
            }
            for line in raw.components(separatedBy: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard trimmed.hasPrefix("data: "), trimmed != "data: [DONE]" else { continue }
                let jsonStr = String(trimmed.dropFirst(6))
                guard let jd = jsonStr.data(using: .utf8),
                      let jobj = try? JSONSerialization.jsonObject(with: jd) as? [String: Any],
                      let choices = jobj["choices"] as? [[String: Any]],
                      let delta = choices.first?["delta"] as? [String: Any],
                      let content = delta["content"] as? String else { continue }
                fullText += content
                DispatchQueue.main.async { onChunk(content) }
            }
            DispatchQueue.main.async { onComplete(fullText) }
        }.resume()
    }

    // MARK: - Non-streaming chat (with vision)

    func chat(prompt: String, imageData: Data?, model: String, apiKey: String, baseUrl: String) async -> String? {
        let url = URL(string: "\(baseUrl.trimmingCharacters(in: .init(charactersIn: "/")))/chat/completions")!

        var contentParts: [[String: Any]] = [["type": "text", "text": prompt]]
        if let img = imageData {
            let b64 = img.base64EncodedString()
            contentParts.append(["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(b64)"]])
        }

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 1000,
            "messages": [["role": "user", "content": contentParts]],
        ]

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        req.timeoutInterval = 30

        guard let data = try? await session.data(for: req).0,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else { return nil }
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - TTS

    func speak(text: String, voice: String = "alloy", apiKey: String, baseUrl: String) async -> Data? {
        let url = URL(string: "\(baseUrl.trimmingCharacters(in: .init(charactersIn: "/")))/audio/speech")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["model": "tts-1", "input": text, "voice": voice, "response_format": "mp3"]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        req.timeoutInterval = 30
        return try? await session.data(for: req).0
    }
}
