import Domain
import Foundation
import Networking
import Synchronization
import Testing

struct URLSessionJobPostingFetcherTests {
    private let host = StubURLProtocol.makeHost()
    private let fetcher = URLSessionJobPostingFetcher(configuration: StubURLProtocol.makeConfiguration())

    @Test(arguments: ["text/html", "TEXT/HTML", "application/xhtml+xml"])
    func aWebPageCanBeRead(mimeType: String) async throws {
        reply(.respond(statusCode: 200, mimeType: mimeType))

        try await fetcher.fetchPosting(at: url("/jobs/1"))
    }

    @Test(arguments: [403, 404, 500, 999])
    func anErrorStatusCantBeRead(statusCode: Int) async throws {
        reply(.respond(statusCode: statusCode, mimeType: "text/html"))

        await #expect(throws: JobPostingFetchError.httpStatus(statusCode)) {
            try await fetcher.fetchPosting(at: url("/jobs/1"))
        }
    }

    @Test(arguments: ["application/pdf", "application/json", "image/png"])
    func somethingOtherThanAWebPageCantBeRead(mimeType: String) async throws {
        reply(.respond(statusCode: 200, mimeType: mimeType))

        await #expect(throws: JobPostingFetchError.notAWebPage) {
            try await fetcher.fetchPosting(at: url("/jobs/1"))
        }
    }

    @Test(arguments: [URLError.Code.timedOut, .notConnectedToInternet, .cannotFindHost])
    func aRequestWithNoResponseCantBeRead(code: URLError.Code) async throws {
        reply(.fail(URLError(code)))

        await #expect(throws: JobPostingFetchError.unreachable) {
            try await fetcher.fetchPosting(at: url("/jobs/1"))
        }
    }

    @Test func asksForAWebPage() async throws {
        let request = Mutex<URLRequest?>(nil)
        StubURLProtocol.register(host: host) { received in
            request.withLock { $0 = received }
            return .respond(statusCode: 200, mimeType: "text/html")
        }

        try await fetcher.fetchPosting(at: url("/jobs/1"))

        let sent = try #require(request.withLock { $0 })
        #expect(sent.httpMethod == "GET")
        #expect(sent.value(forHTTPHeaderField: "Accept") == "text/html,application/xhtml+xml")
    }

    @Test func requestsAnHTTPLinkOverHTTPS() async throws {
        let requestedURL = Mutex<URL?>(nil)
        StubURLProtocol.register(host: host) { request in
            requestedURL.withLock { $0 = request.url }
            return .respond(statusCode: 200, mimeType: "text/html")
        }

        try await fetcher.fetchPosting(at: url("/jobs/1?team=mobile", scheme: "http"))

        #expect(requestedURL.withLock { $0 } == (try url("/jobs/1?team=mobile")))
    }

    @Test func cancellingIsNotAFailure() async throws {
        let (started, didStart) = AsyncStream.makeStream(of: Void.self)
        StubURLProtocol.register(host: host) { _ in
            didStart.yield()
            return .hang
        }
        let link = try url("/jobs/1")
        let fetch = Task { [fetcher] in try await fetcher.fetchPosting(at: link) }

        for await _ in started { break }
        fetch.cancel()

        await #expect(throws: CancellationError.self) { try await fetch.value }
    }

    private func reply(_ reply: StubURLProtocol.Reply) {
        StubURLProtocol.register(host: host) { _ in reply }
    }

    private func url(_ pathAndQuery: String, scheme: String = "https") throws -> URL {
        try #require(URL(string: "\(scheme)://\(host)\(pathAndQuery)"))
    }
}
