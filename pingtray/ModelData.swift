import SwiftUI

class ModelData : ObservableObject {
    @Published var pingMS: String = ""
    @Published var line: String = ""

    init() {
        let proc = Process()
        let pipe = Pipe()

        pipe.fileHandleForReading.readabilityHandler = { [weak self] pipe in
            guard let self = self else {
                proc.terminate()
                return
            }
            if let line = String(
                data: pipe.availableData,
                encoding: String.Encoding(rawValue: NSUTF8StringEncoding)
            ) {
                if !line.isEmpty {
                    DispatchQueue.main.async {
                        if let match = line.wholeMatch(of: /\d+ bytes from \d+\.\d+\.\d+\.\d+: icmp_seq=\d+ ttl=\d+ time=(\d+)\.\d+ ms\s+/) {
                            self.pingMS = String(match.1)
                        } else {
                            self.pingMS = ""
                        }
                        self.line = line
                    }
                }
            } else {
                self.pingMS = ""
                self.line = "Decode error: \(pipe.availableData)"
            }
        }

        proc.executableURL = URL(filePath: "/sbin/ping")
        proc.arguments = ["8.8.8.8"]
        proc.standardOutput = pipe
        proc.launch()

        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification, object: nil, queue: .main
        ) { _ in
            proc.terminate()
        }
    }
}
