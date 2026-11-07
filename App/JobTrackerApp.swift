import Features
import SwiftUI

@main
struct JobTrackerApp: App {
    @State private var rootViewModel = AppDependencies.makeRootViewModel(
        configuration: LaunchConfiguration(arguments: ProcessInfo.processInfo.arguments)
    )

    var body: some Scene {
        WindowGroup {
            RootView(viewModel: rootViewModel)
        }
    }
}
