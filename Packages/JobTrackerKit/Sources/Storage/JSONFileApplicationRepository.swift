import Domain
import Foundation

/// Saves applications as a single, versioned JSON file.
///
/// Every save writes a complete snapshot atomically, so the file on disk is
/// always either the previous or the new snapshot and never a partial write.
/// A file that can't be read is left exactly as it is: the error is reported
/// and the data stays on disk for a fixed or newer version of the app to read.
public actor JSONFileApplicationRepository: ApplicationRepository {
    public enum Error: Swift.Error, Equatable {
        /// The file exists but isn't valid JSON for any known format.
        case unreadable
        /// The file was written by a newer version of the app.
        case unsupportedSchemaVersion(Int)
    }

    static let schemaVersion = 1

    private let fileURL: URL

    /// The file used by the app: `Application Support/applications.json`.
    public static var defaultFileURL: URL {
        URL.applicationSupportDirectory.appending(path: "applications.json", directoryHint: .notDirectory)
    }

    public init(fileURL: URL = defaultFileURL) {
        self.fileURL = fileURL
    }

    public func load() throws -> [Application] {
        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            return []
        }

        let decoder = Self.makeDecoder()
        let header: SchemaHeader
        do {
            header = try decoder.decode(SchemaHeader.self, from: data)
        } catch {
            throw Error.unreadable
        }
        guard header.schemaVersion == Self.schemaVersion else {
            throw Error.unsupportedSchemaVersion(header.schemaVersion)
        }
        do {
            return try decoder.decode(Snapshot.self, from: data).applications
        } catch {
            throw Error.unreadable
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
