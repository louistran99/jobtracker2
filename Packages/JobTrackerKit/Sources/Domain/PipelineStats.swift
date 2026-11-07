/// Counts that summarize the job search. Pure, so it is computed and tested
/// without any UI or storage.
public struct PipelineStats: Equatable, Sendable {
    public let total: Int
    public let inProgress: Int
    public let offers: Int
    /// Applications that got any answer: every stage after Applied, including
    /// a rejection.
    public let heardBack: Int
    public let countsByStage: [Stage: Int]

    public init(applications: [Application]) {
        var counts = Dictionary(uniqueKeysWithValues: Stage.allCases.map { ($0, 0) })
        for application in applications {
            counts[application.stage, default: 0] += 1
        }
        total = applications.count
        inProgress = applications.count { $0.stage.isInProgress }
        offers = counts[.offer, default: 0]
        heardBack = total - counts[.applied, default: 0]
        countsByStage = counts
    }

    /// The share of applications that heard back, from 0 to 1, or `nil` when
    /// there are no applications and a rate would be meaningless.
    public var heardBackRate: Double? {
        total == 0 ? nil : Double(heardBack) / Double(total)
    }
}
