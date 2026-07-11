import AtollCodexUsageCore
import Foundation

@main
enum CodexUsageTests {
    private static var failures = 0

    static func main() {
        run("decodes both Codex windows", decodesBothCodexWindows)
        run("ignores additional model limits", ignoresAdditionalModelLimits)
        run("clamps invalid percentages", clampsInvalidPercentages)
        run("rejects a missing window", rejectsMissingWindow)
        run("rejects a missing percentage", rejectsMissingPercentage)

        if failures > 0 {
            exit(1)
        }
        print("All Codex usage tests passed")
    }

    private static func run(_ name: String, _ test: () throws -> Void) {
        do {
            try test()
            print("PASS: \(name)")
        } catch {
            failures += 1
            print("FAIL: \(name) — \(error)")
        }
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        guard condition() else { throw TestFailure(message) }
    }

    private static func decodesBothCodexWindows() throws {
        let data = Data("""
        {
          "plan_type": "pro",
          "rate_limit": {
            "primary_window": { "used_percent": 32.4, "reset_at": 1760000000 },
            "secondary_window": { "used_percent": 61, "reset_at": 1760500000 }
          }
        }
        """.utf8)

        let usage = try CodexUsageFetcher.decode(data: data)

        try expect(usage.fiveHour.usedPercent == 32, "5h should be 32%")
        try expect(usage.weekly.usedPercent == 61, "1w should be 61%")
        try expect(usage.plan == "pro", "plan should be pro")
        try expect(usage.notchText == "5h 68% left · 1w 39% left", "notch text should match")
    }

    private static func clampsInvalidPercentages() throws {
        let data = Data("""
        {
          "rate_limit": {
            "primary_window": { "used_percent": -30, "reset_at": 1760000000 },
            "secondary_window": { "used_percent": 140, "reset_at": 1760500000 }
          }
        }
        """.utf8)

        let usage = try CodexUsageFetcher.decode(data: data)

        try expect(usage.fiveHour.usedPercent == 0, "negative usage should clamp to zero")
        try expect(usage.weekly.usedPercent == 100, "usage above 100 should clamp to 100")
    }

    private static func ignoresAdditionalModelLimits() throws {
        let data = Data("""
        {
          "plan_type": "pro",
          "rate_limit": {
            "primary_window": { "used_percent": 14, "reset_at": 1783805450 },
            "secondary_window": { "used_percent": 6, "reset_at": 1784354762 }
          },
          "additional_rate_limits": [
            {
              "limit_name": "GPT-5.3-Codex-Spark",
              "rate_limit": {
                "primary_window": { "used_percent": 0, "reset_at": 1783808493 },
                "secondary_window": { "used_percent": 0, "reset_at": 1784395293 }
              }
            }
          ]
        }
        """.utf8)

        let usage = try CodexUsageFetcher.decode(data: data)

        try expect(usage.fiveHour.remainingPercent == 86, "should use the first 5h limit")
        try expect(usage.weekly.remainingPercent == 94, "should use the first weekly limit")
    }

    private static func rejectsMissingWindow() throws {
        let data = Data("""
        { "rate_limit": { "primary_window": { "used_percent": 20 } } }
        """.utf8)

        do {
            _ = try CodexUsageFetcher.decode(data: data)
            throw TestFailure("missing window unexpectedly decoded")
        } catch let error as CodexUsageError {
            try expect(error == .malformedResponse, "wrong missing-window error")
        }
    }

    private static func rejectsMissingPercentage() throws {
        let data = Data("""
        {
          "rate_limit": {
            "primary_window": { "reset_at": 1760000000 },
            "secondary_window": { "used_percent": 20 }
          }
        }
        """.utf8)

        do {
            _ = try CodexUsageFetcher.decode(data: data)
            throw TestFailure("missing percentage unexpectedly decoded")
        } catch let error as CodexUsageError {
            try expect(error == .malformedResponse, "wrong missing-percentage error")
        }
    }
}

private struct TestFailure: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}
