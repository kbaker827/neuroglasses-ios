import Foundation
import Network

final class GlassesStreamServer {
    private let port: NWEndpoint.Port = 8083
    private var listener: NWListener?
    private var connections: [NWConnection] = []
    private let queue = DispatchQueue(label: "glasses.stream")

    var onClientConnected: (() -> Void)?
    var onClientDisconnected: (() -> Void)?

    var clientCount: Int { connections.count }

    func start() {
        do {
            listener = try NWListener(using: .tcp, on: port)
        } catch {
            print("GlassesStreamServer: failed to create listener: \(error)")
            return
        }
        listener?.newConnectionHandler = { [weak self] conn in
            self?.accept(conn)
        }
        listener?.start(queue: queue)
        print("GlassesStreamServer: listening on port \(port)")
    }

    func stop() {
        listener?.cancel()
        listener = nil
        connections.forEach { $0.cancel() }
        connections.removeAll()
    }

    private func accept(_ conn: NWConnection) {
        connections.append(conn)
        conn.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            if case .failed = state {
                self.remove(conn)
            } else if case .cancelled = state {
                self.remove(conn)
            }
        }
        conn.start(queue: queue)
        onClientConnected?()
    }

    private func remove(_ conn: NWConnection) {
        connections.removeAll { $0 === conn }
        onClientDisconnected?()
    }

    // MARK: - Broadcast

    func broadcastChunk(_ text: String) {
        send(["type": "chunk", "text": text])
    }

    func broadcastClear() {
        send(["type": "clear"])
    }

    func broadcastDone() {
        send(["type": "done"])
    }

    func broadcastError(_ message: String) {
        send(["type": "error", "message": message])
    }

    private func send(_ payload: [String: String]) {
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              var line = String(data: data, encoding: .utf8) else { return }
        line += "\n"
        let raw = Data(line.utf8)
        for conn in connections {
            conn.send(content: raw, completion: .idempotent)
        }
    }
}
