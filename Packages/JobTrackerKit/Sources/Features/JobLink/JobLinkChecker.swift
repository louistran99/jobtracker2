import Domain
import Foundation
import Observation

/// Checks the job link as the user types or pastes it, and holds the result.
///
/// The link is checked against saved applications first. That check is local,
/// so a duplicate shows right away, even offline. Otherwise the posting is
/// fetched once the user pauses typing.
@MainActor
@Observable
public final class JobLinkChecker {
    public private(set) var state: JobLinkState = .empty

    @ObservationIgnored private let store: ApplicationStore
    @ObservationIgnored private let fetcher: any JobPostingFetcher
    @ObservationIgnored private let now: @MainActor () -> Date
    @ObservationIgnored private let calendar: Calendar
    @ObservationIgnored private let locale: Locale
    @ObservationIgnored private let debounce: Duration
    @ObservationIgnored private let sleep: @Sendable (Duration) async throws -> Void
    /// Counts checks, so a check that has been overtaken by a newer one never
    /// changes the state.
    @ObservationIgnored private var latestCheck = 0

    /// - Parameters:
    ///   - debounce: How long typing has to pause before a link is fetched or
    ///     reported as invalid.
    ///   - sleep: Waits out the debounce. Tests replace it so they never wait.
    public init(
        store: ApplicationStore,
        fetcher: any JobPostingFetcher,
        now: @escaping @MainActor () -> Date = { .now },
        calendar: Calendar = .current,
        locale: Locale = .current,
        debounce: Duration = .milliseconds(400),
        sleep: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) }
    ) {
        self.store = store
        self.fetcher = fetcher
        self.now = now
        self.calendar = calendar
        self.locale = locale
        self.debounce = debounce
        self.sleep = sleep
    }

    /// Checks `text` and updates `state`. Call it each time the text changes,
    /// from `.task(id: text)` so SwiftUI cancels the previous check.
    public func check(_ text: String) async {
        latestCheck += 1
        let check = latestCheck

        let link = JobLink(parsing: text)
        switch link {
        case .empty:
            state = .empty
            return
        case .valid(let url):
            if let existing = store.applications.firstApplication(withJobURL: url) {
                state = .duplicate(addedOn: existing.createdAt)
                return
            }
            state = .loading
        case .invalid:
            // The user may still be typing, so wait before calling it invalid.
            state = .empty
        }

        do {
            try await sleep(debounce)
        } catch {
            return
        }
        guard isCurrent(check) else { return }

        guard case .valid(let url) = link else {
            state = .invalid
            return
        }
        let result: JobLinkState
        do {
            try await fetcher.fetchPosting(at: url)
            result = .loaded
        } catch is CancellationError {
            return
        } catch {
            result = .failed
        }
        guard isCurrent(check) else { return }
        state = result
    }

    /// "You added this on Oct 12" when the link is a duplicate. The year is
    /// included when it isn't this year.
    public var duplicateMessage: String? {
        guard case .duplicate(let addedOn) = state else { return nil }
        var style = Date.FormatStyle(date: .omitted, time: .omitted, locale: locale, calendar: calendar)
            .month(.abbreviated)
            .day()
        if !calendar.isDate(addedOn, equalTo: now(), toGranularity: .year) {
            style = style.year()
        }
        style.timeZone = calendar.timeZone
        return "You added this on \(addedOn.formatted(style))"
    }

    /// What VoiceOver says when the check settles, or `nil` while there is
    /// nothing to report.
    public var announcement: String? {
        switch state {
        case .empty, .loading: nil
        case .invalid: "Not a web address."
        case .loaded: "Posting found."
        case .failed: "This posting couldn't be read."
        case .duplicate: duplicateMessage.map { "Already added. \($0)." }
        }
    }

    private func isCurrent(_ check: Int) -> Bool {
        check == latestCheck && !Task.isCancelled
    }
}
