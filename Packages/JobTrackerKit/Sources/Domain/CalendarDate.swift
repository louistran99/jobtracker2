import Foundation

/// A day on the calendar, such as November 3, 2026, with no time of day and no
/// time zone.
///
/// Use it for things that happen on a day rather than at a moment. An
/// application sent "on Nov 3" stays on Nov 3 when the user travels. A `Date`
/// can't do that: it is a moment, and the day a moment falls on depends on the
/// time zone it is seen from.
///
/// Days are always Gregorian, whatever calendar the user has chosen, so a saved
/// value means the same thing everywhere. It is encoded as an ISO 8601 date,
/// such as `"2026-11-03"`, and is a storage contract.
public struct CalendarDate: Hashable, Sendable {
    public let year: Int
    public let month: Int
    public let day: Int

    /// Returns `nil` unless the values name a real day in the years 1 to 9999.
    public init?(year: Int, month: Int, day: Int) {
        let components = DateComponents(year: year, month: month, day: day)
        guard Self.supportedYears.contains(year), components.isValidDate(in: Self.gregorian(in: .gmt)) else {
            return nil
        }
        self.year = year
        self.month = month
        self.day = day
    }

    /// The day that `date` falls on in `timeZone`.
    ///
    /// Moments before year 1 or after year 9999 give the first or last
    /// supported day, so every value can be saved and read back.
    public init(_ date: Date, in timeZone: TimeZone = .current) {
        let calendar = Self.gregorian(in: timeZone)
        let clamped = min(max(date, Self.first.startDate(in: timeZone)), Self.last.startDate(in: timeZone))
        let components = calendar.dateComponents([.year, .month, .day], from: clamped)
        guard
            let year = components.year,
            let month = components.month,
            let day = components.day,
            let value = CalendarDate(year: year, month: month, day: day)
        else {
            preconditionFailure("A clamped Gregorian date always has a supported year, month, and day")
        }
        self = value
    }

    /// The moment this day starts in `timeZone`.
    public func startDate(in timeZone: TimeZone = .current) -> Date {
        let components = DateComponents(year: year, month: month, day: day)
        guard let date = Self.gregorian(in: timeZone).date(from: components) else {
            preconditionFailure("\(self) is validated on creation, so it always converts to a date")
        }
        return date
    }
}

extension CalendarDate {
    private static let supportedYears = 1...9999
    private static let first = CalendarDate(uncheckedYear: 1, month: 1, day: 1)
    private static let last = CalendarDate(uncheckedYear: 9999, month: 12, day: 31)

    /// Only for values known to be valid.
    private init(uncheckedYear year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    private static func gregorian(in timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }
}

extension CalendarDate: Comparable {
    public static func < (lhs: CalendarDate, rhs: CalendarDate) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }
}

extension CalendarDate: CustomStringConvertible {
    /// The ISO 8601 form, such as `2026-11-03`.
    public var description: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }
}

extension CalendarDate: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        guard let value = Self(isoString: string) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected an ISO 8601 date such as 2026-11-03, got \(string)"
            )
        }
        self = value
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }

    /// Parses exactly `YYYY-MM-DD`.
    private init?(isoString string: String) {
        let parts = string.split(separator: "-", omittingEmptySubsequences: false)
        guard
            parts.map(\.count) == [4, 2, 2],
            parts.allSatisfy({ $0.allSatisfy(\.isASCIIDigit) }),
            let year = Int(parts[0]),
            let month = Int(parts[1]),
            let day = Int(parts[2])
        else {
            return nil
        }
        self.init(year: year, month: month, day: day)
    }
}

extension Character {
    fileprivate var isASCIIDigit: Bool {
        ("0"..."9").contains(self)
    }
}
