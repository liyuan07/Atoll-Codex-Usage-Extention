import AtollCodexUsageCore
import Foundation

@MainActor
final class AtollActivityPublisher {
    static let activityID = "codex-usage"
    static let experienceID = "codex-usage-tab"
    // 64 px transparent ChatGPT/OpenAI Blossom from OpenAI's official brand
    // artwork, embedded so the extension has no runtime asset dependency.
    private static let chatGPTMarkBase64 = "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAQAAAAAYLlVAAAAIGNIUk0AAHomAACAhAAA+gAAAIDoAAB1MAAA6mAAADqYAAAXcJy6UTwAAAACYktHRAAAqo0jMgAAAAd0SU1FB+oHCw86CUkD6LUAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjYtMDctMTFUMTU6NTg6MDkrMDA6MDBqpRbrAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI2LTA3LTExVDE1OjU4OjA5KzAwOjAwG/iuVwAAACh0RVh0ZGF0ZTp0aW1lc3RhbXAAMjAyNi0wNy0xMVQxNTo1ODowOSswMDowMEztj4gAAAlhSURBVGjerZlpkFTVFcf/3dMDMyzKIiP7KgyDLEKGTJAKgaAxFJshVpApCZUBtBCiWMaIhbFcYsLqUqYKkCUCBUSQABq0hIAIEVCBIDASmLCHXXAYYEBmmF8+9H2373vdM91Ded6Hfn3fvef8z3LPPee9kFIgvJsMNVdntVc7Sed1QEe1Xxe8h6FUWMVR0lVWeFP9QgPUSY1VU2FJUpkuq0gb9JG+0I1bh5BEPEI04km+ojIqZhHdUKLr+xF/L5+SjE7wOBlmfhoRIkRSAxKqSrwkKV/T1dQMlemY9uprlUtKUwflqL0y7LM39VflKlsdVUMSOqTD+rf26lKK3k6ofT7fGB2vsYoRNCPd6hUmi4G8yxUzo5xz3AxY5jKf8iQtbsElCNGH04bRfh6xJvZfYR7lUhIHFTKe2tWCgBBN2GoYfMbdQR3M/wj9+IAyR1gFpZzlAuU+COUspnU1ICDEc2bxDjomFC46MsvRvow9zCCf+8jmHoYygSUcdkBsol2KEBCiNf8B4Cz93WVWeBbPUOSw/4pR3BlwTxpteIoDQQipAZhkFs1IID6DfD5zhJ/keZpX4iTRkfesQ1ZTLykEhKjDFsO6s7fAsAvRkxVct8JLWEL3yqLcjNdluoFQwaQqAVjU93AOgFVEcMdbM4Ozjtc/YZC3MeU3v59jHZabNcejWbNy4RFyeY5tVAAw2WFdnwmOP2Evj3NbTBjerDZRMwec0YH9Zt30hADM8hzm2dQDNxhqAdzGcgMq6poptIzpau4yGcl2TrKZIdSIs8MEs/5rmpNQfIRHOOjbvVfoZbXrYTfcNZaRGyc8TC9W2ti4yoK4OY3NgWbV8ouvxRSuBjKYCyDXADjCcC8nOl5vy2tcCKw+xYs08cXFNPPkVR8AhEhnms3jZaxld6UAFsfpXp/xFPqyXox2UOAlYcQQkzM/pAYB34+h1EbpeGoxp1IAi3zCI/ycDU5slPA2D7GEa3bkO96nNyGE6GR20AZq+gH8yB46O+mDEHOrBmCuriyk2NH8QwYQQWQylC3OyfgNU2mPaMFxs3+yXADpLDMTi+hpWCcH0JRXOGFFVLCT33ibEiHuYLwvpA8wjq4cA6CQxi6AvoZ1CYPs8soBLETUJZ9dvoC7xrMJElJbppuEFo2tHaZ22EhGDECERWbCHKeMqhzAEvrwATcIUinL+WGCzdmT5U5ERGkV6TEAORwF4Fw0oysZgDOcd3TayGanGjjNDO/Ud0BkMMJm1ijNdJIUBUabtV5kJgEQoy8Yye3czji+dkYLKYilYicinnUO7z1eFS2J2WbQnlIpATjKszS17FsylZOOXf7Jz0iLA5HNLOuMHbYyYLvZQkNTBnCe16OHtHOF6MICB+IlZtE1zhnpjOeMmbEsmqDEHgCKyfMdHJUD2GUyRXzpkc799sSLWul5z0rOrAJjhXIeRZgmSyqN9XhJaI82S1LIqfPNfZnW60tnZiu9ojV6WJlR4Wb+Ys2XJKXpMWVJYTNeTy0TiqtwusMohaMig+QbIdorSsrVAv1NvRWSB6FM07RbktRdQ6WwTkmSaiorTpRUQzlRftWkK/qDPjIgMjVEa/QnNbB8jmu2kBTSQ6ob1i6jV24ChdI1RS+pSXXlC63XMI3TPvO/oSZprGOnj3VIktRDOWFtU6kkqZ8aOboWmd879YLWqkAZulktCGm6rgUarFd11oy0dzQ7ri8kSfWVF9bnKpQkddMAh8E8vaVic99ds7VMP7YBmzod1fOapDJjlRhV6HMDs1NYZ7Xa/BkT9VNIki5oon6ldaowrnhQ01S7etKNuffbgHTpsMqjN2FJK3REktRb4xyoFVqv4XrM+rGm4VgRVEdKPGIghBOOWgpLKtJcISmsp/VLb1JIkoo1T4P0ks44K7rqp0pTXCKSVEP3q2eK5glksfqss+fZ8ARZPNd5CwDFvEWXQCoWP2CpTcWXyLXZr5dZOdeXEUea03G2N9CVnWZxCW8mOFJrMoQtTrl5khdi3SB38TqnnCScHMBUM/PlmIhuzmuoAzxBgzgd6/FbX5G1h1HUowFPmz46JQAIUdd0niU8EMMkUwljjop/MTRB/Z/NG77OaRvbnOLzpDnrkgHoz2UA9tEsFgkZbAjocZXltkiNgQjRhw+c7tijEhbRjSVVA0CITN4za2a4pWkzU7FcpcjR6TQvJ4iI2kz21Xk32cgDpCMWpgBgLN8Ze3VxAbTlfwAcJ4+nTJ0Ypb086hVZCNGAiex3arxCnrDPFyUF0Nfyfs3Zyog2FkALRDZv8a2j4ToGk47IZBhbHQudYRptHXDJANzHf61abf0AWnLEAGiFEGncx0fGWABXmM8oVjsNbClL6BVwT+UueJv6TLQvN4p5yE1lQtRiMwDfxtpqalPADscZFc7ddobF3gGY+RHerxTAPrbaPFLM6Gi36AII8Y55PM63+5vwoi/JABxmIllxW7Q24ykxO6JnHIAYFTPaX1N6TMaaCeupG5eKF1jTX+QNOsTtiwj9+dhuzlN0sADuDQDYxYMB7S2EbBOG113/GAE1GMgaTrCWfoTjdO/EfKdLvs6fnVdbI5yQPcIfvRc7CY4nwvzFTNxEwwRldyatqBVXZjfmaRO+XmzkU9MBOBmAcj5hEtnBgj7ohO4mlVYwM5aG5eoaTEgP87lj3uM8RyMfxEzWA3CUu6oQ7gSi9xannGlkJl5gGIXpy0qnSy5hVuy7iZ3X27hmafSQr5IQ4g4+NgzLWOgm4YAlOvEmF63wMv7B/V5z78yMmA6rjPyk4hVjHWuv9vEUbbwCxV4t+T2HHMMXMia6b+JcNtiUKFv9MeVSoKGRJPXVTPWwg0e0TVt1Whd1Q41VT3n6ibLt09NaoDk64Wdl+ORouTpLKtdYvZPiJxtb4az0fYSAm1zhUuCDTKn7tSzOSb3ZZuatMH1wamSW1wm8+0tEF/h1nHuiV30mmJwC+2Lv26sHQbTgGbab5BqjMif4rvAuA8nyUhMinTYUONVjIXlVb75QZSAM1VNndVdbtVNIIRXroAp1TGM1WmlmxnUVab8O6qakWrpbOWple4F9GhPtgW7pm6rPqNFPkZ6mmfwu7oAK0g3+Tk6S1HMLQGJXHkud/B90025GUycV8bdoG0lSuvI0QP3VXnWVprCkcl3TeX2pVdrkdcXJBNziB29Hr4bKUUs1Vztd1V6dUpFOmH44Jeb/Bx3lxgG0hDyqAAAAAElFTkSuQmCC"

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
