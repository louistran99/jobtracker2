/// Launch arguments understood by the app. Keep in sync with
/// `App/AppDependencies.swift`.
enum LaunchArguments {
    /// Runs the app on in-memory storage with animations off.
    static let uiTesting = "-ui-testing"
    /// Starts with sample applications instead of none.
    static let seedSampleData = "-seed-sample-data"
}
