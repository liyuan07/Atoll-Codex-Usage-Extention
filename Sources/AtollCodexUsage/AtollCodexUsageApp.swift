import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        UsageController.shared.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        UsageController.shared.stop()
    }
}

@main
struct AtollCodexUsageApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var controller = UsageController.shared

    var body: some Scene {
        MenuBarExtra("Atoll Codex Usage", systemImage: "chevron.left.forwardslash.chevron.right") {
            VStack(alignment: .leading, spacing: 8) {
                Text(controller.status)
                    .font(.system(.body, design: .monospaced))
                    .lineLimit(2)
                if let lastUpdated = controller.lastUpdated {
                    Text("Updated \(lastUpdated.formatted(date: .omitted, time: .shortened))")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)

            Divider()

            Button(controller.displayEnabled ? "Hide from Atoll" : "Show in Atoll") {
                if controller.displayEnabled {
                    controller.hideDisplay()
                } else {
                    controller.restoreDisplay()
                }
            }

            Button("Refresh Now") {
                Task { await controller.refresh() }
            }
            .disabled(controller.isRefreshing)

            Divider()

            Button("Quit") {
                Task { await controller.quit() }
            }
        }
        .menuBarExtraStyle(.menu)
    }
}
