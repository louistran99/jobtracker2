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
        JobLink(parsing: jobURL) != .invalid
    }

    /// Builds the application to save, or `nil` when the draft is not valid.
    /// Pass the original `id` and `createdAt` when saving an edit.
    public func makeApplication(id: UUID, createdAt: Date) -> Application? {
        guard isValid else { return nil }
        let jobURL: URL? =
            switch JobLink(parsing: jobURL) {
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

extension String {
    fileprivate var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
