import Foundation

/// The next thing that happens on an application, such as "Onsite loop,
/// 4 rounds" on Nov 5 at 10:00 AM.
public struct NextStep: Hashable, Codable, Sendable {
    public var title: String
    /// When it happens. Unlike an application's applied date, this is a moment
    /// with a time of day: a call at 10:00 AM in San Francisco is at 6:00 PM in
    /// London.
    public var date: Date
    /// Whether the user wants a reminder the day before.
    public var remindsDayBefore: Bool

    public init(title: String, date: Date, remindsDayBefore: Bool = false) {
        self.title = title
        self.date = date
        self.remindsDayBefore = remindsDayBefore
    }
}
