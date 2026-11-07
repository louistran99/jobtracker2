import Domain
import Foundation

/// Saves applications as a single, versioned JSON file.
///
/// Every save writes a complete snapshot atomically, so the file on disk is
/// always either the previous or the new snapshot and never a partial write.
/// A file that can't be read is left exactly as it is: the error is reported
/// and the data stays on disk for a fixed or newer version of the app to read.
///
/// Files from older versions are converted as they load and are saved in the
/// current format on the next change. Each version's format is pinned by a
/// test in `JSONFileApplicationRepositoryTests`.
public actor JSONFileApplicationRepository: ApplicationRepository {
    public enum Error: Swift.Error, Equatable {
        /// The file exists but isn't valid JSON for any known format.
        case unreadable
        /// The file was written by a newer version of the app.
        case unsupportedSchemaVersion(Int)
    }

    /// Version history:
    /// 1. `id`, `company`, `role`, `stage`, `appliedOn` (a moment), `createdAt`.
    /// 2. `appliedOn` is a calendar day. Adds `jobURL`, `nextStep`, and `notes`.
    static let schemaVersion = 2

    private let fileURL: URL
    private let timeZone: TimeZone

    /// The file used by the app: `Application Support/applications.json`.
    public static var defaultFileURL: URL {
        URL.applicationSupportDirectory.appending(path: "applications.json", directoryHint: .notDirectory)
    }

    /// - Parameter timeZone: Used to convert version 1 files, which saved the
    ///   applied date as a moment. The day it becomes is the day the user saw
    ///   in the app.
    public init(fileURL: URL = defaultFileURL, timeZone: TimeZone = .current) {
        self.fileURL = fileURL
        self.timeZone = timeZone
    }

    public func load() throws -> [Application] {
        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            return []
        }

        let schemaVersion = try Self.decode(SchemaHeader.self, from: data).schemaVersion
        switch schemaVersion {
        case 1:
            return try Self.decode(SnapshotV1.self, from: data).applications.map { $0.migrated(in: timeZone) }
        case Self.schemaVersion:
            return try Self.decode(Snapshot.self, from: data).applications
        default:
            throw Error.unsupportedSchemaVersion(schemaVersion)
        }
    }

    public func save(_ applications: [Application]) throws {
        let snapshot = Snapshot(schemaVersion: Self.schemaVersion, applications: applications)
        let data = try Self.makeEncoder().encode(snapshot)
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
}

// MARK: - File format

extension JSONFileApplicationRepository {
    /// Decoded first, on its own, so a newer format is reported as such
    /// instead of as a generic decoding failure.
    private struct SchemaHeader: Decodable {
        let schemaVersion: Int
    }

    private struct Snapshot: Codable {
        let schemaVersion: Int
        let applications: [Application]
    }

    private struct SnapshotV1: Decodable {
        let applications: [ApplicationV1]
    }

    private struct ApplicationV1: Decodable {
        let id: UUID
        let company: String
        let role: String
        let stage: Stage
        let appliedOn: Date
        let createdAt: Date

        func migrated(in timeZone: TimeZone) -> Application {
            Application(
                id: id,
                company: company,
                role: role,
                stage: stage,
                appliedOn: CalendarDate(appliedOn, in: timeZone),
                createdAt: createdAt
            )
        }
    }

    /// Any failure to decode means the file isn't in the format its version
    /// promises.
    private static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try makeDecoder().decode(type, from: data)
        } catch {
            throw Error.unreadable
        }
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(date.formatted(dateFormat))
        }
        return encoder
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            do {
                return try dateFormat.parse(string)
            } catch {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Expected an ISO 8601 date, got \(string)"
                )
            }
        }
        return decoder
    }

    /// ISO 8601 with milliseconds: human-readable in the file, and precise
    /// enough that a save followed by a load doesn't visibly change any date.
    private static let dateFormat = Date.ISO8601FormatStyle(includingFractionalSeconds: true)
}

extension JSONFileApplicationRepository.Error: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unreadable:
            "Your saved applications couldn't be read. They haven't been changed."
        case .unsupportedSchemaVersion:
            "Your applications were saved by a newer version of Job Tracker. Update the app to see them."
        }
    }
}
