import Foundation

/// A job posting link as the user typed or pasted it.
public enum JobLink: Equatable, Sendable {
    /// Nothing but whitespace.
    case empty
    /// Text that isn't an http or https address with a host name.
    case invalid
    /// A web address.
    case valid(URL)

    /// Reads the link the way people type or paste one: surrounding whitespace
    /// is ignored, and a link without a scheme, such as
    /// `stripe.com/jobs/listing/6519024`, is taken to be https.
    ///
    /// Anything other than an http or https address with a host name, such as
    /// `stripe.com`, is invalid.
    public init(parsing text: String) {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            self = .empty
            return
        }
        guard !text.contains(where: \.isWhitespace) else {
            self = .invalid
            return
        }

        let hasScheme = text.range(of: "^[A-Za-z][A-Za-z0-9+.-]*://", options: .regularExpression) != nil
        guard
            let components = URLComponents(string: hasScheme ? text : "https://" + text),
            let scheme = components.scheme?.lowercased(),
            ["http", "https"].contains(scheme),
            components.user == nil,
            components.password == nil,
            let host = components.host,
            host.split(separator: ".").count >= 2,
            let url = components.url
        else {
            self = .invalid
            return
        }
        self = .valid(url)
    }
}

// MARK: - Duplicates

extension URL {
    /// Identifies the posting a link points to, so two links to the same
    /// posting compare equal even when they were copied from different places.
    ///
    /// The scheme, the host's case, a leading `www.`, the default port, the
    /// fragment, a trailing slash, tracking parameters, and the order of the
    /// remaining query parameters are all ignored. The path keeps its case,
    /// because paths are case-sensitive.
    public var jobPostingKey: String {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return absoluteString
        }

        var host = (components.host ?? "").lowercased()
        if host.hasPrefix("www.") {
            host.removeFirst(4)
        }

        var key = host
        if let port = components.port, port != 80, port != 443 {
            key += ":\(port)"
        }

        var path = components.percentEncodedPath
        while path.hasSuffix("/") {
            path.removeLast()
        }
        key += path

        let query = (components.percentEncodedQueryItems ?? [])
            .filter { !Self.isTrackingParameter($0.name) }
            .map { item in item.value.map { "\(item.name)=\($0)" } ?? item.name }
            .sorted()
        if !query.isEmpty {
            key += "?" + query.joined(separator: "&")
        }
        return key
    }

    /// Query parameters that say where a link was shared or clicked, not which
    /// posting it is.
    private static func isTrackingParameter(_ name: String) -> Bool {
        let name = name.lowercased()
        return name.hasPrefix("utm_") || trackingParameters.contains(name)
    }

    private static let trackingParameters: Set<String> = [
        "gclid", "fbclid", "mc_cid", "mc_eid", "gh_src", "trk", "trackingid", "refid", "ref", "source",
    ]
}

extension Sequence<Application> {
    /// The application saved with a link to the same posting as `url`, or
    /// `nil` when there isn't one. When several match, the one added first.
    public func firstApplication(withJobURL url: URL) -> Application? {
        let key = url.jobPostingKey
        return
            filter { $0.jobURL?.jobPostingKey == key }
            .min { $0.createdAt < $1.createdAt }
    }
}
