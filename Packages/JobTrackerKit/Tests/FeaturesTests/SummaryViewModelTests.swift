import Domain
import Features
import Testing

@MainActor
struct SummaryViewModelTests {
    @Test func showsLoadingUntilTheStoreLoads() {
        #expect(SummaryViewModel(store: ApplicationStore(repository: ControllableRepository())).content == .loading)
    }

    @Test func showsLoadFailureMessage() async {
        let store = ApplicationStore(repository: ControllableRepository(failsToLoad: true))
        await store.load()

        #expect(SummaryViewModel(store: store).content == .failed(message: "Something went wrong."))
    }

    @Test func summarizesThePipeline() async {
        let stages: [Stage] = [.applied, .screening, .onsite, .offer, .rejected]
        let (store, _) = await makeLoadedStore(stages.map { makeApplication(stage: $0) })

        guard case .loaded(let tiles) = SummaryViewModel(store: store).content else {
            Issue.record("Expected loaded content")
            return
        }

        #expect(tiles.active == 3)
        #expect(tiles.total == 5)
        #expect(tiles.offers == 1)
        #expect(tiles.offersLabel == "Offer")
    }

    @Test func pluralizesOffers() async {
        let (store, _) = await makeLoadedStore([makeApplication(stage: .offer), makeApplication(stage: .offer)])

        guard case .loaded(let tiles) = SummaryViewModel(store: store).content else {
            Issue.record("Expected loaded content")
            return
        }

        #expect(tiles.offersLabel == "Offers")
    }

    @Test func updatesWhenAnApplicationIsAdded() async {
        let (store, _) = await makeLoadedStore()
        let viewModel = SummaryViewModel(store: store)

        store.add(makeApplication())

        guard case .loaded(let tiles) = viewModel.content else {
            Issue.record("Expected loaded content")
            return
        }
        #expect(tiles.total == 1)
    }
}
