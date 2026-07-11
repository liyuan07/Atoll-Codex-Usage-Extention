import AtollCodexUsageCore
import Foundation

@MainActor
final class AtollActivityPublisher {
    static let activityID = "codex-usage"
    static let experienceID = "codex-usage-tab"
    // 64 px transparent ChatGPT/OpenAI mark, derived from the MIT-licensed
    // CodexIsland artwork and embedded so the extension has no runtime asset
    // dependency outside its own app bundle.
    private static let chatGPTMarkBase64 = "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"

    private let client: AtollRPCClient
    private let bundleIdentifier = "dev.atoll.extensions.codexusage"
    private(set) var isPresented = false
    private var dismissedLegacyLiveActivity = false

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
        if !dismissedLegacyLiveActivity {
            _ = try? await client.call(
                method: "atoll.dismissLiveActivity",
                params: ["activityID": Self.activityID, "bundleIdentifier": bundleIdentifier]
            )
            dismissedLegacyLiveActivity = true
        }

        let descriptor = makeNotchExperienceDescriptor(usage)
        let method = isPresented ? "atoll.updateNotchExperience" : "atoll.presentNotchExperience"

        do {
            _ = try await client.call(method: method, params: ["descriptor": descriptor])
        } catch where isPresented {
            _ = try await client.call(method: "atoll.presentNotchExperience", params: ["descriptor": descriptor])
        }

