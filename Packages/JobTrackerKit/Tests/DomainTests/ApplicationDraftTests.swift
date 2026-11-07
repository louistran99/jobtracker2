import Domain
import Foundation
import Testing

struct ApplicationDraftTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func newDraftIsInvalid() {
        #expect(!ApplicationDraft(appliedOn: date).isValid)
    }

    @Test(arguments: [
        ("Stripe", ""),
        ("", "EM, Mobile Platform"),
        ("  ", "EM"),
        ("Stripe", "\n\t"),
    ])
    func draftMissingCompanyOrRoleIsInvalid(company: String, role: String) {
        #expect(!ApplicationDraft(company: company, role: role, appliedOn: date).isValid)
    }

    @Test func draftWithCompanyAndRoleIsValid() {
        #expect(ApplicationDraft(company: "Stripe", role: "EM", appliedOn: date).isValid)
    }

    @Test func makeApplicationTrimsAndKeepsEveryField() throws {
        let draft = ApplicationDraft(company: "  Stripe ", role: " EM\n", stage: .onsite, appliedOn: date)
        let id = UUID()
        let createdAt = date.addingTimeInterval(60)

        let application = try #require(draft.makeApplication(id: id, createdAt: createdAt))

        #expect(
            application
                == Application(
                    id: id,
                    company: "Stripe",
                    role: "EM",
                    stage: .onsite,
                    appliedOn: date,
                    createdAt: createdAt
                )
        )
    }

    @Test func makeApplicationReturnsNilForInvalidDraft() {
        #expect(ApplicationDraft(appliedOn: date).makeApplication(id: UUID(), createdAt: date) == nil)
    }
}
