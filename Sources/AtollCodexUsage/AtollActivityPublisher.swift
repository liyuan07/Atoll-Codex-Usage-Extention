import AtollCodexUsageCore
import AtollExtensionKit
import Foundation

@MainActor
final class AtollActivityPublisher {
    static let activityID = "codex-usage"

    private let client: AtollClient
    private(set) var isPresented = false

    init(client: AtollClient) {
        self.client = client
    }

    convenience init() {
        self.init(client: AtollClient.shared)
    }

    func requestAuthorization() async throws -> Bool {
        try await client.requestAuthorization()
    }

    func publish(_ usage: CodexUsage) async throws {
        let descriptor = makeDescriptor(usage)
        if isPresented {
            do {
                try await client.updateLiveActivity(descriptor)
            } catch {
                try await client.presentLiveActivity(descriptor)
            }
        } else {
            try await client.presentLiveActivity(descriptor)
        }
        isPresented = true
    }

    func dismiss() async {
        guard isPresented else { return }
        try? await client.dismissLiveActivity(activityID: Self.activityID)
        isPresented = false
    }

    func observeDismissal(_ handler: @escaping () -> Void) {
        client.onActivityDismiss(activityID: Self.activityID) { [weak self] in
            self?.isPresented = false
            handler()
        }
    }

    private func makeDescriptor(_ usage: CodexUsage) -> AtollLiveActivityDescriptor {
        AtollLiveActivityDescriptor(
            id: Self.activityID,
            priority: .low,
            title: "Codex usage",
            subtitle: usage.plan?.uppercased(),
            leadingIcon: .symbol(name: "chevron.left.forwardslash.chevron.right", size: 15, weight: .semibold),
            trailingContent: .text(
                usage.notchText,
                font: .monospacedDigit(size: 11, weight: .semibold),
                color: .white
            ),
            accentColor: AtollColorDescriptor(red: 0.25, green: 0.85, blue: 0.68),
            allowsMusicCoexistence: true,
            metadata: ["fiveHourReset": resetString(usage.fiveHour.resetAt), "weeklyReset": resetString(usage.weekly.resetAt)],
            sneakPeekConfig: .disabled
        )
    }

    private func resetString(_ date: Date?) -> String {
        guard let date else { return "" }
        return String(Int(date.timeIntervalSince1970))
    }
}
