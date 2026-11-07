import Domain
import Foundation
import Testing

struct PipelineStatsTests {
    @Test func emptyPipelineHasZeroForEveryStage() {
        let stats = PipelineStats(applications: [])

        #expect(stats.total == 0)
        #expect(stats.inProgress == 0)
        #expect(stats.offers == 0)
        #expect(stats.countsByStage == [.applied: 0, .screening: 0, .onsite: 0, .offer: 0, .rejected: 0])
    }

    @Test func countsEachStage() {
        let stages: [Stage] = [.applied, .applied, .screening, .onsite, .offer, .rejected, .rejected]

        let stats = PipelineStats(applications: stages.map(makeApplication))

        #expect(stats.total == 7)
        #expect(stats.inProgress == 4)
        #expect(stats.offers == 1)
        #expect(stats.countsByStage == [.applied: 2, .screening: 1, .onsite: 1, .offer: 1, .rejected: 2])
    }

    private func makeApplication(stage: Stage) -> Application {
        let date = Date(timeIntervalSince1970: 0)
        return Application(id: UUID(), company: "Co", role: "Role", stage: stage, appliedOn: date, createdAt: date)
    }
}
