import Domain
import Foundation
import Storage
import Testing

/// Each test gets its own directory, so tests can run in parallel and never
/// see each other's files.
final class JSONFileApplicationRepositoryTests {
    private let directory: URL
    private let fileURL: URL

    init() throws {
        directory = FileManager.default.temporaryDirectory
            .appending(path: "JSONFileApplicationRepositoryTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        // Nested so the test also covers creating missing parent directories.
        fileURL = directory.appending(path: "nested/applications.json")
    }

    deinit {
        try? FileManager.default.removeItem(at: directory)
    }

    @Test func loadingWhenNothingWasSavedReturnsEmpty() async throws {
        let repository = JSONFileApplicationRepository(fileURL: fileURL)

        #expect(try await repository.load().isEmpty)
    }

    @Test func savedApplicationsLoadBackUnchanged() async throws {
        let applications = [
            makeApplication(company: "Stripe", stage: .onsite),
            makeApplication(company: "Linear", stage: .applied),
        ]

        try await JSONFileApplicationRepository(fileURL: fileURL).save(applications)
        let loaded = try await JSONFileApplicationRepository(fileURL: fileURL).load()

        #expect(loaded == applications)
    }

    @Test func saveReplacesThePreviousSnapshot() async throws {
        let repository = JSONFileApplicationRepository(fileURL: fileURL)
        try await repository.save([makeApplication(company: "Old")])

        let replacement = [makeApplication(company: "New")]
        try await repository.save(replacement)

        #expect(try await repository.load() == replacement)
    }

    /// Pins the on-disk format. If this test needs to change, saved user data
    /// needs a migration.
    @Test func readsVersionOneFileFormat() async throws {
        try write(
            """
            {
              "applications" : [
                {
                  "appliedOn" : "2026-11-03T17:00:00.000Z",
                  "company" : "Stripe",
                  "createdAt" : "2026-11-03T17:05:30.250Z",
                  "id" : "6F1D2C3B-4A5E-4F60-8172-93A4B5C6D7E8",
                  "role" : "EM, Mobile Platform",
                  "stage" : "onsite"
                }
              ],
              "schemaVersion" : 1
            }
            """
        )

        let loaded = try await JSONFileApplicationRepository(fileURL: fileURL).load()

        #expect(
            loaded == [
                Application(
                    id: try #require(UUID(uuidString: "6F1D2C3B-4A5E-4F60-8172-93A4B5C6D7E8")),
                    company: "Stripe",
                    role: "EM, Mobile Platform",
                    stage: .onsite,
                    appliedOn: Date(timeIntervalSince1970: 1_793_725_200),
                    createdAt: Date(timeIntervalSince1970: 1_793_725_530.25)
                )
            ]
        )
    }

    @Test func writesTheSchemaVersion() async throws {
        try await JSONFileApplicationRepository(fileURL: fileURL).save([])

        let json = try String(contentsOf: fileURL, encoding: .utf8)

        #expect(json.contains(#""schemaVersion" : 1"#))
    }

    @Test(arguments: ["", "not json", "[]", #"{"schemaVersion": 1}"#, #"{"schemaVersion": 1, "applications": [{}]}"#])
    func unreadableFileThrowsAndIsLeftUntouched(contents: String) async throws {
        try write(contents)

        await #expect(throws: JSONFileApplicationRepository.Error.unreadable) {
            try await JSONFileApplicationRepository(fileURL: fileURL).load()
        }
        #expect(try String(contentsOf: fileURL, encoding: .utf8) == contents)
    }

    @Test func fileFromNewerVersionThrowsAndIsLeftUntouched() async throws {
        let contents = #"{"schemaVersion": 2, "applications": []}"#
        try write(contents)

        await #expect(throws: JSONFileApplicationRepository.Error.unsupportedSchemaVersion(2)) {
            try await JSONFileApplicationRepository(fileURL: fileURL).load()
        }
        #expect(try String(contentsOf: fileURL, encoding: .utf8) == contents)
    }

    private func write(_ contents: String) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data(contents.utf8).write(to: fileURL)
    }

    private func makeApplication(company: String, stage: Stage = .applied) -> Application {
        // Millisecond precision is the most the file format keeps. 0.125 is
        // exactly representable in binary, so equality is exact after a round trip.
        let date = Date(timeIntervalSince1970: 1_793_725_200.125)
        return Application(id: UUID(), company: company, role: "EM", stage: stage, appliedOn: date, createdAt: date)
    }
}
