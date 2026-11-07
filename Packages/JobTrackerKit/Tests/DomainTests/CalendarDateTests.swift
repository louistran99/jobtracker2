import Domain
import Foundation
import Testing

struct CalendarDateTests {
    private let losAngeles = TimeZone(identifier: "America/Los_Angeles")
    private let tokyo = TimeZone(identifier: "Asia/Tokyo")

    @Test(arguments: [
        (2026, 11, 3),
        (2024, 2, 29),
        (1, 1, 1),
        (9999, 12, 31),
    ])
    func acceptsRealDays(year: Int, month: Int, day: Int) throws {
        let date = try #require(CalendarDate(year: year, month: month, day: day))

        #expect(date.year == year)
        #expect(date.month == month)
        #expect(date.day == day)
    }

    @Test(arguments: [
        (2026, 2, 29),
        (2026, 4, 31),
        (2026, 13, 1),
        (2026, 0, 1),
        (2026, 1, 0),
        (0, 1, 1),
        (10_000, 1, 1),
    ])
    func rejectsDaysThatDontExist(year: Int, month: Int, day: Int) {
        #expect(CalendarDate(year: year, month: month, day: day) == nil)
    }

    /// The same moment is Nov 3 in San Francisco and already Nov 4 in Tokyo.
    @Test func theDayOfAMomentDependsOnTheTimeZone() throws {
        let moment = Date(timeIntervalSince1970: 1_793_725_200)  // 2026-11-03T17:00:00Z

        #expect(CalendarDate(moment, in: try #require(losAngeles)) == CalendarDate(year: 2026, month: 11, day: 3))
        #expect(CalendarDate(moment, in: try #require(tokyo)) == CalendarDate(year: 2026, month: 11, day: 4))
    }

    /// Includes days when clocks change, and a day in Santiago whose midnight
    /// doesn't exist because clocks jump from 00:00 to 01:00.
    @Test(arguments: [
        ("America/Los_Angeles", 2026, 3, 8),
        ("America/Los_Angeles", 2026, 11, 1),
        ("America/Santiago", 2026, 9, 6),
        ("Asia/Tokyo", 2026, 11, 3),
        ("GMT", 2026, 11, 3),
    ])
    func startDateFallsOnTheSameDay(timeZoneID: String, year: Int, month: Int, day: Int) throws {
        let timeZone = try #require(TimeZone(identifier: timeZoneID))
        let date = try #require(CalendarDate(year: year, month: month, day: day))

        #expect(CalendarDate(date.startDate(in: timeZone), in: timeZone) == date)
    }

    @Test func momentsOutsideTheSupportedYearsClampToTheNearestDay() {
        let farFuture = Date(timeIntervalSince1970: 1e12)
        let farPast = Date(timeIntervalSince1970: -1e11)

        #expect(CalendarDate(farFuture, in: .gmt) == CalendarDate(year: 9999, month: 12, day: 31))
        #expect(CalendarDate(farPast, in: .gmt) == CalendarDate(year: 1, month: 1, day: 1))
    }

    @Test func ordersByYearThenMonthThenDay() throws {
        let days = try [(2026, 11, 3), (2025, 12, 31), (2026, 1, 15), (2026, 11, 2)].map { year, month, day in
            try #require(CalendarDate(year: year, month: month, day: day))
        }

        #expect(days.sorted().map(\.description) == ["2025-12-31", "2026-01-15", "2026-11-02", "2026-11-03"])
    }

    @Test func encodesAsAnISODateString() throws {
        let date = try #require(CalendarDate(year: 812, month: 3, day: 9))

        let json = try String(decoding: JSONEncoder().encode([date]), as: UTF8.self)

        #expect(json == #"["0812-03-09"]"#)
        #expect(try JSONDecoder().decode([CalendarDate].self, from: Data(json.utf8)) == [date])
    }

    @Test(arguments: [
        "2026-11-3",
        "2026/11/03",
        "2026-02-30",
        "+026-11-03",
        " 2026-11-03",
        "20261103",
        "2026-11-03T00:00:00Z",
        "0000-01-01",
        "",
    ])
    func rejectsAnythingButAValidISODate(string: String) throws {
        let json = try JSONEncoder().encode([string])

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode([CalendarDate].self, from: json)
        }
    }
}
