import Foundation

public struct WindowUsage: Equatable, Sendable {
    public let usedFraction: Double
    public let resetAt: Date?

    public init(usedFraction: Double, resetAt: Date?) {
        self.usedFraction = min(max(usedFraction, 0), 1)
        self.resetAt = resetAt
    }

    public var usedPercent: Int {
        Int((usedFraction * 100).rounded())
    }

    public var remainingFraction: Double {
        1 - usedFraction
    }

    public var remainingPercent: Int {
        Int((remainingFraction * 100).rounded())
    }
}

public enum CodexResetTimeFormatter {
    public static func description(
        for date: Date?,
        includeDate: Bool,
        timeZone: TimeZone = .current
    ) -> String {
        guard let date else { return "reset —" }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = includeDate ? "HH:mm 'on' d MMM" : "HH:mm"
        return "↻ \(formatter.string(from: date))"
    }
}

public struct CodexUsage: Equatable, Sendable {
    public let fiveHour: WindowUsage
    public let weekly: WindowUsage
    public let plan: String?
    public let tokenUsage: CodexTokenUsage

    public init(
        fiveHour: WindowUsage,
        weekly: WindowUsage,
        plan: String?,
        tokenUsage: CodexTokenUsage = .zero
    ) {
        self.fiveHour = fiveHour
        self.weekly = weekly
        self.plan = plan
        self.tokenUsage = tokenUsage
    }

    public var notchText: String {
        "5h \(fiveHour.remainingPercent)% left · 1w \(weekly.remainingPercent)% left"
    }
}

public enum CodexUsageError: LocalizedError, Equatable {
    case missingCredentials
    case expiredCredentials
    case httpStatus(Int)
    case malformedResponse
    case transport(String)

    public var errorDescription: String? {
        switch self {
        case .missingCredentials:
            return "No Codex login found — run codex login"
        case .expiredCredentials:
            return "Codex login expired — run codex login"
        case .httpStatus(let status):
            return "Codex usage request failed (HTTP \(status))"
        case .malformedResponse:
            return "Codex returned an unsupported usage response"
        case .transport(let message):
            return "Could not refresh Codex usage: \(message)"
        }
    }
}

public protocol CodexTokenProviding: Sendable {
    func accessToken() throws -> String
}

public struct CodexAuthFileTokenProvider: CodexTokenProviding {
    private let authURL: URL

    public init(authURL: URL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".codex/auth.json")) {
        self.authURL = authURL
    }

    public func accessToken() throws -> String {
        guard let data = try? Data(contentsOf: authURL),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tokens = object["tokens"] as? [String: Any],
              let token = tokens["access_token"] as? String,
              !token.isEmpty
        else {
            throw CodexUsageError.missingCredentials
        }
        return token
    }
}

public struct CodexUsageFetcher: Sendable {
    public static let endpoint = URL(string: "https://chatgpt.com/backend-api/wham/usage")!

    private let tokenProvider: any CodexTokenProviding
    private let endpoint: URL

    public init(tokenProvider: any CodexTokenProviding = CodexAuthFileTokenProvider(), endpoint: URL = CodexUsageFetcher.endpoint) {
        self.tokenProvider = tokenProvider
        self.endpoint = endpoint
    }

