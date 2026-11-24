import Features
import SwiftUI

@main
struct JobTrackerApp: App {
    @State private var screen = AppDependencies.makeScreen(
        configuration: LaunchConfiguration(arguments: ProcessInfo.processInfo.arguments)
    )

    var body: some Scene {
        WindowGroup {
            switch screen {
            case .root(let viewModel):
                RootView(viewModel: viewModel)
            #if DEBUG
                case .jobLinkHarness(let store, let fetcher):
                    JobLinkHarnessView(store: store, fetcher: fetcher)
            #endif
            }
        }
    }
}
