/// Launch arguments understood by the app. Keep in sync with
/// `App/AppDependencies.swift`.
enum LaunchArguments {
    /// Runs the app on in-memory storage and a stubbed network, with
    /// animations off.
    static let uiTesting = "-ui-testing"
    /// Starts with sample applications instead of none.
    static let seedSampleData = "-seed-sample-data"
    /// Opens the job link field on its own instead of the app's tabs.
    static let jobLinkScreen = ["-screen", "job-link"]
}
