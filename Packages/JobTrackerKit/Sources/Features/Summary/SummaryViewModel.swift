import Domain
import Observation

@MainActor
@Observable
public final class SummaryViewModel {
    public enum Content: Equatable {
        case loading
        case failed(message: String)
        case loaded(Tiles)
    }

    public struct Tiles: Equatable, Sendable {
        public let active: Int
        public let total: Int
        public let offers: Int

        /// "Offer" or "Offers", to read naturally under the count.
        public var offersLabel: String {
            offers == 1 ? "Offer" : "Offers"
        }
    }

    @ObservationIgnored private let store: ApplicationStore

    public init(store: ApplicationStore) {
        self.store = store
    }

    public var content: Content {
        switch store.loadState {
        case .idle, .loading:
            return .loading
        case .failed(let error):
            return .failed(message: error.localizedDescription)
        case .loaded:
            let stats = PipelineStats(applications: store.applications)
            return .loaded(Tiles(active: stats.inProgress, total: stats.total, offers: stats.offers))
        }
    }
}
