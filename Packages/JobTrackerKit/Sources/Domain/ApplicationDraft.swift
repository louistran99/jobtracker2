import Foundation

/// The editable, not-yet-saved form of an `Application`.
///
/// A draft is a value, so cancelling an edit means discarding it: there is
/// nothing to roll back in storage.
public struct ApplicationDraft: Equatable, Sendable {
    public var company: String
    public var role: String
    public var stage: Stage
    public var appliedOn: Date

    public init(company: String = "", role: String = "", stage: Stage = .applied, appliedOn: Date) {
        self.company = company
        self.role = role
        self.stage = stage
        self.appliedOn = appliedOn
    }

    /// Company and role are the only required fields.
    public var isValid: Bool {
        !company.trimmed.isEmpty && !role.trimmed.isEmpty
    }

    /// Builds the application to save, or `nil` when the draft is not valid.
    public func makeApplication(id: UUID, createdAt: Date) -> Application? {
        guard isValid else { return nil }
        return Application(
            id: id,
            company: company.trimmed,
            role: role.trimmed,
            stage: stage,
            appliedOn: appliedOn,
            createdAt: createdAt
        )
    }
}

extension String {
    fileprivate var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
