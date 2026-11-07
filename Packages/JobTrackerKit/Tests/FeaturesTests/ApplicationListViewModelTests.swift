import Domain
import Features
import Foundation
import Testing

@MainActor
struct ApplicationListViewModelTests {
    @Test func showsLoadingUntilTheStoreLoads() {
        let viewModel = ApplicationListViewModel(store: ApplicationStore(repository: ControllableRepository()))

        #expect(viewModel.content == .loading)
        #expect(!viewModel.canAddApplication)
    }

    @Test func showsLoadFailureMessage() async {
        let store = ApplicationStore(repository: ControllableRepository(failsToLoad: true))
        await store.load()

        #expect(ApplicationListViewModel(store: store).content == .failed(message: "Something went wrong."))
    }

    @Test func showsEmptyStateWhenNothingIsSaved() async {
        let (store, _) = await makeLoadedStore()

        let viewModel = ApplicationListViewModel(store: store)

        #expect(viewModel.content == .empty)
        #expect(viewModel.canAddApplication)
    }

    @Test func listsMostRecentlyAppliedFirstThenByCompany() async {
        let day: TimeInterval = 86_400
        let older = makeApplication(company: "Spotify", appliedOn: Date(timeIntervalSince1970: 0))
        let newerB = makeApplication(company: "stripe", appliedOn: Date(timeIntervalSince1970: day))
        let newerA = makeApplication(company: "Airbnb", appliedOn: Date(timeIntervalSince1970: day))
        let (store, _) = await makeLoadedStore([older, newerB, newerA])

        guard case .list(let rows) = ApplicationListViewModel(store: store).content else {
            Issue.record("Expected a list")
            return
        }

        #expect(rows.map(\.company) == ["Airbnb", "stripe", "Spotify"])
        #expect(rows.first?.id == newerA.id)
        #expect(rows.first?.role == newerA.role)
    }

    @Test func selectingARowPushesItsDetail() async {
        let application = makeApplication()
        let (store, _) = await makeLoadedStore([application])
        let viewModel = ApplicationListViewModel(store: store)
        guard case .list(let rows) = viewModel.content else {
            Issue.record("Expected a list")
            return
        }

        viewModel.select(rows[0])

        #expect(viewModel.path == [.detail(application.id)])
    }

    @Test func addShowsNewApplicationSheet() async {
        let (store, _) = await makeLoadedStore()
        let viewModel = ApplicationListViewModel(store: store)

        viewModel.addApplicationTapped()

        #expect(viewModel.newApplication != nil)
    }

    @Test func addDoesNothingBeforeTheStoreLoads() {
        let viewModel = ApplicationListViewModel(store: ApplicationStore(repository: ControllableRepository()))

        viewModel.addApplicationTapped()

        #expect(viewModel.newApplication == nil)
    }

    @Test func addedApplicationAppearsInTheList() async {
        let (store, _) = await makeLoadedStore()
        let viewModel = ApplicationListViewModel(store: store)

        store.add(makeApplication(company: "Duolingo"))

        guard case .list(let rows) = viewModel.content else {
            Issue.record("Expected a list")
            return
        }
        #expect(rows.map(\.company) == ["Duolingo"])
    }
}
