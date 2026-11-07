/// Where an application currently is in the hiring pipeline.
///
/// The raw values are persisted, so they are a storage contract:
/// never rename them without a migration.
public enum Stage: String, CaseIterable, Codable, Hashable, Sendable {
    case applied
    case screening
    case onsite
    case offer
    case rejected

    /// Whether the application is still moving through the pipeline.
    public var isInProgress: Bool {
        switch self {
        case .applied, .screening, .onsite: true
        case .offer, .rejected: false
        }
    }
}
