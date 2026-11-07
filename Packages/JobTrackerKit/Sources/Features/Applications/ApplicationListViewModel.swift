import Domain
import Foundation
import Observation

@MainActor
@Observable
public final class ApplicationListViewModel {
    public enum Content: Equatable {
        case loading
        case failed(message: String)
        case empty
        case list([Row])
    }

    public struct Row: Identifiable, Equatable, Sendable {
        public let id: Application.ID
        public let company: String
        public let role: String
    }

    /// The tab's navigation stack.
    public var path: [ApplicationsRoute] = []
    /// The New Application sheet's view model while the sheet is shown.
    public var newApplication: NewApplicationViewModel?

    @ObservationIgnored private let store: ApplicationStore
    @ObservationIgnored private let now: @MainActor () -> Date

    public init(store: ApplicationStore, now: @escaping @MainActor () -> Date = { .now }) {
        self.store = store
        self.now = now
    }

    public var content: Content {
        switch store.loadState {
        case .idle, .loading:
            .loading
        case .failed(let error):
            .failed(message: error.localizedDescription)
        case .loaded:
            store.applications.isEmpty ? .empty : .list(Self.rows(from: store.applications))
        }
    }

    public var canAddApplication: Bool {
        store.isLoaded
    }

    public func select(_ row: Row) {
        path.append(.detail(row.id))
    }

    public func addApplicationTapped() {
        guard canAddApplication else { return }
        newApplication = NewApplicationViewModel(store: store, now: now)
    }

    public func makeDetailViewModel(applicationID: Application.ID) -> ApplicationDetailViewModel {
        ApplicationDetailViewModel(applicationID: applicationID, store: store)
    }

    /// Most recently applied first; ties broken by company name so the order is stable.
    static func rows(from applications: [Application]) -> [Row] {
        applications
            .sorted { lhs, rhs in
                if lhs.appliedOn != rhs.appliedOn { return lhs.appliedOn > rhs.appliedOn }
                return lhs.company.localizedStandardCompare(rhs.company) == .orderedAscending
            }
            .map { Row(id: $0.id, company: $0.company, role: $0.role) }
    }
}
