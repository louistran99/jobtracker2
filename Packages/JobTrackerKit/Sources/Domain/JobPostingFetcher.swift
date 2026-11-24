import Foundation

/// Reads a job posting from the web.
public protocol JobPostingFetcher: Sendable {
    /// Returns when the posting at `url` could be read, and throws when it
    /// couldn't: a login wall, an error page, a timeout, or something other
    /// than a web page.
    ///
    /// Throws `CancellationError` when the calling task is cancelled, so a
    /// cancelled check is never mistaken for an unreadable posting.
    func fetchPosting(at url: URL) async throws
}

/// Why a job posting couldn't be read.
public enum JobPostingFetchError: Error, Equatable, Sendable {
    /// The request didn't get a response: no connection, a timeout, or a
    /// server that couldn't be found.
    case unreachable
    /// The server answered with a status other than success, such as 403 for
    /// a login wall or 404 for a posting that was taken down.
    case httpStatus(Int)
    /// The response wasn't a web page.
    case notAWebPage
}

/// A `JobPostingFetcher` that never touches the network: it runs `fetch`
/// instead. Used by previews and UI tests.
public struct StubJobPostingFetcher: JobPostingFetcher {
    private let fetch: @Sendable (URL) async throws -> Void

    public init(_ fetch: @escaping @Sendable (URL) async throws -> Void = { _ in }) {
        self.fetch = fetch
    }

    public func fetchPosting(at url: URL) async throws {
        try await fetch(url)
    }
}