    public func fetch() async throws -> CodexUsage {
        let token = try tokenProvider.accessToken()
        var request = URLRequest(url: endpoint)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        // Fail quickly so the curl transport fallback can still complete within
        // the extension's initial refresh window on affected TLS setups.
        request.timeoutInterval = 4

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            if status == 401 { throw CodexUsageError.expiredCredentials }
            guard status == 200 else { throw CodexUsageError.httpStatus(status) }
            let usage = try Self.decode(data: data)
            let tokens = await Task.detached(priority: .utility) {
                CodexTokenUsageScanner.scan()
            }.value
            return CodexUsage(
                fiveHour: usage.fiveHour,
                weekly: usage.weekly,
                plan: usage.plan,
                tokenUsage: tokens
            )
        } catch let error as CodexUsageError {
            throw error
        } catch {
            // Some macOS network configurations reject the endpoint's TLS
            // connection in URLSession even though the system curl succeeds.
            // Use curl only as a transport fallback; credentials are supplied
            // through its standard input, never command-line arguments.
            do {
                let data = try await Self.fetchUsingCurl(token: token, endpoint: endpoint)
                let usage = try Self.decode(data: data)
                let tokens = await Task.detached(priority: .utility) {
                    CodexTokenUsageScanner.scan()
                }.value
                return CodexUsage(
                    fiveHour: usage.fiveHour,
                    weekly: usage.weekly,
                    plan: usage.plan,
                    tokenUsage: tokens
                )
            } catch let fallbackError as CodexUsageError {
                throw fallbackError
            } catch {
                throw CodexUsageError.transport(error.localizedDescription)
            }
        }
    }

    private static func fetchUsingCurl(token: String, endpoint: URL) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let input = Pipe()
            let output = Pipe()
            let errorOutput = Pipe()

            process.executableURL = URL(fileURLWithPath: "/usr/bin/curl")
            process.arguments = [
                "--silent", "--show-error", "--fail",
                "--config", "-",
                endpoint.absoluteString
            ]
            process.standardInput = input
            process.standardOutput = output
            process.standardError = errorOutput
            process.terminationHandler = { completedProcess in
                let data = output.fileHandleForReading.readDataToEndOfFile()
                let errors = errorOutput.fileHandleForReading.readDataToEndOfFile()
                if completedProcess.terminationStatus == 0 {
                    continuation.resume(returning: data)
                } else {
                    let message = String(data: errors, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                    continuation.resume(throwing: CodexUsageError.transport(message?.isEmpty == false ? message! : "curl fallback failed"))
                }
            }

            do {
                try process.run()
                let escapedToken = token
                    .replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "\"", with: "\\\"")
                    .replacingOccurrences(of: "\n", with: "")
                    .replacingOccurrences(of: "\r", with: "")
                let config = "header = \"Authorization: Bearer \(escapedToken)\"\nheader = \"Accept: application/json\"\nconnect-timeout = 15\nmax-time = 20\n"
                input.fileHandleForWriting.write(Data(config.utf8))
                try input.fileHandleForWriting.close()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    public static func decode(data: Data) throws -> CodexUsage {
        // The response can also contain `additional_rate_limits`, including a
        // separate GPT-5.3-Codex-Spark allowance. Decode only the top-level
        // `rate_limit`, which is the first/default allowance shown by /status.
        guard let response = try? JSONDecoder().decode(UsageResponse.self, from: data),
              let primary = parseWindow(response.rateLimit.primaryWindow)
        else {
            throw CodexUsageError.malformedResponse
        }
        // The service can omit `secondary_window` immediately after a weekly
        // reset. In that state the weekly allowance is fresh; use a full
        // allowance until the server begins returning the window again.
        let secondary = response.rateLimit.secondaryWindow
            .flatMap(parseWindow)
            ?? WindowUsage(usedFraction: 0, resetAt: nil)

        return CodexUsage(
            fiveHour: primary,
            weekly: secondary,
            plan: response.planType
        )
    }

    private static func parseWindow(_ window: UsageWindow) -> WindowUsage? {
        guard window.usedPercent.isFinite else {
            return nil
        }

        let resetAt = window.resetAt.map(Date.init(timeIntervalSince1970:))
        return WindowUsage(usedFraction: window.usedPercent / 100, resetAt: resetAt)
    }

    private struct UsageResponse: Decodable {
        let planType: String?
        let rateLimit: RateLimit

        private enum CodingKeys: String, CodingKey {
            case planType = "plan_type"
            case rateLimit = "rate_limit"
        }
    }

    private struct RateLimit: Decodable {
        let primaryWindow: UsageWindow
        let secondaryWindow: UsageWindow?

        private enum CodingKeys: String, CodingKey {
            case primaryWindow = "primary_window"
            case secondaryWindow = "secondary_window"
        }
    }

    private struct UsageWindow: Decodable {
        let usedPercent: Double
        let resetAt: Double?

        private enum CodingKeys: String, CodingKey {
            case usedPercent = "used_percent"
            case resetAt = "reset_at"
        }
    }
}
