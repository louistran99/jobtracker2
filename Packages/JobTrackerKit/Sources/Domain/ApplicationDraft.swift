import Foundation

/// The editable, not-yet-saved form of an `Application`.
///
/// A draft is a value, so cancelling an edit means discarding it: there is
/// nothing to roll back in storage.
public struct ApplicationDraft: Equatable, Sendable {
    public var company: String
    public var role: String
    public var stage: Stage
    public var appliedOn: CalendarDate
    /// The job posting's link exactly as typed or pasted. Empty means no link.
    public var jobURL: String
    /// `nil` when the application has no next step.
    public var nextStep: NextStep?
    public var notes: String

    public init(
        company: String = "",
        role: String = "",
        stage: Stage = .applied,
        appliedOn: CalendarDate,
        jobURL: String = "",
        nextStep: NextStep? = nil,
        notes: String = ""
    ) {
        self.company = company
        self.role = role
        self.stage = stage
        self.appliedOn = appliedOn
        self.jobURL = jobURL
        self.nextStep = nextStep
        self.notes = notes
    }

    /// A draft for editing `application`. Saving it unchanged gives back the
    /// same application.
    public init(_ application: Application) {
        self.init(
            company: application.company,
            role: application.role,
            stage: application.stage,
            appliedOn: application.appliedOn,
            jobURL: application.jobURL?.absoluteString ?? "",
            nextStep: application.nextStep,
            notes: application.notes
        )
    }

    /// Company and role are required. A link, when there is one, must be a web
    /// address, and a next step needs a title.
    public var isValid: Bool {
        !company.trimmed.isEmpty
            && !role.trimmed.isEmpty
            && isJobURLValid
            && nextStep.map { !$0.title.trimmed.isEmpty } ?? true
    }

    /// Whether the link is empty or a web address, so the form can point out a
    /// bad link next to the field.
    public var isJobURLValid: Bool {
        if case .invalid = parsedJobURL { false } else { true }
    }

    /// Builds the application to save, or `nil` when the draft is not valid.
    /// Pass the original `id` and `createdAt` when saving an edit.
    public func makeApplication(id: UUID, createdAt: Date) -> Application? {
        guard isValid else { return nil }
        let jobURL: URL? =
            switch parsedJobURL {
            case .valid(let url): url
            case .empty, .invalid: nil
            }
        return Application(
            id: id,
            company: company.trimmed,
            role: role.trimmed,
            stage: stage,
            appliedOn: appliedOn,
            jobURL: jobURL,
            nextStep: nextStep.map { step in
                var step = step
                step.title = step.title.trimmed
                return step
            },
            notes: notes.trimmed,
            createdAt: createdAt
        )
    }
}

// MARK: - Job link

extension ApplicationDraft {
    private enum ParsedJobURL {
        case empty
        case valid(URL)
        case invalid
    }

    /// Reads the link the way people type or paste one: surrounding whitespace
    /// is ignored, and a link without a scheme, such as
    /// `stripe.com/jobs/listing/6519024`, is taken to be https.
    ///
    /// Anything other than an http or https address with a host name, such as
    /// `stripe.com`, is invalid.
    private var parsedJobURL: ParsedJobURL {
        let text = jobURL.trimmed
        guard !text.isEmpty else { return .empty }
        guard !text.contains(where: \.isWhitespace) else { return .invalid }

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
            return .invalid
        }
        return .valid(url)
    }
}

extension String {
    fileprivate var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
