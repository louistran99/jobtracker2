import Domain
import Features
import Storage
import UIKit

/// The composition root: the only place that decides which concrete
/// implementations the app runs with.
@MainActor
enum AppDependencies {
    static func makeRootViewModel(configuration: LaunchConfiguration) -> RootViewModel {
        if configuration.isUITesting {
            // Removes timing as a source of UI test flakiness.
            UIView.setAnimationsEnabled(false)
        }
        let store = ApplicationStore(repository: makeRepository(configuration: configuration))
        return RootViewModel(store: store)
    }

    private static func makeRepository(configuration: LaunchConfiguration) -> any ApplicationRepository {
        guard configuration.isUITesting else {
            return JSONFileApplicationRepository()
        }
        // UI tests never touch the disk, so every run starts from the same state.
        let applications = configuration.seedsSampleData ? SampleApplications.make(relativeTo: .now) : []
        return InMemoryApplicationRepository(applications: applications)
    }
}

/// Options passed as launch arguments, used by UI tests.
/// Keep the argument names in sync with `UITests/LaunchArguments.swift`.
struct LaunchConfiguration {
    let isUITesting: Bool
    let seedsSampleData: Bool

    init(arguments: [String]) {
        isUITesting = arguments.contains("-ui-testing")
        seedsSampleData = arguments.contains("-seed-sample-data")
    }
}
