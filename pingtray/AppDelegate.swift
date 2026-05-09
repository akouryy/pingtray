import AppKit
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let modelData = ModelData()
    private var cancellable: AnyCancellable?
    private let lineMenuItem = NSMenuItem()
    private let monoFont = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
    private let regularFont = NSFont.systemFont(ofSize: NSFont.systemFontSize)

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

        cancellable = modelData.$pingMS.combineLatest(modelData.$line)
            .receive(on: RunLoop.main)
            .sink { [weak self] pingMS, line in
                self?.update(pingMS: pingMS, line: line)
            }
    }

    private func update(pingMS: String, line: String) {
        lineMenuItem.title = line.trimmingCharacters(in: .whitespacesAndNewlines)

        if pingMS.isEmpty {
            statusItem.button?.image = NSImage(systemSymbolName: "bolt.slash", accessibilityDescription: nil)
            statusItem.button?.attributedTitle = NSAttributedString()
        } else {
            statusItem.button?.image = nil
            let result = NSMutableAttributedString(
                string: String(format: "%2d", Int(pingMS) ?? 0),
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
