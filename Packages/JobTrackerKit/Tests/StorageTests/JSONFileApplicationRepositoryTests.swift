import Domain
import Foundation
import Storage
import Testing

/// Each test gets its own directory, so tests can run in parallel and never
/// see each other's files.
final class JSONFileApplicationRepositoryTests {
    private let directory: URL
    private let fileURL: URL
    private let losAngeles: TimeZone

    init() throws {
        directory = FileManager.default.temporaryDirectory
            .appending(path: "JSONFileApplicationRepositoryTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        // Nested so the test also covers creating missing parent directories.
        fileURL = directory.appending(path: "nested/applications.json")
        losAngeles = try #require(TimeZone(identifier: "America/Los_Angeles"))
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
            try makeFullApplication(),
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

    // MARK: File format

    /// Pins the current on-disk format, both ways. If this test needs to
    /// change, saved user data needs a new schema version and a migration.
    @Test func writesVersionTwoFileFormat() async throws {
        try await JSONFileApplicationRepository(fileURL: fileURL).save([try makeFullApplication()])

        #expect(try String(contentsOf: fileURL, encoding: .utf8) == Self.versionTwoFile)
    }

    @Test func readsVersionTwoFileFormat() async throws {
        try write(Self.versionTwoFile)

        let loaded = try await JSONFileApplicationRepository(fileURL: fileURL).load()

        #expect(loaded == [try makeFullApplication()])
    }

    /// Version 1 files must keep loading for as long as anyone might have one.
    @Test func readsVersionOneFileFormat() async throws {
        try write(Self.versionOneFile)

        let loaded = try await JSONFileApplicationRepository(fileURL: fileURL, timeZone: losAngeles).load()

        #expect(
            loaded == [
                Application(
                    id: try #require(UUID(uuidString: "6F1D2C3B-4A5E-4F60-8172-93A4B5C6D7E8")),
                    company: "Stripe",
                    role: "EM, Mobile Platform",
                    stage: .onsite,
                    appliedOn: try #require(CalendarDate(year: 2026, month: 11, day: 3)),
                    jobURL: nil,
                    nextStep: nil,
                    notes: "",
                    createdAt: Date(timeIntervalSince1970: 1_793_725_530.25)
                )
            ]
        )
    }

    /// Version 1 saved 2026-11-03T17:00Z, which a user in Tokyo saw as Nov 4.
    @Test func versionOneAppliedDateBecomesTheDayTheUserSaw() async throws {
        try write(Self.versionOneFile)
        let tokyo = try #require(TimeZone(identifier: "Asia/Tokyo"))

        let loaded = try await JSONFileApplicationRepository(fileURL: fileURL, timeZone: tokyo).load()

        #expect(loaded.map(\.appliedOn) == [try #require(CalendarDate(year: 2026, month: 11, day: 4))])
    }

    @Test func versionOneFileIsSavedAsVersionTwo() async throws {
        try write(Self.versionOneFile)
        let repository = JSONFileApplicationRepository(fileURL: fileURL, timeZone: losAngeles)

        try await repository.save(try await repository.load())

        #expect(try String(contentsOf: fileURL, encoding: .utf8).contains(#""schemaVersion" : 2"#))
        #expect(try await repository.load().map(\.company) == ["Stripe"])
    }

    // MARK: Files that can't be loaded

    @Test(arguments: [
        "",
        "not json",
        "[]",
        #"{"schemaVersion": 1}"#,
        #"{"schemaVersion": 1, "applications": [{}]}"#,
        #"{"schemaVersion": 2}"#,
        #"{"schemaVersion": 2, "applications": [{}]}"#,
        // A version 2 file with a version 1 applied date.
        JSONFileApplicationRepositoryTests.versionTwoFile.replacingOccurrences(
            of: #""2026-11-03""#, with: #""2026-11-03T17:00:00.000Z""#),
        // A day that doesn't exist.
        JSONFileApplicationRepositoryTests.versionTwoFile.replacingOccurrences(
            of: #""2026-11-03""#, with: #""2026-02-30""#),
    ])
    func unreadableFileThrowsAndIsLeftUntouched(contents: String) async throws {
        try write(contents)

        await #expect(throws: JSONFileApplicationRepository.Error.unreadable) {
            try await JSONFileApplicationRepository(fileURL: fileURL).load()
        }
        #expect(try String(contentsOf: fileURL, encoding: .utf8) == contents)
    }

    @Test func fileFromNewerVersionThrowsAndIsLeftUntouched() async throws {
        let contents = #"{"schemaVersion": 3, "applications": []}"#
        try write(contents)

        await #expect(throws: JSONFileApplicationRepository.Error.unsupportedSchemaVersion(3)) {
            try await JSONFileApplicationRepository(fileURL: fileURL).load()
        }
        #expect(try String(contentsOf: fileURL, encoding: .utf8) == contents)
    }

    // MARK: Helpers

    private static let versionOneFile = """
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

    /// The file `makeFullApplication()` saves to.
    private static let versionTwoFile = """
        {
          "applications" : [
            {
              "appliedOn" : "2026-11-03",
              "company" : "Stripe",
              "createdAt" : "2026-11-03T17:05:30.250Z",
              "id" : "6F1D2C3B-4A5E-4F60-8172-93A4B5C6D7E8",
              "jobURL" : "https://stripe.com/jobs/listing/6519024",
              "nextStep" : {
                "date" : "2026-11-05T18:00:00.000Z",
                "remindsDayBefore" : true,
                "title" : "Onsite loop, 4 rounds"
              },
              "notes" : "Prep two STAR stories",
              "role" : "EM, Mobile Platform",
              "stage" : "onsite"
            }
          ],
          "schemaVersion" : 2
        }
        """

    /// An application with every field set.
    private func makeFullApplication() throws -> Application {
        Application(
            id: try #require(UUID(uuidString: "6F1D2C3B-4A5E-4F60-8172-93A4B5C6D7E8")),
            company: "Stripe",
            role: "EM, Mobile Platform",
            stage: .onsite,
            appliedOn: try #require(CalendarDate(year: 2026, month: 11, day: 3)),
            jobURL: URL(string: "https://stripe.com/jobs/listing/6519024"),
            nextStep: NextStep(
                title: "Onsite loop, 4 rounds",
                date: Date(timeIntervalSince1970: 1_793_901_600),
                remindsDayBefore: true
            ),
            notes: "Prep two STAR stories",
            createdAt: Date(timeIntervalSince1970: 1_793_725_530.25)
        )
    }

    private func makeApplication(company: String, stage: Stage = .applied) -> Application {
        // Millisecond precision is the most the file format keeps. 0.125 is
        // exactly representable in binary, so equality is exact after a round trip.
        let date = Date(timeIntervalSince1970: 1_793_725_200.125)
        return Application(
            id: UUID(),
            company: company,
            role: "EM",
            stage: stage,
            appliedOn: CalendarDate(date, in: .gmt),
            createdAt: date
        )
    }

    private func write(_ contents: String) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data(contents.utf8).write(to: fileURL)
    }
}
