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

    @Test func updateReplacesTheApplicationAndSaves() async {
        let original = makeApplication(company: "Stripe", stage: .screening)
        let other = makeApplication(company: "Ramp")
        let (store, repository) = await makeLoadedStore([original, other])
        var edited = original
        edited.stage = .onsite
        edited.notes = "Prep two STAR stories"

        store.update(edited)
        #expect(store.applications == [edited, other])

        await store.flush()
        #expect(await repository.savedSnapshots == [[edited, other]])
    }

    @Test func updateWithoutChangesDoesNotSave() async {
        let application = makeApplication()
        let (store, repository) = await makeLoadedStore([application])

        store.update(application)
        await store.flush()

        #expect(await repository.savedSnapshots.isEmpty)
    }

    /// An edit saved after the application was deleted must not bring it back.
    @Test func updateOfADeletedApplicationDoesNothing() async {
        let application = makeApplication()
        let (store, repository) = await makeLoadedStore([application])
        store.delete(id: application.id)

        var edited = application
        edited.stage = .offer
        store.update(edited)
        await store.flush()

        #expect(store.applications.isEmpty)
        #expect(await repository.savedSnapshots == [[]])
    }

    @Test func deleteRemovesTheApplicationAndSaves() async {
        let kept = makeApplication(company: "Ramp")
        let deleted = makeApplication(company: "Stripe")
        let (store, repository) = await makeLoadedStore([kept, deleted])

        store.delete(id: deleted.id)
        #expect(store.applications == [kept])

        await store.flush()
        #expect(await repository.savedSnapshots == [[kept]])
    }

    @Test func deleteOfAnUnknownIDDoesNothing() async {
        let (store, repository) = await makeLoadedStore([makeApplication()])

        store.delete(id: UUID())
        await store.flush()

        #expect(store.applications.count == 1)
        #expect(await repository.savedSnapshots.isEmpty)
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
