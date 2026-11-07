import Domain
import Foundation
import Testing

struct InMemoryApplicationRepositoryTests {
    @Test func loadReturnsWhatWasSaved() async {
        let date = Date(timeIntervalSince1970: 0)
        let application = Application(
            id: UUID(),
            company: "Ramp",
            role: "EM",
            stage: .applied,
            appliedOn: date,
            createdAt: date
        )
        let repository = InMemoryApplicationRepository()

        await repository.save([application])

        #expect(await repository.load() == [application])
        #expect(await repository.saveCount == 1)
    }
}
