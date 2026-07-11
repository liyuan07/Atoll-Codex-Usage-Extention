import AtollCodexUsageCore
import Foundation

@MainActor
final class AtollActivityPublisher {
    static let activityID = "codex-usage"
    static let experienceID = "codex-usage-tab"
    // OpenAI's official Blossom on a 64 px canvas, inset to 48 px and rendered
    // at 65% opacity so the inactive tab matches Atoll's native SF Symbols.
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
                "preferredHeight": 200,
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
        body{height:162px;outline:none}.wrap{position:relative;height:162px;padding:2px 10px 0}.dashboard{position:relative;height:140px}
        .quota{height:62px;display:grid;grid-template-columns:102px minmax(0,1fr) minmax(0,1fr);gap:24px}.identity{position:absolute;left:0;top:0;width:102px;height:132px;display:flex;align-items:center;justify-content:flex-start;gap:7px}.openai{width:21px;height:21px;color:#f5f6f8;filter:drop-shadow(0 0 5px #ffffff28)}.pill{font-size:10px;font-weight:800;color:#d4d4da;background:#ffffff16;border:1px solid #ffffff12;border-radius:5px;padding:3px 7px;letter-spacing:.45px}
        .metric{padding-top:11px}.row{display:flex;align-items:baseline;justify-content:space-between;margin-bottom:8px}.label{font-size:13px;color:#a8aab3;font-weight:800;white-space:nowrap}.value-line{display:flex;align-items:baseline;gap:7px}.value{font-size:26px;font-weight:850;line-height:.85;letter-spacing:.2px}.value span{font-size:12px;color:#a8aab3;margin-left:2px}.inline-reset{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:10px;font-weight:750;color:#a6a8b0;white-space:nowrap}
        .bar{display:grid;grid-template-columns:repeat(30,1fr);gap:3px;height:14px}.seg{height:14px;border-radius:3px;background:#ffffff13}.seg.on{background:#75c6ff;box-shadow:0 0 7px #58baff70}
        .tokens{height:70px;margin-left:126px;display:grid;grid-template-columns:1fr 1fr 1fr;gap:0;border-top:1px solid #ffffff12}.stat{padding:9px 16px 0}.stat:not(:last-child){border-right:1px solid #ffffff12}.token-label{font-size:12px;color:#a8aab3;font-weight:800}.token-value{font-size:25px;font-weight:820;color:#73c4ff;text-shadow:0 0 15px #4db3ff70;line-height:1;margin-top:5px}.cap{font-size:10px;color:#737680;font-weight:750;margin-top:3px}.status{position:absolute;right:10px;bottom:0;font-size:10px;font-weight:760;color:#d9dbe2}.dotgreen{display:inline-block;width:7px;height:7px;border-radius:50%;background:#30d98b;box-shadow:0 0 8px #30d98b;margin-right:6px}
        </style></head><body><div class="wrap"><div class="dashboard">
        <section class="quota">
        <div class="identity"><svg class="openai" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.1" stroke-linecap="round" stroke-linejoin="round" aria-label="OpenAI"><path d="M12 3.2a4.3 4.3 0 0 1 7.37 3.03 4.3 4.3 0 0 1 1.95 7.73 4.3 4.3 0 0 1-5.41 5.83A4.3 4.3 0 0 1 8.63 20a4.3 4.3 0 0 1-5.95-5.3A4.3 4.3 0 0 1 4.6 7.04 4.3 4.3 0 0 1 12 3.2Z"/><path d="m8.1 7.1 7.8 4.5v8.1M4.7 14.5l7.3-4.2 7.2 4.2M12 3.2v8.4l-7.3 4.2"/></svg><div class="pill">\(plan)</div></div>
        <div aria-hidden="true"></div>
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
