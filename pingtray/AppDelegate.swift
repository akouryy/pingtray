import AppKit
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let modelData = ModelData()
    private var cancellable: AnyCancellable?
    private let lineMenuItem = NSMenuItem()
    private let monoFont = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize - 1, weight: .regular)
    private let regularFont = NSFont.systemFont(ofSize: NSFont.systemFontSize - 1)

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        statusItem.menu = NSMenu()
        statusItem.menu!.addItem(lineMenuItem)
        statusItem.menu!.addItem(.separator())
        let versionLabel = [
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
            Bundle.main.infoDictionary?["BuiltAt"] as? String ?? "",
        ].filter { !$0.isEmpty }.joined(separator: ".")
        statusItem.menu!.addItem(
            NSMenuItem(
                title: "Quit PingTray \(versionLabel)",
                action: #selector(quit),
                keyEquivalent: "q",
            ),
        )

        cancellable = modelData.$pingResult
            .sink { [weak self] pingResult in
                MainActor.assumeIsolated {
                    self?.update(pingResult: pingResult)
                }
            }
    }

    private func update(pingResult: ModelData.PingResult) {
        lineMenuItem.title = pingResult.line.trimmingCharacters(in: .whitespacesAndNewlines)

        if pingResult.pingMS.isEmpty {
            statusItem.button?.image = NSImage(systemSymbolName: "bolt.slash", accessibilityDescription: nil)
            statusItem.button?.attributedTitle = NSAttributedString()
        } else {
            statusItem.button?.image = nil
            let result = NSMutableAttributedString(
                string: String(format: "%2d", Int(pingResult.pingMS) ?? 0),
                attributes: [.font: monoFont],
            )
            result.append(NSAttributedString(string: "ms", attributes: [.font: regularFont]))
            statusItem.button?.attributedTitle = result
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
