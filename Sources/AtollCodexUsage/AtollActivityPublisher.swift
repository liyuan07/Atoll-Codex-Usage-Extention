import AtollCodexUsageCore
import Foundation

@MainActor
final class AtollActivityPublisher {
    static let activityID = "codex-usage"

    private let client: AtollRPCClient
    private let bundleIdentifier = "dev.atoll.extensions.codexusage"
    private(set) var isPresented = false

    init(client: AtollRPCClient = AtollRPCClient()) {
        self.client = client
    }

    func requestAuthorization() async throws -> Bool {
        let result = try await client.call(
            method: "atoll.requestAuthorization",
            params: ["bundleIdentifier": bundleIdentifier]
        )
        return result["authorized"] as? Bool ?? false
    }

    func publish(_ usage: CodexUsage) async throws {
        let descriptor = makeDescriptor(usage)
        let method = isPresented ? "atoll.updateLiveActivity" : "atoll.presentLiveActivity"

        do {
            _ = try await client.call(method: method, params: ["descriptor": descriptor])
        } catch where isPresented {
            _ = try await client.call(method: "atoll.presentLiveActivity", params: ["descriptor": descriptor])
        }

        isPresented = true
    }

    func dismiss() async {
        guard isPresented else { return }
        _ = try? await client.call(
            method: "atoll.dismissLiveActivity",
            params: ["activityID": Self.activityID, "bundleIdentifier": bundleIdentifier]
        )
        isPresented = false
    }

    func observeDismissal(_ handler: @escaping () -> Void) {
        // The fallback RPC transport uses short-lived WebSocket calls and does not
        // keep a callback channel open. Manual Hide/Show remains available.
    }

    private func makeDescriptor(_ usage: CodexUsage) -> [String: Any] {
        var descriptor: [String: Any] = [
            "id": Self.activityID,
            "bundleIdentifier": bundleIdentifier,
            "priority": "low",
            "title": "Codex usage",
            "leadingIcon": [
                "type": "symbol",
                "name": "chevron.left.forwardslash.chevron.right",
                "size": 15,
                "weight": "semibold"
            ],
            "trailingContent": [
                "type": "text",
                "text": usage.notchText,
                "font": [
                    "size": 11,
                    "weight": "semibold",
                    "design": "default",
                    "isMonospacedDigit": true
                ],
                "color": ["red": 1, "green": 1, "blue": 1, "alpha": 1]
            ],
            "progress": 0,
            "accentColor": ["red": 0.25, "green": 0.85, "blue": 0.68, "alpha": 1],
            "allowsMusicCoexistence": true,
            "metadata": [
                "fiveHourReset": resetString(usage.fiveHour.resetAt),
                "weeklyReset": resetString(usage.weekly.resetAt)
            ],
            "centerTextStyle": "inheritUser",
            "sneakPeekConfig": ["enabled": false, "showOnUpdate": false]
        ]

        if let plan = usage.plan {
            descriptor["subtitle"] = plan.uppercased()
        }

        return descriptor
    }

    private func resetString(_ date: Date?) -> String {
        guard let date else { return "" }
        return String(Int(date.timeIntervalSince1970))
    }
}

final class AtollRPCClient {
    private let url: URL
    private let session: URLSession

    init(url: URL = URL(string: "ws://127.0.0.1:9020")!, session: URLSession = .shared) {
        self.url = url
        self.session = session
    }

    func call(method: String, params: [String: Any]) async throws -> [String: Any] {
        let task = session.webSocketTask(with: url)
        task.resume()
        defer { task.cancel(with: .goingAway, reason: nil) }

        let request: [String: Any] = [
            "jsonrpc": "2.0",
            "method": method,
            "params": params,
            "id": UUID().uuidString
        ]
        let data = try JSONSerialization.data(withJSONObject: request, options: [])
        guard let text = String(data: data, encoding: .utf8) else {
            throw AtollRPCError.invalidRequest
        }

        try await task.send(.string(text))
        let response = try await task.receive()
        let responseData: Data

        switch response {
        case .data(let data):
            responseData = data
        case .string(let string):
            responseData = Data(string.utf8)
        @unknown default:
            throw AtollRPCError.invalidResponse
        }

        guard let object = try JSONSerialization.jsonObject(with: responseData) as? [String: Any] else {
            throw AtollRPCError.invalidResponse
        }
        if let error = object["error"] as? [String: Any] {
            throw AtollRPCError.remote(error["message"] as? String ?? "Unknown Atoll RPC error")
        }
        guard let result = object["result"] as? [String: Any] else {
            throw AtollRPCError.invalidResponse
        }
        return result
    }
}

enum AtollRPCError: LocalizedError {
    case invalidRequest
    case invalidResponse
    case remote(String)

    var errorDescription: String? {
        switch self {
        case .invalidRequest:
            return "Could not encode Atoll RPC request."
        case .invalidResponse:
            return "Atoll RPC returned an invalid response."
        case .remote(let message):
            return "Atoll RPC error: \(message)"
        }
    }
}
