import Domain
import Foundation
import Testing

struct JobLinkTests {
    // MARK: Parsing

    @Test(arguments: ["", "   ", "\n\t"])
    func blankTextIsEmpty(text: String) {
        #expect(JobLink(parsing: text) == .empty)
    }

    @Test(arguments: [
        ("stripe.com/jobs/listing/6519024", "https://stripe.com/jobs/listing/6519024"),
        ("  https://stripe.com/jobs\n", "https://stripe.com/jobs"),
        ("HTTP://Stripe.com/jobs", "HTTP://Stripe.com/jobs"),
        ("jobs.lever.co/ramp/1f2e", "https://jobs.lever.co/ramp/1f2e"),
    ])
    func webAddressesAreValid(text: String, expected: String) throws {
        #expect(JobLink(parsing: text) == .valid(try url(expected)))
    }

    @Test(arguments: ["stripe", "stripe com/jobs", "ftp://stripe.com/jobs", "https://user@stripe.com/jobs"])
    func anythingElseIsInvalid(text: String) {
        #expect(JobLink(parsing: text) == .invalid)
    }

    // MARK: Posting key

    @Test(arguments: [
        // Scheme, host case, www, and the default port don't matter.
        ("https://stripe.com/jobs/1", "http://stripe.com/jobs/1"),
        ("https://stripe.com/jobs/1", "https://STRIPE.com/jobs/1"),
        ("https://stripe.com/jobs/1", "https://www.stripe.com/jobs/1"),
        ("https://stripe.com/jobs/1", "https://stripe.com:443/jobs/1"),
        ("http://stripe.com/jobs/1", "http://stripe.com:80/jobs/1"),
        // Nor do the fragment or a trailing slash.
        ("https://stripe.com/jobs/1", "https://stripe.com/jobs/1#apply"),
        ("https://stripe.com/jobs/1", "https://stripe.com/jobs/1/"),
        ("https://stripe.com", "https://stripe.com/"),
        // Nor the order of the query parameters that identify the posting.
        ("https://boards.example.com/view?job=1&team=2", "https://boards.example.com/view?team=2&job=1"),
    ])
    func linksToTheSamePostingHaveTheSameKey(lhs: String, rhs: String) throws {
        #expect(try url(lhs).jobPostingKey == url(rhs).jobPostingKey)
    }

    @Test(arguments: [
        "utm_source=linkedin", "UTM_Campaign=fall", "gclid=1", "fbclid=1", "mc_cid=1", "mc_eid=1", "gh_src=abc",
        "trk=public_jobs", "trackingId=abc", "refId=abc", "ref=hn", "source=newsletter",
    ])
    func trackingParametersAreIgnored(parameter: String) throws {
        let plain = try url("https://stripe.com/jobs/1?job=1")
        let tracked = URL(string: "https://stripe.com/jobs/1?job=1&\(parameter)")!

        #expect(tracked.jobPostingKey == plain.jobPostingKey)
    }

    @Test(arguments: [
        ("https://stripe.com/jobs/1", "https://stripe.com/jobs/2"),
        ("https://stripe.com/jobs/abc", "https://stripe.com/jobs/ABC"),
        ("https://stripe.com/jobs/1", "https://jobs.stripe.com/jobs/1"),
        ("https://stripe.com:8443/jobs/1", "https://stripe.com/jobs/1"),
        ("https://boards.example.com/view?job=1", "https://boards.example.com/view?job=2"),
    ])
    func linksToDifferentPostingsHaveDifferentKeys(lhs: String, rhs: String) throws {
        #expect(try url(lhs).jobPostingKey != url(rhs).jobPostingKey)
    }

    // MARK: Finding a saved posting

    @Test func findsTheApplicationWithALinkToTheSamePosting() throws {
        let stripe = makeApplication("Stripe", jobURL: "https://stripe.com/jobs/listing/6519024")
        let ramp = makeApplication("Ramp", jobURL: "https://ramp.com/careers/1")
        let noLink = makeApplication("Linear", jobURL: nil)
        let link = try url("http://www.stripe.com/jobs/listing/6519024/?utm_source=linkedin")

        #expect([noLink, ramp, stripe].firstApplication(withJobURL: link) == stripe)
    }

    @Test func findsNothingWhenNoApplicationHasThePosting() throws {
        let applications = [makeApplication("Stripe", jobURL: "https://stripe.com/jobs/1")]

        #expect(applications.firstApplication(withJobURL: try url("https://stripe.com/jobs/2")) == nil)
    }

    @Test func prefersTheApplicationAddedFirst() throws {
        let later = makeApplication("Stripe again", jobURL: "https://stripe.com/jobs/1", createdAt: 2_000)
        let first = makeApplication("Stripe", jobURL: "https://stripe.com/jobs/1", createdAt: 1_000)

        #expect([later, first].firstApplication(withJobURL: try url("https://stripe.com/jobs/1")) == first)
    }

    private func url(_ string: String) throws -> URL {
        try #require(URL(string: string))
    }

    private func makeApplication(_ company: String, jobURL: String?, createdAt: TimeInterval = 0) -> Application {
        Application(
            id: UUID(),
            company: company,
            role: "EM",
            stage: .applied,
            appliedOn: CalendarDate(Date(timeIntervalSince1970: createdAt), in: .gmt),
            jobURL: jobURL.flatMap(URL.init(string:)),
            createdAt: Date(timeIntervalSince1970: createdAt)
        )
    }
}
