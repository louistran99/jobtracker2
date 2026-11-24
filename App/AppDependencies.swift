import Domain
import Features
import Networking
import Storage
import UIKit

/// The composition root: the only place that decides which concrete
/// implementations the app runs with.
@MainActor
enum AppDependencies {
    static func makeScreen(configuration: LaunchConfiguration) -> AppScreen {
        if configuration.isUITesting {
            // Removes timing as a source of UI test flakiness.
            UIView.setAnimationsEnabled(false)
        }
        let store = ApplicationStore(repository: makeRepository(configuration: configuration))

        #if DEBUG
            if configuration.screen == .jobLink {
                return .jobLinkHarness(store: store, fetcher: makeJobPostingFetcher(configuration: configuration))
            }
        #endif
        return .root(RootViewModel(store: store))
    }

    private static func makeRepository(configuration: LaunchConfiguration) -> any ApplicationRepository {
        guard configuration.isUITesting else {
            return JSONFileApplicationRepository()
        }
        // UI tests never touch the disk, so every run starts from the same state.
        let applications = configuration.seedsSampleData ? SampleApplications.make(relativeTo: .now) : []
        return InMemoryApplicationRepository(applications: applications)
    }

    private static func makeJobPostingFetcher(configuration: LaunchConfiguration) -> any JobPostingFetcher {
        guard configuration.isUITesting else {
            return URLSessionJobPostingFetcher()
        }
        // UI tests never touch the network. Keep these rules in sync with
        // `UITests/JobLinkUITests.swift`.
        return StubJobPostingFetcher { url in
            let host = url.host()?.lowercased() ?? ""
            if host == "linkedin.com" || host.hasSuffix(".linkedin.com") {
                // LinkedIn turns away anyone who isn't signed in.
                throw JobPostingFetchError.httpStatus(999)
            }
            if url.path().hasPrefix("/slow") {
                // Stays in flight until the check is cancelled.
                try await Task.sleep(for: .seconds(3600))
            }
        }
    }
}

/// The screen the app opens with.
enum AppScreen {
    /// The app's tabs.
    case root(RootViewModel)
    #if DEBUG
        /// The job link field on its own (`-screen job-link`).
        case jobLinkHarness(store: ApplicationStore, fetcher: any JobPostingFetcher)
    #endif
}

/// Options passed as launch arguments, used by UI tests.
/// Keep the argument names in sync with `UITests/LaunchArguments.swift`.
struct LaunchConfiguration {
    /// A screen to open in place of the app's tabs (debug builds only).
    enum Screen: String {
        case jobLink = "job-link"
    }

    let isUITesting: Bool
    let seedsSampleData: Bool
    let screen: Screen?

    init(arguments: [String]) {
        isUITesting = arguments.contains("-ui-testing")
        seedsSampleData = arguments.contains("-seed-sample-data")
        screen = arguments.firstIndex(of: "-screen")
            .flatMap { arguments.indices.contains($0 + 1) ? arguments[$0 + 1] : nil }
            .flatMap(Screen.init(rawValue:))
    }
}
