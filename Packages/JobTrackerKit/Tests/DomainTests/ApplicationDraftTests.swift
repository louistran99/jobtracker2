import Domain
import Foundation
import Testing

struct ApplicationDraftTests {
    private let date = Date(timeIntervalSince1970: 1_800_000_000)
    private var day: CalendarDate { CalendarDate(date, in: .gmt) }

    @Test func newDraftIsInvalid() {
        #expect(!ApplicationDraft(appliedOn: day).isValid)
    }

    @Test(arguments: [
        ("Stripe", ""),
        ("", "EM, Mobile Platform"),
        ("  ", "EM"),
        ("Stripe", "\n\t"),
    ])
    func draftMissingCompanyOrRoleIsInvalid(company: String, role: String) {
        #expect(!ApplicationDraft(company: company, role: role, appliedOn: day).isValid)
    }

    @Test func draftWithCompanyAndRoleIsValid() {
        #expect(ApplicationDraft(company: "Stripe", role: "EM", appliedOn: day).isValid)
    }

    @Test func makeApplicationTrimsAndKeepsEveryField() throws {
        let nextStep = NextStep(title: " Onsite loop ", date: date + 86_400, remindsDayBefore: true)
        let draft = ApplicationDraft(
            company: "  Stripe ",
            role: " EM\n",
            stage: .onsite,
            appliedOn: day,
            jobURL: " https://stripe.com/jobs/listing/6519024 ",
            nextStep: nextStep,
            notes: "\nPrep STAR stories  "
        )
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
                    appliedOn: day,
                    jobURL: URL(string: "https://stripe.com/jobs/listing/6519024"),
                    nextStep: NextStep(title: "Onsite loop", date: date + 86_400, remindsDayBefore: true),
                    notes: "Prep STAR stories",
                    createdAt: createdAt
                )
        )
    }

    @Test func makeApplicationReturnsNilForInvalidDraft() {
        #expect(ApplicationDraft(appliedOn: day).makeApplication(id: UUID(), createdAt: date) == nil)
    }

    @Test func editingAnApplicationWithoutChangesGivesItBack() throws {
        let application = Application(
            id: UUID(),
            company: "Stripe",
            role: "EM, Mobile Platform",
            stage: .onsite,
            appliedOn: day,
            jobURL: URL(string: "https://stripe.com/jobs/listing/6519024?gh_src=abc"),
            nextStep: NextStep(title: "Onsite loop, 4 rounds", date: date, remindsDayBefore: true),
            notes: "Rounds: system design.\nPrep two STAR stories.",
            createdAt: date
        )

        let saved = ApplicationDraft(application).makeApplication(id: application.id, createdAt: application.createdAt)

        #expect(saved == application)
    }

    // MARK: Job link

    @Test func emptyLinkIsValidAndSavesNoURL() throws {
        let draft = ApplicationDraft(company: "Stripe", role: "EM", appliedOn: day, jobURL: "  ")

        #expect(draft.isJobURLValid)
        #expect(try #require(draft.makeApplication(id: UUID(), createdAt: date)).jobURL == nil)
    }

    @Test(arguments: [
        ("stripe.com/jobs/listing/6519024", "https://stripe.com/jobs/listing/6519024"),
        ("  https://stripe.com/jobs\n", "https://stripe.com/jobs"),
        ("http://example.co.uk/a?b=c#d", "http://example.co.uk/a?b=c#d"),
        ("jobs.lever.co/ramp/1f2e", "https://jobs.lever.co/ramp/1f2e"),
    ])
    func acceptsWebLinks(text: String, expected: String) throws {
        let draft = ApplicationDraft(company: "Stripe", role: "EM", appliedOn: day, jobURL: text)

        #expect(draft.isJobURLValid)
        #expect(try #require(draft.makeApplication(id: UUID(), createdAt: date)).jobURL?.absoluteString == expected)
    }

    @Test(arguments: [
        "stripe",
        "stripe com/jobs",
        ".com",
        "https://",
        "ftp://stripe.com/jobs",
        "mailto:jobs@stripe.com",
        "https://user:password@stripe.com/jobs",
        "javascript:alert(1)",
    ])
    func rejectsAnythingButAWebLink(text: String) {
        let draft = ApplicationDraft(company: "Stripe", role: "EM", appliedOn: day, jobURL: text)

        #expect(!draft.isJobURLValid)
        #expect(!draft.isValid)
    }

    // MARK: Next step

    @Test(arguments: ["", "  \n"])
    func nextStepNeedsATitle(title: String) {
        let draft = ApplicationDraft(
            company: "Stripe",
            role: "EM",
            appliedOn: day,
            nextStep: NextStep(title: title, date: date)
        )

        #expect(!draft.isValid)
    }
}
