import Features
import Foundation
import Testing

@MainActor
struct ApplicationDetailViewModelTests {
    @Test func exposesTheApplication() async {
        let application = makeApplication()
        let (store, _) = await makeLoadedStore([application])

        let viewModel = ApplicationDetailViewModel(applicationID: application.id, store: store)

        #expect(viewModel.application == application)
    }

    @Test func applicationIsNilWhenItDoesNotExist() async {
        let (store, _) = await makeLoadedStore([makeApplication()])

        #expect(ApplicationDetailViewModel(applicationID: UUID(), store: store).application == nil)
    }
}
