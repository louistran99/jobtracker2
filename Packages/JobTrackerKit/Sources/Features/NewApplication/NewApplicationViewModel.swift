import Domain
import Foundation
import Observation

/// Backs the New Application sheet. The sheet edits a draft value; nothing is
/// saved until Add, so Cancel has nothing to undo.
@MainActor
@Observable
public final class NewApplicationViewModel: Identifiable {
    public var draft: ApplicationDraft
    /// Whether the "Discard this application?" confirmation is showing.
    public var isConfirmingDiscard = false

    @ObservationIgnored private let initialDraft: ApplicationDraft
    @ObservationIgnored private let store: ApplicationStore
    @ObservationIgnored private let now: @MainActor () -> Date
    @ObservationIgnored private let makeID: @MainActor () -> UUID

    public init(
        store: ApplicationStore,
        now: @escaping @MainActor () -> Date = { .now },
        makeID: @escaping @MainActor () -> UUID = { UUID() }
    ) {
        self.store = store
        self.now = now
        self.makeID = makeID
        let draft = ApplicationDraft(appliedOn: CalendarDate(now()))
        self.draft = draft
        self.initialDraft = draft
    }

    public var canAdd: Bool {
        draft.isValid
    }

    /// Whether closing the sheet would lose something the user typed.
    public var hasChanges: Bool {
        draft != initialDraft
    }

    /// Saves the application. Returns whether the sheet should close.
    public func add() -> Bool {
        guard let application = draft.makeApplication(id: makeID(), createdAt: now()) else { return false }
        store.add(application)
        return true
    }

    /// Returns whether the sheet can close right away. If there are changes,
    /// asks the user to confirm instead.
    public func cancel() -> Bool {
        guard hasChanges else { return true }
        isConfirmingDiscard = true
        return false
    }
}
