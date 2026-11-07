import Domain
import Features
import Foundation
import Testing

@MainActor
struct ApplicationStoreTests {
    @Test func startsIdleAndEmpty() {
        let store = ApplicationStore(repository: ControllableRepository())

        #expect(store.applications.isEmpty)
        #expect(!store.isLoaded)
    }

    @Test func loadPublishesSavedApplications() async {
        let saved = [makeApplication(company: "Ramp")]

        let (store, _) = await makeLoadedStore(saved)

        #expect(store.isLoaded)
        #expect(store.applications == saved)
    }

    @Test func loadFailureIsReported() async {
        let store = ApplicationStore(repository: ControllableRepository(failsToLoad: true))

        await store.load()

        guard case .failed(let error) = store.loadState else {
            Issue.record("Expected a failed load, got \(store.loadState)")
            return
        }
        #expect(error as? TestError == TestError())
        #expect(store.applications.isEmpty)
    }

    @Test func loadRunsOnlyOnce() async {
        let (store, _) = await makeLoadedStore([makeApplication()])
        store.add(makeApplication(company: "Linear"))

        await store.load()

        #expect(store.applications.count == 2)
    }

    @Test func addUpdatesMemoryImmediatelyAndSaves() async {
        let (store, repository) = await makeLoadedStore()
        let application = makeApplication()

        store.add(application)
        #expect(store.applications == [application])

        await store.flush()
        #expect(await repository.savedSnapshots == [[application]])
    }

    @Test func savesRunInOrderWithCompleteSnapshots() async {
        let (store, repository) = await makeLoadedStore()
        let first = makeApplication(company: "Airbnb")
        let second = makeApplication(company: "Stripe")

        store.add(first)
        store.add(second)
        await store.flush()

        #expect(await repository.savedSnapshots == [[first], [first, second]])
    }

    @Test func findsApplicationByID() async {
        let application = makeApplication()
        let (store, _) = await makeLoadedStore([application])

        #expect(store.application(id: application.id) == application)
        #expect(store.application(id: UUID()) == nil)
    }

    @Test func saveFailureIsReportedUntilCleared() async {
        let store = ApplicationStore(repository: ControllableRepository(failsToSave: true))
        await store.load()

        store.add(makeApplication())
        await store.flush()

        #expect(store.saveError as? TestError == TestError())
        store.clearSaveError()
        #expect(store.saveError == nil)
    }
}
