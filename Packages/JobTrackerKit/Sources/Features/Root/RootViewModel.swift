import Observation

/// Owns the screens' view models for the lifetime of the app and reports
/// app-wide problems, such as failed saves.
@MainActor
@Observable
public final class RootViewModel {
    public let applications: ApplicationListViewModel
    public let summary: SummaryViewModel
    @ObservationIgnored private let store: ApplicationStore

    public init(store: ApplicationStore) {
        self.store = store
        self.applications = ApplicationListViewModel(store: store)
        self.summary = SummaryViewModel(store: store)
    }

    public var saveErrorMessage: String? {
        store.saveError?.localizedDescription
    }

    public func load() async {
        await store.load()
    }

    public func dismissSaveError() {
        store.clearSaveError()
    }
}
