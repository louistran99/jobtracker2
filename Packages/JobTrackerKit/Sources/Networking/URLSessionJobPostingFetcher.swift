import Domain
import Foundation

/// Reads job postings over the network.
///
/// A posting counts as read when the server answers with success (after
/// following redirects) and the response is a web page. The page itself isn't
/// downloaded: the request is cancelled as soon as the response arrives.
public struct URLSessionJobPostingFetcher: JobPostingFetcher {
    /// How long to wait for the server before giving up.
    public static let timeout: TimeInterval = 10

    private static let webPageTypes: Set<String> = ["text/html", "application/xhtml+xml"]

    private let session: URLSession

    /// - Parameter configuration: Ephemeral by default, so nothing is saved
    ///   to disk: no cookies, cache, or credentials outlive the session.
    public init(configuration: URLSessionConfiguration = .ephemeral) {
        configuration.timeoutIntervalForRequest = Self.timeout
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        session = URLSession(configuration: configuration)
    }

    public func fetchPosting(at url: URL) async throws {
        var request = URLRequest(url: Self.secured(url))
        request.setValue("text/html,application/xhtml+xml", forHTTPHeaderField: "Accept")

        let response: URLResponse
        do {
            let (body, receivedResponse) = try await session.bytes(for: request)
            body.task.cancel()
            response = receivedResponse
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch is URLError {
            throw JobPostingFetchError.unreachable
        }
        try Task.checkCancellation()

        guard let response = response as? HTTPURLResponse else {
            throw JobPostingFetchError.unreachable
        }
        guard (200..<300).contains(response.statusCode) else {
            throw JobPostingFetchError.httpStatus(response.statusCode)
        }
        guard let mimeType = response.mimeType?.lowercased(), Self.webPageTypes.contains(mimeType) else {
            throw JobPostingFetchError.notAWebPage
        }
    }

    /// The https version of an http link. App Transport Security blocks plain
    /// http, and nearly every job site serves https. Only the request changes;
    /// the saved link stays as the user entered it.
    private static func secured(_ url: URL) -> URL {
        guard
            url.scheme?.lowercased() == "http",
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else {
            return url
        }
        components.scheme = "https"
        if components.port == 80 {
            components.port = nil
        }
        return components.url ?? url
    }
}
