/// Counts that summarize the job search. Pure, so it is computed and tested
/// without any UI or storage.
public struct PipelineStats: Equatable, Sendable {
    public let total: Int
    public let inProgress: Int
    public let offers: Int
    public let countsByStage: [Stage: Int]

    public init(applications: [Application]) {
        var counts = Dictionary(uniqueKeysWithValues: Stage.allCases.map { ($0, 0) })
        for application in applications {
            counts[application.stage, default: 0] += 1
        }
        total = applications.count
        inProgress = applications.count { $0.stage.isInProgress }
        offers = counts[.offer, default: 0]
        countsByStage = counts
    }
}
