import SwiftUI

@main
struct pingtrayApp: App {
    @StateObject var d = ModelData()

    var body: some Scene {
        MenuBarExtra {
            Text(d.line)
            Divider()
            Button("Quit PingTray") { NSApp.terminate(nil) }
        } label: {
            if d.pingMS.isEmpty {
                Image(systemName: "bolt.slash")
            }
            Text("\(d.pingMS)ms")
        }
        .menuBarExtraStyle(.menu)
    }
}
