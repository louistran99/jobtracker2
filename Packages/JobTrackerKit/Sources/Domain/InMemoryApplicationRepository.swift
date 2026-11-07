/// An `ApplicationRepository` that keeps data in memory only.
/// Used by previews, tests, and UI tests, where nothing should touch the disk.
public actor InMemoryApplicationRepository: ApplicationRepository {
    public private(set) var applications: [Application]
    public private(set) var saveCount = 0

    public init(applications: [Application] = []) {
        self.applications = applications
    }

    public func load() -> [Application] {
        applications
    }

    public func save(_ applications: [Application]) {
        self.applications = applications
        saveCount += 1
    }
}
