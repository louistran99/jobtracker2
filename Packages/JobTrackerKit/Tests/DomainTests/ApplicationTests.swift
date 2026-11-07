import Domain
import Foundation
import Testing

struct ApplicationTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test(arguments: [
        (Stage.applied, false, Application.FollowUp.awaitingResponse),
        (.screening, false, .awaitingResponse),
        (.onsite, false, .awaitingResponse),
        (.offer, false, .closed),
        (.rejected, false, .closed),
        (.applied, true, .nextStep),
        (.onsite, true, .nextStep),
        (.offer, true, .nextStep),
    ])
    func followUpComesFromTheStageAndNextStep(stage: Stage, hasNextStep: Bool, expected: Application.FollowUp) {
        let nextStep = hasNextStep ? NextStep(title: "Call", date: now) : nil

        #expect(makeApplication(stage: stage, nextStep: nextStep).followUp == expected)
    }

    @Test func upcomingNextStepsAreSoonestFirstFromTheStartDate() {
        let hour: TimeInterval = 3_600
        let past = makeApplication(company: "Past", nextStep: NextStep(title: "Call", date: now - 1))
        let none = makeApplication(company: "None", nextStep: nil)
        let later = makeApplication(company: "Later", nextStep: NextStep(title: "Onsite", date: now + 2 * hour))
        let tieB = makeApplication(company: "stripe", nextStep: NextStep(title: "Call", date: now + hour))
        let tieA = makeApplication(company: "Airbnb", nextStep: NextStep(title: "Call", date: now + hour))
        let startingNow = makeApplication(company: "Now", nextStep: NextStep(title: "Call", date: now))

        let upcoming = [past, none, later, tieB, tieA, startingNow].withUpcomingNextSteps(from: now)

        #expect(upcoming.map(\.company) == ["Now", "Airbnb", "stripe", "Later"])
    }

    @Test func sampleDataMatchesTheMockups() {
        let samples = SampleApplications.make(relativeTo: now)

        #expect(samples.filter { $0.followUp == .nextStep }.map(\.company) == ["Airbnb", "Stripe", "Ramp", "Duolingo"])
        #expect(samples.filter { $0.followUp == .awaitingResponse }.map(\.company) == ["Linear", "Spotify"])
        #expect(samples.withUpcomingNextSteps(from: now).map(\.company) == ["Airbnb", "Stripe", "Ramp", "Duolingo"])
    }

    private func makeApplication(
        company: String = "Stripe",
        stage: Stage = .applied,
        nextStep: NextStep?
    ) -> Application {
        Application(
            id: UUID(),
            company: company,
            role: "EM",
            stage: stage,
            appliedOn: CalendarDate(now, in: .gmt),
            nextStep: nextStep,
            createdAt: now
        )
    }
}
