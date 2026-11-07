import Domain
import Features
import Foundation
import Testing

@MainActor
struct NewApplicationViewModelTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func startsWithSensibleDefaults() async {
        let (store, _) = await makeLoadedStore()

        let viewModel = NewApplicationViewModel(store: store, now: { now })

        #expect(viewModel.draft == ApplicationDraft(stage: .applied, appliedOn: now))
        #expect(!viewModel.canAdd)
        #expect(!viewModel.hasChanges)
    }

    @Test func canAddOnceCompanyAndRoleAreFilled() async {
        let (store, _) = await makeLoadedStore()
        let viewModel = NewApplicationViewModel(store: store, now: { now })

        viewModel.draft.company = "Stripe"
        #expect(!viewModel.canAdd)

        viewModel.draft.role = "EM"
        #expect(viewModel.canAdd)
        #expect(viewModel.hasChanges)
    }

    @Test func addSavesTheApplication() async {
        let (store, repository) = await makeLoadedStore()
        let id = UUID()
        let viewModel = NewApplicationViewModel(store: store, now: { now }, makeID: { id })
        viewModel.draft.company = " Stripe "
        viewModel.draft.role = "EM"
        viewModel.draft.stage = .screening

        #expect(viewModel.add())
        await store.flush()

        let expected = Application(
            id: id,
            company: "Stripe",
            role: "EM",
            stage: .screening,
            appliedOn: now,
            createdAt: now
        )
        #expect(store.applications == [expected])
        #expect(await repository.savedSnapshots == [[expected]])
    }

    @Test func addRefusesAnInvalidDraft() async {
        let (store, _) = await makeLoadedStore()
        let viewModel = NewApplicationViewModel(store: store, now: { now })

        #expect(!viewModel.add())
        #expect(store.applications.isEmpty)
    }

    @Test func cancelWithoutChangesClosesRightAway() async {
        let (store, _) = await makeLoadedStore()
        let viewModel = NewApplicationViewModel(store: store, now: { now })

        #expect(viewModel.cancel())
        #expect(!viewModel.isConfirmingDiscard)
    }

    @Test func cancelWithChangesAsksToDiscard() async {
        let (store, _) = await makeLoadedStore()
        let viewModel = NewApplicationViewModel(store: store, now: { now })
        viewModel.draft.company = "Stripe"

        #expect(!viewModel.cancel())
        #expect(viewModel.isConfirmingDiscard)
        #expect(store.applications.isEmpty)
    }
}
