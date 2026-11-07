import Domain
import Observation

@MainActor
@Observable
public final class ApplicationDetailViewModel {
    public let applicationID: Application.ID
    @ObservationIgnored private let store: ApplicationStore

    public init(applicationID: Application.ID, store: ApplicationStore) {
        self.applicationID = applicationID
        self.store = store
    }

    /// The application, or `nil` if it no longer exists.
    public var application: Application? {
        store.application(id: applicationID)
    }
}
