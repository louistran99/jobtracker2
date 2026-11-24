import Domain
import Features
import Foundation
import Testing

struct TestError: Error, Equatable, LocalizedError {
    var errorDescription: String? { "Something went wrong." }
}

/// A repository whose load and save fail on demand.
actor ControllableRepository: ApplicationRepository {
    private(set) var savedSnapshots: [[Application]] = []
    private let initial: [Application]
    private let failsToLoad: Bool
    private var failsToSave: Bool

    init(applications: [Application] = [], failsToLoad: Bool = false, failsToSave: Bool = false) {
        self.initial = applications
        self.failsToLoad = failsToLoad
        self.failsToSave = failsToSave
    }

    func load() throws -> [Application] {
        if failsToLoad { throw TestError() }
        return initial
    }

    func save(_ applications: [Application]) throws {
        if failsToSave { throw TestError() }
        savedSnapshots.append(applications)
    }
}

func makeApplication(
    company: String = "Stripe",
    role: String = "EM",
    stage: Stage = .applied,
    appliedOn: CalendarDate = CalendarDate(Date(timeIntervalSince1970: 1_800_000_000), in: .gmt),
    jobURL: URL? = nil,
    createdAt: Date = Date(timeIntervalSince1970: 1_800_000_000)
) -> Application {
    Application(
        id: UUID(),
        company: company,
        role: role,
        stage: stage,
        appliedOn: appliedOn,
        jobURL: jobURL,
        createdAt: createdAt
    )
}

@MainActor
func makeLoadedStore(_ applications: [Application] = []) async -> (ApplicationStore, ControllableRepository) {
    let repository = ControllableRepository(applications: applications)
    let store = ApplicationStore(repository: repository)
    await store.load()
    return (store, repository)
}

/// A `JobPostingFetcher` that holds every fetch until the test answers it, so
/// a test can look at the state while a fetch is in flight.
actor ControllableJobPostingFetcher: JobPostingFetcher {
    private(set) var fetchCount = 0
    private var pending: [(url: URL, continuation: CheckedContinuation<Void, any Error>)] = []
    private nonisolated let requests: AsyncStream<URL>
    private let requestsContinuation: AsyncStream<URL>.Continuation

    init() {
        (requests, requestsContinuation) = AsyncStream.makeStream()
    }

    func fetchPosting(at url: URL) async throws {
        fetchCount += 1
        try await withCheckedThrowingContinuation { continuation in
            pending.append((url, continuation))
            requestsContinuation.yield(url)
        }
    }

    /// Waits for the next fetch to start and returns its URL.
    nonisolated func nextRequest() async -> URL? {
        for await url in requests {
            return url
        }
        return nil
    }

    /// Ends the fetch of `url`: it returns, or throws `error`.
    func finish(_ url: URL, throwing error: (any Error)? = nil) {
        guard let index = pending.firstIndex(where: { $0.url == url }) else {
            Issue.record("No fetch of \(url) is in flight")
            return
        }
        let continuation = pending.remove(at: index).continuation
        if let error {
            continuation.resume(throwing: error)
        } else {
            continuation.resume()
        }
    }
}

/// Stands in for `Task.sleep` in debounced code. It records each wait and
/// holds it until the test opens the gate, unless the gate starts open.
actor DebounceGate {
    private(set) var waits: [Duration] = []
    private var isOpen: Bool
    private var waiters: [CheckedContinuation<Void, Never>] = []
    private nonisolated let entered: AsyncStream<Void>
    private let enteredContinuation: AsyncStream<Void>.Continuation

    init(isOpen: Bool = true) {
        self.isOpen = isOpen
        (entered, enteredContinuation) = AsyncStream.makeStream()
    }

    /// Pass this as the `sleep` dependency.
    nonisolated var sleep: @Sendable (Duration) async throws -> Void {
        { [self] duration in await wait(duration) }
    }

    /// Waits until code under test is waiting at the gate.
    nonisolated func waitUntilEntered() async {
        for await _ in entered {
            return
        }
    }

    func open() {
        isOpen = true
        waiters.forEach { $0.resume() }
        waiters.removeAll()
    }

    private func wait(_ duration: Duration) async {
        waits.append(duration)
        enteredContinuation.yield()
        guard !isOpen else { return }
        await withCheckedContinuation { waiters.append($0) }
    }
}