        isPresented = true
    }

    func dismiss() async {
        guard isPresented else { return }
        _ = try? await client.call(
            method: "atoll.dismissNotchExperience",
            params: ["experienceID": Self.experienceID, "bundleIdentifier": bundleIdentifier]
        )
        isPresented = false
    }

    func observeDismissal(_ handler: @escaping () -> Void) {
        // The fallback RPC transport uses short-lived WebSocket calls and does not
        // keep a callback channel open. Manual Hide/Show remains available.
    }

    private func makeNotchExperienceDescriptor(_ usage: CodexUsage) -> [String: Any] {
        [
            "id": Self.experienceID,
            "bundleIdentifier": bundleIdentifier,
            "priority": "normal",
            "accentColor": accentColor(),
            "metadata": [
                "fiveHourReset": resetString(usage.fiveHour.resetAt),
                "weeklyReset": resetString(usage.weekly.resetAt),
                "plan": usage.plan ?? ""
            ],
            "tab": [
                // Atoll currently always reserves a native tab header. An invisible
                // title removes the duplicated "Codex" text while preserving the
                // tab's icon in Atoll's extension ecosystem.
                "title": "\u{200B}",
                "iconSymbolName": "sparkles",
                "badgeIcon": [
                    "type": "image",
                    "data": Self.chatGPTMarkBase64,
                    // CGSize's Codable representation in the Atoll RPC
                    // transport is an ordered [width, height] pair.
                    "size": [32, 32],
                    "cornerRadius": 0
                ],
                "preferredHeight": 300,
                "allowWebInteraction": true,
                "sections": [],
                "webContent": [
                    "html": dashboardHTML(for: usage),
                    "preferredHeight": 162,
                    "isTransparent": true,
                    "allowLocalhostRequests": false,
                    "allowRemoteRequests": false,
                    "maximumContentWidth": 640
                ]
            ]
        ]
    }

    private func accentColor() -> [String: Any] {
        ["red": 0.25, "green": 0.85, "blue": 0.68, "alpha": 1]
    }

    private func dashboardHTML(for usage: CodexUsage) -> String {
        let plan = htmlEscape((usage.plan ?? "plus").uppercased())
        let fiveReset = htmlEscape(resetTimeDescription(usage.fiveHour.resetAt))
        let weeklyReset = htmlEscape(resetTimeDescription(usage.weekly.resetAt))
        let five = usage.fiveHour.remainingPercent
        let week = usage.weekly.remainingPercent
        let fiveHourTokens = compactTokenCount(usage.tokenUsage.fiveHour)
        let dailyTokens = compactTokenCount(usage.tokenUsage.twentyFourHour)
        let weeklyTokens = compactTokenCount(usage.tokenUsage.weekly)
        let fiveBars = barSegments(filledPercent: five)
        let weekBars = barSegments(filledPercent: week)

        return """
        <!doctype html><html><head><meta charset="utf-8"><style>
        *{box-sizing:border-box}html,body{margin:0;background:transparent;color:#f6f7fb;font-family:-apple-system,BlinkMacSystemFont,"SF Pro Display",sans-serif;overflow:hidden}
        body{height:162px;outline:none}.wrap{position:relative;height:162px;padding:2px 10px 0}.dashboard{height:140px;transform:translateY(-38px)}
        .quota{height:62px;display:grid;grid-template-columns:102px minmax(0,1fr) minmax(0,1fr);gap:24px}.identity{height:62px;display:flex;align-items:center;justify-content:flex-start;gap:7px}.openai{width:21px;height:21px;color:#f5f6f8;filter:drop-shadow(0 0 5px #ffffff28)}.pill{font-size:10px;font-weight:800;color:#d4d4da;background:#ffffff16;border:1px solid #ffffff12;border-radius:5px;padding:3px 7px;letter-spacing:.45px}
        .metric{padding-top:11px}.row{display:flex;align-items:baseline;justify-content:space-between;margin-bottom:8px}.label{font-size:13px;color:#a8aab3;font-weight:800;white-space:nowrap}.value-line{display:flex;align-items:baseline;gap:7px}.value{font-size:26px;font-weight:850;line-height:.85;letter-spacing:.2px}.value span{font-size:12px;color:#a8aab3;margin-left:2px}.inline-reset{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:10px;font-weight:750;color:#a6a8b0;white-space:nowrap}
        .bar{display:grid;grid-template-columns:repeat(30,1fr);gap:3px;height:14px}.seg{height:14px;border-radius:3px;background:#ffffff13}.seg.on{background:#75c6ff;box-shadow:0 0 7px #58baff70}
        .tokens{height:70px;display:grid;grid-template-columns:1fr 1fr 1fr;gap:0;border-top:1px solid #ffffff12}.stat{padding:9px 16px 0}.stat:not(:last-child){border-right:1px solid #ffffff12}.token-label{font-size:12px;color:#a8aab3;font-weight:800}.token-value{font-size:25px;font-weight:820;color:#73c4ff;text-shadow:0 0 15px #4db3ff70;line-height:1;margin-top:5px}.cap{font-size:10px;color:#737680;font-weight:750;margin-top:3px}.status{position:absolute;right:10px;bottom:0;font-size:10px;font-weight:760;color:#d9dbe2}.dotgreen{display:inline-block;width:7px;height:7px;border-radius:50%;background:#30d98b;box-shadow:0 0 8px #30d98b;margin-right:6px}
        </style></head><body><div class="wrap"><div class="dashboard">
        <section class="quota">
        <div class="identity"><svg class="openai" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.1" stroke-linecap="round" stroke-linejoin="round" aria-label="OpenAI"><path d="M12 3.2a4.3 4.3 0 0 1 7.37 3.03 4.3 4.3 0 0 1 1.95 7.73 4.3 4.3 0 0 1-5.41 5.83A4.3 4.3 0 0 1 8.63 20a4.3 4.3 0 0 1-5.95-5.3A4.3 4.3 0 0 1 4.6 7.04 4.3 4.3 0 0 1 12 3.2Z"/><path d="m8.1 7.1 7.8 4.5v8.1M4.7 14.5l7.3-4.2 7.2 4.2M12 3.2v8.4l-7.3 4.2"/></svg><div class="pill">\(plan)</div></div>
        <div class="metric"><div class="row"><div class="label">5h</div><div class="value-line"><div class="inline-reset">\(fiveReset)</div><div class="value">\(five)<span>%</span></div></div></div><div class="bar">\(fiveBars)</div></div>
        <div class="metric"><div class="row"><div class="label">1 week</div><div class="value-line"><div class="inline-reset">\(weeklyReset)</div><div class="value">\(week)<span>%</span></div></div></div><div class="bar">\(weekBars)</div></div>
        </section>
        <section class="tokens">
        <div class="stat"><div class="token-label">5h</div><div class="token-value">\(fiveHourTokens)</div><div class="cap">tokens used</div></div>
        <div class="stat"><div class="token-label">24h</div><div class="token-value">\(dailyTokens)</div><div class="cap">tokens used</div></div>
        <div class="stat"><div class="token-label">1 week</div><div class="token-value">\(weeklyTokens)</div><div class="cap">tokens used</div></div>
        </section></div><div class="status"><span class="dotgreen"></span>synced</div></div>
        </body></html>
        """
    }

    private func barSegments(filledPercent: Int) -> String {
        let segmentCount = 30
        let filled = max(0, min(segmentCount, Int((Double(filledPercent) / 100 * Double(segmentCount)).rounded())))
        return (0..<segmentCount).map { index in
            "<i class=\"seg\(index < filled ? " on" : "")\"></i>"
        }.joined()
    }

    private func compactTokenCount(_ value: Int) -> String {
        switch value {
        case 1_000_000...:
            return String(format: "%.1fM", Double(value) / 1_000_000)
        case 1_000...:
            return String(format: "%.1fK", Double(value) / 1_000)
        default:
            return "\(value)"
        }
    }

    private func relativeResetDescription(_ date: Date?) -> String {
        guard let date else { return "later" }
        let seconds = max(0, Int(date.timeIntervalSinceNow.rounded()))
        let days = seconds / 86_400
        let hours = (seconds % 86_400) / 3_600
        let minutes = (seconds % 3_600) / 60
        if days > 0 { return "in \(days)d" }
        if hours > 0 { return "in \(hours)h" }
        return "in \(max(1, minutes))m"
    }

    private func resetTimeDescription(_ date: Date?) -> String {
        guard let date else { return "reset —" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "HH:mm"
        return "↻ \(formatter.string(from: date))"
    }

    private func htmlEscape(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }

    private func resetDescription(_ date: Date?) -> String {
        guard let date else { return "Reset time unavailable" }
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return "Resets at \(formatter.string(from: date))"
    }

    private func footerText(for usage: CodexUsage) -> String {
        if let plan = usage.plan, !plan.isEmpty {
            return "\(plan.uppercased()) · Updated every 5 minutes"
        }
        return "Updated every 5 minutes"
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
