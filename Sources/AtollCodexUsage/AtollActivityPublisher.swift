import AtollCodexUsageCore
import Foundation

@MainActor
final class AtollActivityPublisher {
    static let activityID = "codex-usage"
    static let experienceID = "codex-usage-tab"

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
                "title": "Codex",
                "iconSymbolName": "chevron.left.forwardslash.chevron.right",
                "preferredHeight": 250,
                "allowWebInteraction": true,
                "sections": [],
                "webContent": [
                    "html": dashboardHTML(for: usage),
                    "preferredHeight": 178,
                    "isTransparent": true,
                    "allowLocalhostRequests": false,
                    "allowRemoteRequests": false,
                    "maximumContentWidth": 640
                ],
                "footnote": footerText(for: usage)
            ]
        ]
    }

    private func accentColor() -> [String: Any] {
        ["red": 0.25, "green": 0.85, "blue": 0.68, "alpha": 1]
    }

    private func dashboardHTML(for usage: CodexUsage) -> String {
        let plan = htmlEscape((usage.plan ?? "plus").uppercased())
        let generatedAt = Int(Date().timeIntervalSince1970 * 1000)
        let fiveReset = htmlEscape(relativeResetDescription(usage.fiveHour.resetAt))
        let weeklyReset = htmlEscape(relativeResetDescription(usage.weekly.resetAt))
        let five = usage.fiveHour.remainingPercent
        let week = usage.weekly.remainingPercent
        let fiveBars = barSegments(filledPercent: five)
        let weekBars = barSegments(filledPercent: week)

        return """
        <!doctype html><html><head><meta charset="utf-8"><style>
        *{box-sizing:border-box}html,body{margin:0;background:transparent;color:#f6f7fb;font-family:-apple-system,BlinkMacSystemFont,"SF Pro Display",sans-serif;overflow:hidden}
        body{height:178px;outline:none}.wrap{position:relative;height:178px;padding:2px 8px 0}
        .top{display:flex;align-items:center;justify-content:center;height:30px;gap:9px}.brand{font-size:18px;font-weight:750;letter-spacing:.2px}.pill{font-size:10px;font-weight:800;color:#c9c9cf;background:#ffffff16;border:1px solid #ffffff12;border-radius:5px;padding:2px 6px}
        .pages{position:relative;height:122px}.page{position:absolute;inset:0;display:grid;grid-template-columns:1fr 1fr;gap:34px;opacity:0;transform:translateX(16px);transition:opacity .18s ease,transform .18s ease}.page.active{opacity:1;transform:translateX(0)}
        .metric{padding-top:7px}.row{display:flex;align-items:flex-end;justify-content:space-between;margin-bottom:9px}.label{font-size:13px;color:#a8aab3;font-weight:800}.value{font-size:28px;font-weight:850;line-height:.85;letter-spacing:.2px}.value span{font-size:13px;color:#a8aab3;margin-left:2px}
        .bar{display:grid;grid-template-columns:repeat(34,1fr);gap:3px;height:20px;margin-bottom:10px}.seg{height:20px;border-radius:3px;background:#ffffff13}.seg.on{background:#75c6ff;box-shadow:0 0 7px #58baff70}.reset{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:12px;font-weight:750;color:#a6a8b0}
        .stats{grid-template-columns:1fr 1fr 1fr}.big{font-size:38px;font-weight:800;color:#73c4ff;text-shadow:0 0 15px #4db3ff70;line-height:1}.cap{font-size:12px;color:#a8aab3;font-weight:750;margin-top:8px}.status{position:absolute;right:8px;bottom:0;font-size:13px;font-weight:760;color:#d9dbe2}.dotgreen{display:inline-block;width:8px;height:8px;border-radius:50%;background:#30d98b;box-shadow:0 0 8px #30d98b;margin-right:7px}
        .nav{position:absolute;left:8px;bottom:3px;display:flex;gap:7px}.nav button{width:8px;height:8px;border-radius:50%;border:0;padding:0;background:#ffffff45}.nav button.active{background:#fff}.hint{position:absolute;left:36px;bottom:0;font-size:11px;color:#ffffff45;font-weight:700}
        </style></head><body tabindex="0"><div class="wrap"><div class="top"><div class="brand">Codex</div><div class="pill">\(plan)</div></div>
        <div class="pages">
        <section class="page active" id="p0">
        <div class="metric"><div class="row"><div class="label">5h</div><div class="value">\(five)<span>%</span></div></div><div class="bar">\(fiveBars)</div><div class="reset">resets \(fiveReset)</div></div>
        <div class="metric"><div class="row"><div class="label">week</div><div class="value">\(week)<span>%</span></div></div><div class="bar">\(weekBars)</div><div class="reset">resets \(weeklyReset)</div></div>
        </section>
        <section class="page stats" id="p1">
        <div><div class="big">\(five)<span style="font-size:17px;color:#8da3b8">%</span></div><div class="cap">5h left</div></div>
        <div><div class="big">\(week)<span style="font-size:17px;color:#8da3b8">%</span></div><div class="cap">weekly left</div></div>
        <div><div class="big">5<span style="font-size:17px;color:#8da3b8">m</span></div><div class="cap">refresh</div></div>
        </section></div>
        <div class="nav"><button class="active" onclick="show(0)"></button><button onclick="show(1)"></button></div><div class="hint">← →</div><div class="status"><span class="dotgreen"></span>synced <span id="age">now</span></div></div>
        <script>let page=0,ts=\(generatedAt);function show(n){page=n;document.querySelectorAll('.page').forEach((p,i)=>p.classList.toggle('active',i===n));document.querySelectorAll('.nav button').forEach((b,i)=>b.classList.toggle('active',i===n))}document.addEventListener('keydown',e=>{if(e.key==='ArrowRight')show((page+1)%2);if(e.key==='ArrowLeft')show((page+1)%2)});function tick(){let s=Math.max(0,Math.floor((Date.now()-ts)/1000));document.getElementById('age').textContent=s<2?'now':s+'s ago'}setInterval(tick,1000);tick();window.focus();</script>
        </body></html>
        """
    }

    private func barSegments(filledPercent: Int) -> String {
        let filled = max(0, min(34, Int((Double(filledPercent) / 100 * 34).rounded())))
        return (0..<34).map { index in
            "<i class=\"seg\(index < filled ? " on" : "")\"></i>"
        }.joined()
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
