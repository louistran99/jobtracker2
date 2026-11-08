import Domain
import Features
import Foundation

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
    appliedOn: CalendarDate = CalendarDate(Date(timeIntervalSince1970: 1_800_000_000), in: .gmt)
) -> Application {
    Application(
        id: UUID(),
        company: company,
        role: role,
        stage: stage,
        appliedOn: appliedOn,
        createdAt: Date(timeIntervalSince1970: 1_800_000_000)
    )
}

@MainActor
func makeLoadedStore(_ applications: [Application] = []) async -> (ApplicationStore, ControllableRepository) {
    let repository = ControllableRepository(applications: applications)
    let store = ApplicationStore(repository: repository)
    await store.load()
    return (store, repository)
}
