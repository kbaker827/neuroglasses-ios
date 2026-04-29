import Foundation
import AVFoundation

final class StreamingAudioPlayer {
    private var player: AVAudioPlayer?
    private var queue: [Data] = []
    private var isPlaying = false

    func enqueue(_ data: Data) {
        queue.append(data)
        if !isPlaying { playNext() }
    }

    func stop() {
        player?.stop()
        player = nil
        queue.removeAll()
        isPlaying = false
    }

    private func playNext() {
        guard !queue.isEmpty else { isPlaying = false; return }
        let data = queue.removeFirst()
        isPlaying = true
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(data: data)
            player?.delegate = DelegateShim(onFinish: { [weak self] in self?.playNext() })
            player?.play()
        } catch {
            isPlaying = false
            playNext()
        }
    }
}

private final class DelegateShim: NSObject, AVAudioPlayerDelegate {
    let onFinish: () -> Void
    init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) { onFinish() }
}
