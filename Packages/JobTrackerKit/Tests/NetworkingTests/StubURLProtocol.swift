import Foundation
import Synchronization

/// Answers requests without touching the network.
///
/// Each test registers a reply for a host of its own (see `makeHost()`), so
/// tests running in parallel never see each other's replies.
final class StubURLProtocol: URLProtocol {
    enum Reply: Sendable {
        case respond(statusCode: Int, mimeType: String?)
        case fail(URLError)
        /// Never answers, as if the request were still in flight.
        case hang
    }

    typealias Handler = @Sendable (URLRequest) -> Reply

    private static let handlers = Mutex<[String: Handler]>([:])

    /// A host no other test uses.
    static func makeHost() -> String {
        "\(UUID().uuidString.lowercased()).test"
    }

    static func register(host: String, handler: @escaping Handler) {
        handlers.withLock { $0[host] = handler }
    }

    /// A configuration whose sessions are answered by registered handlers.
    static func makeConfiguration() -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return configuration
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard
            let url = request.url,
            let host = url.host(),
            let handler = Self.handlers.withLock({ $0[host] })
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.cannotFindHost))
            return
        }

        switch handler(request) {
        case .respond(let statusCode, let mimeType):
            let headers = mimeType.map { ["Content-Type": "\($0); charset=utf-8"] } ?? [:]
            guard
                let response = HTTPURLResponse(
                    url: url, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: headers)
            else {
                client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
                return
            }
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data("<html></html>".utf8))
            client?.urlProtocolDidFinishLoading(self)
        case .fail(let error):
            client?.urlProtocol(self, didFailWithError: error)
        case .hang:
            break
        }
    }

    override func stopLoading() {}
}
