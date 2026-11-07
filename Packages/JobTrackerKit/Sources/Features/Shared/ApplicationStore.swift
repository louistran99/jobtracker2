import Domain
import Foundation
import Observation

/// The single source of truth for applications while the app runs.
///
/// Every screen reads from the same store, so a change made on one screen
/// shows up on all of them. Changes apply in memory right away and are then
/// saved in order, one complete snapshot at a time.
@MainActor
@Observable
public final class ApplicationStore {
    public enum LoadState {
        case idle
        case loading
        case loaded
        case failed(any Error)
    }

    public private(set) var applications: [Application] = []
    public private(set) var loadState: LoadState = .idle
    /// The most recent save failure, until the user acknowledges it.
    public private(set) var saveError: (any Error)?

    @ObservationIgnored private let repository: any ApplicationRepository
    @ObservationIgnored private var latestSave: Task<Void, Never>?

    public init(repository: any ApplicationRepository) {
        self.repository = repository
    }

    public var isLoaded: Bool {
        if case .loaded = loadState { true } else { false }
    }

    /// Loads saved applications. Runs once; later calls do nothing.
    public func load() async {
        guard case .idle = loadState else { return }
        loadState = .loading
        do {
            applications = try await repository.load()
            loadState = .loaded
        } catch {
            loadState = .failed(error)
        }
    }

    public func application(id: Application.ID) -> Application? {
        applications.first { $0.id == id }
    }

    public func add(_ application: Application) {
        mutate { $0.append(application) }
    }

    public func clearSaveError() {
        saveError = nil
    }

    /// Waits until every change made so far has been saved (or has failed).
    public func flush() async {
        await latestSave?.value
    }

    /// Applies a change and queues a save of the resulting snapshot. Saves run
    /// one after another, so the file always ends up with the latest snapshot.
    private func mutate(_ change: (inout [Application]) -> Void) {
        // Writing before a successful load would overwrite saved data with an
        // empty or partial list. The UI only offers changes once loaded.
        precondition(isLoaded, "ApplicationStore can only change after a successful load")
        change(&applications)

        let snapshot = applications
        let previousSave = latestSave
        latestSave = Task { [repository] in
            await previousSave?.value
            do {
                try await repository.save(snapshot)
            } catch {
                saveError = error
            }
        }
    }
}

#if DEBUG
    extension ApplicationStore {
        /// A store that is already loaded, for previews.
        public static func preview(
            applications: [Application] = SampleApplications.make(relativeTo: .now)
        )
            -> ApplicationStore
        {
            let store = ApplicationStore(repository: InMemoryApplicationRepository(applications: applications))
            store.applications = applications
            store.loadState = .loaded
            return store
        }
    }
#endif
