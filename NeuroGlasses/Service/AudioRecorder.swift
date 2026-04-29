import Foundation
import AVFoundation

final class AudioRecorder {
    private var engine = AVAudioEngine()
    private var file: AVAudioFile?
    private var fileURL: URL?
    private var isRecording = false

    func startRecording() throws {
        guard !isRecording else { return }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".wav")
        fileURL = url

        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        file = try AVAudioFile(forWriting: url, settings: format.settings)

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
            try? self?.file?.write(from: buffer)
        }

        engine.prepare()
        try engine.start()
        isRecording = true
    }

    func stopRecording() -> Data? {
        guard isRecording else { return nil }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        file = nil
        isRecording = false

        try? AVAudioSession.sharedInstance().setActive(false)

        guard let url = fileURL,
              let data = try? Data(contentsOf: url) else { return nil }
        try? FileManager.default.removeItem(at: url)
        fileURL = nil
        return data
    }

    var recording: Bool { isRecording }
}
