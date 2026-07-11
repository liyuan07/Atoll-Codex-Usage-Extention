import AtollCodexUsageCore
import Foundation
import SwiftUI

@MainActor
final class UsageController: ObservableObject {
    static let shared = UsageController()

    @Published private(set) var lastUpdated: Date?
    @Published private(set) var status = "Starting…"
    @Published private(set) var displayEnabled = true
    @Published private(set) var isRefreshing = false

    private let fetcher: CodexUsageFetcher
    private let publisher: AtollActivityPublisher
    private var refreshTimer: Timer?
    private var currentUsage: CodexUsage?

    init(fetcher: CodexUsageFetcher = CodexUsageFetcher(), publisher: AtollActivityPublisher? = nil) {
        self.fetcher = fetcher
        self.publisher = publisher ?? AtollActivityPublisher()
    }

    func start() {
        guard refreshTimer == nil else { return }
        publisher.observeDismissal { [weak self] in
            self?.displayEnabled = false
            self?.status = "Hidden in Atoll"
        }
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.refresh() }
        }
        Task { await authorizeAndRefresh() }
    }

    func authorizeAndRefresh() async {
        do {
            let authorized = try await withTimeout(seconds: 5) {
                try await self.publisher.requestAuthorization()
            }
            guard authorized else {
                status = "Authorize this app in Atoll Settings → Extensions"
                return
            }
            await refresh()
        } catch {
            status = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let usage = try await fetcher.fetch()
            currentUsage = usage
            lastUpdated = Date()
            status = usage.notchText
            if displayEnabled {
                try await withTimeout(seconds: 12) {
                    try await self.publisher.publish(usage)
                }
            }
        } catch {
            status = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func restoreDisplay() {
        displayEnabled = true
        Task {
            do {
                let authorized = try await withTimeout(seconds: 5) {
                    try await self.publisher.requestAuthorization()
                }
                guard authorized else {
                    status = "Authorize this app in Atoll Settings → Extensions"
                    return
                }
                if let currentUsage {
                    try await publisher.publish(currentUsage)
                } else {
                    await refresh()
                }
            } catch {
                status = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }
    }

    func hideDisplay() {
        displayEnabled = false
        status = "Hidden in Atoll"
        Task { await publisher.dismiss() }
    }

    func stop() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        Task { await publisher.dismiss() }
    }

    func quit() async {
        refreshTimer?.invalidate()
        refreshTimer = nil
        try? await withTimeout(seconds: 3) {
            await self.publisher.dismiss()
        }
        NSApp.terminate(nil)
    }
}

private struct OperationTimeoutError: LocalizedError {
    let seconds: UInt64

    var errorDescription: String? {
        "Timed out connecting to Atoll after \(seconds)s. Restart Atoll and try Refresh Now."
    }
}

private func withTimeout<T>(
    seconds: UInt64,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    try await withCheckedThrowingContinuation { continuation in
        let state = ContinuationResumeState<T>()
        Task {
            do {
                let value = try await operation()
                state.resume(continuation, with: .success(value))
            } catch {
                state.resume(continuation, with: .failure(error))
            }
        }
        Task {
            try await Task.sleep(nanoseconds: seconds * 1_000_000_000)
            state.resume(continuation, with: .failure(OperationTimeoutError(seconds: seconds)))
        }
    }
}

private final class ContinuationResumeState<T>: @unchecked Sendable {
    private let lock = NSLock()
    private var didResume = false

    func resume(
        _ continuation: CheckedContinuation<T, Error>,
        with result: Result<T, Error>
    ) {
        lock.lock()
        defer { lock.unlock() }

        guard !didResume else { return }
        didResume = true
        continuation.resume(with: result)
    }
}
