/// Loads and saves the user's applications.
///
/// The app keeps every application in memory and saves complete snapshots.
/// This is simple and correct at the scale of one person's job search.
public protocol ApplicationRepository: Sendable {
    /// Returns every saved application, or an empty array when nothing has been saved yet.
    func load() async throws -> [Application]

    /// Replaces everything saved with `applications`.
    func save(_ applications: [Application]) async throws
}
