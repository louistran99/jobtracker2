import Domain
import Features
import Foundation
import Testing

@MainActor
struct JobLinkCheckerTests {
    /// Jan 15, 2027, 08:00 UTC.
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let fetcher = ControllableJobPostingFetcher()
    private let gate = DebounceGate()

    // MARK: Empty and invalid

    @Test func blankTextFetchesNothing() async {
        let checker = await makeChecker()

        await checker.check("  ")

        #expect(checker.state == .empty)
        #expect(checker.announcement == nil)
        #expect(await fetcher.fetchCount == 0)
        #expect(await gate.waits.isEmpty)
    }

    @Test func invalidTextIsReportedOnceTypingPauses() async {
        let gate = DebounceGate(isOpen: false)
        let checker = await makeChecker(gate: gate)

        let check = Task { await checker.check("stripe") }
        await gate.waitUntilEntered()
        #expect(checker.state == .empty, "Text still being typed isn't called invalid")

        await gate.open()
        await check.value

        #expect(checker.state == .invalid)
        #expect(checker.announcement == "Not a web address.")
        #expect(await fetcher.fetchCount == 0)
    }

    // MARK: Fetching

    @Test func aPostingThatCanBeReadIsLoaded() async throws {
        let checker = await makeChecker()

        let check = Task { await checker.check(" stripe.com/jobs/1 ") }
        let requested = await fetcher.nextRequest()
        #expect(requested == (try url("https://stripe.com/jobs/1")))
        #expect(checker.state == .loading)
        #expect(checker.announcement == nil)

        await fetcher.finish(try url("https://stripe.com/jobs/1"))
        await check.value

        #expect(checker.state == .loaded)
        #expect(checker.announcement == "Posting found.")
        #expect(await gate.waits == [.milliseconds(400)])
    }

    @Test func aPostingThatCantBeReadFailed() async throws {
        let checker = await makeChecker()

        let check = Task { await checker.check("linkedin.com/jobs/view/1") }
        _ = await fetcher.nextRequest()
        await fetcher.finish(
            try url("https://linkedin.com/jobs/view/1"), throwing: JobPostingFetchError.httpStatus(999))
        await check.value

        #expect(checker.state == .failed)
        #expect(checker.announcement == "This posting couldn't be read.")
    }

    @Test func clearingTheLinkClearsTheState() async throws {
        let checker = await makeChecker()
        let check = Task { await checker.check("stripe.com/jobs/1") }
        _ = await fetcher.nextRequest()
        await fetcher.finish(try url("https://stripe.com/jobs/1"))
        await check.value

        await checker.check("")

        #expect(checker.state == .empty)
    }

    // MARK: Overtaken and cancelled checks

    @Test func anOlderFetchNeverOverwritesANewerLink() async throws {
        let checker = await makeChecker()
        let first = Task { await checker.check("stripe.com/jobs/1") }
        _ = await fetcher.nextRequest()
        let second = Task { await checker.check("stripe.com/jobs/2") }
        _ = await fetcher.nextRequest()

        await fetcher.finish(try url("https://stripe.com/jobs/2"))
        await second.value
        await fetcher.finish(try url("https://stripe.com/jobs/1"), throwing: JobPostingFetchError.unreachable)
        await first.value

        #expect(checker.state == .loaded)
    }

    @Test func aCancelledCheckLeavesTheStateAlone() async throws {
        let checker = await makeChecker()
        let check = Task { await checker.check("stripe.com/jobs/1") }
        _ = await fetcher.nextRequest()

        check.cancel()
        await fetcher.finish(try url("https://stripe.com/jobs/1"))
        await check.value

        #expect(checker.state == .loading)
    }

    @Test func aCancelledFetchIsNotAFailure() async throws {
        let checker = await makeChecker()
        let check = Task { await checker.check("stripe.com/jobs/1") }
        _ = await fetcher.nextRequest()

        await fetcher.finish(try url("https://stripe.com/jobs/1"), throwing: CancellationError())
        await check.value

        #expect(checker.state == .loading)
    }

    // MARK: Duplicates

    @Test func aSavedPostingIsADuplicateRightAway() async throws {
        let addedOn = now.addingTimeInterval(-10 * 86_400)
        let checker = await makeChecker(saved: [
            makeApplication(jobURL: try url("https://stripe.com/jobs/listing/6519024"), createdAt: addedOn)
        ])

        await checker.check("http://www.stripe.com/jobs/listing/6519024/?utm_source=linkedin")

        #expect(checker.state == .duplicate(addedOn: addedOn))
        #expect(checker.duplicateMessage == "You added this on Jan 5")
        #expect(checker.announcement == "Already added. You added this on Jan 5.")
        #expect(await fetcher.fetchCount == 0, "Duplicates are found locally")
        #expect(await gate.waits.isEmpty, "Duplicates show without waiting for typing to pause")
    }

    @Test func aDuplicateFromAnotherYearShowsTheYear() async throws {
        let addedOn = Date(timeIntervalSince1970: 1_791_763_200)  // Oct 12, 2026
        let checker = await makeChecker(saved: [
            makeApplication(jobURL: try url("https://stripe.com/jobs/1"), createdAt: addedOn)
        ])

        await checker.check("stripe.com/jobs/1")

        #expect(checker.duplicateMessage == "You added this on Oct 12, 2026")
    }

    @Test func onlyADuplicateHasADuplicateMessage() async {
        let checker = await makeChecker()

        await checker.check("stripe")

        #expect(checker.duplicateMessage == nil)
    }

    // MARK: Helpers

    private func makeChecker(saved: [Application] = [], gate: DebounceGate? = nil) async -> JobLinkChecker {
        let (store, _) = await makeLoadedStore(saved)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return JobLinkChecker(
            store: store,
            fetcher: fetcher,
            now: { [now] in now },
            calendar: calendar,
            locale: Locale(identifier: "en_US"),
            sleep: (gate ?? self.gate).sleep
        )
    }

    private func url(_ string: String) throws -> URL {
        try #require(URL(string: string))
    }
}
