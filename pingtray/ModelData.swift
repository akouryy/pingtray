import SwiftUI

class ModelData: ObservableObject {
    struct PingResult {
        var pingMS: String = ""
        var line: String = ""
    }

    @Published var pingResult = PingResult()

    private let proc = Process()
    private let pipe = Pipe()
    nonisolated(unsafe) private var observer: NSObjectProtocol?

    init() {
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if data.isEmpty { return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let line = String(data: data, encoding: .utf8), !line.isEmpty {
                    if let match = line.wholeMatch(of: /\d+ bytes from \d+\.\d+\.\d+\.\d+: icmp_seq=\d+ ttl=\d+ time=(\d+)\.\d+ ms\s+/) {
                        self.pingResult = PingResult(pingMS: String(match.1), line: line)
                    } else {
                        self.pingResult = PingResult(line: line)
                    }
                } else {
                    self.pingResult = PingResult(line: "Decode error: \(data)")
                }
            }
        }

        proc.executableURL = URL(filePath: "/sbin/ping")
        proc.arguments = ["8.8.8.8"]
        proc.standardOutput = pipe
        try! proc.run()

        observer = NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.proc.terminate() }
        }
    }

    deinit {
        pipe.fileHandleForReading.readabilityHandler = nil
        proc.terminate()
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
