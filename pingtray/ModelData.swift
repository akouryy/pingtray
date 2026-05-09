import SwiftUI

class ModelData: ObservableObject {
    @Published var pingMS: String = ""
    @Published var line: String = ""

    private let proc = Process()
    private let pipe = Pipe()
    private var observer: NSObjectProtocol?

    init() {
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            guard let self else { return }
            let data = handle.availableData
            if data.isEmpty { return }
            if let line = String(data: data, encoding: .utf8), !line.isEmpty {
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    if let match = line.wholeMatch(of: /\d+ bytes from \d+\.\d+\.\d+\.\d+: icmp_seq=\d+ ttl=\d+ time=(\d+)\.\d+ ms\s+/) {
                        self.pingMS = String(match.1)
                    } else {
                        self.pingMS = ""
                    }
                    self.line = line
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.pingMS = ""
                    self.line = "Decode error: \(data)"
                }
            }
        }

        proc.executableURL = URL(filePath: "/sbin/ping")
        proc.arguments = ["8.8.8.8"]
        proc.standardOutput = pipe
        proc.launch()

        observer = NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification, object: nil, queue: .main
        ) { [weak self] _ in
            self?.proc.terminate()
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
