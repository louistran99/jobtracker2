import Foundation

/// A job application the user is tracking.
public struct Application: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var company: String
    public var role: String
    public var stage: Stage
    public var appliedOn: Date
    public let createdAt: Date

    public init(
        id: UUID,
        company: String,
        role: String,
        stage: Stage,
        appliedOn: Date,
        createdAt: Date
    ) {
        self.id = id
        self.company = company
        self.role = role
        self.stage = stage
        self.appliedOn = appliedOn
        self.createdAt = createdAt
    }
}
