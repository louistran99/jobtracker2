import Domain
import SwiftUI

extension Binding where Value == CalendarDate {
    /// The day as the moment it starts, for a `DatePicker` that shows dates
    /// only. Both directions use the current time zone, as `DatePicker` does.
    var startDate: Binding<Date> {
        Binding<Date>(
            get: { wrappedValue.startDate(in: .current) },
            set: { wrappedValue = CalendarDate($0, in: .current) }
        )
    }
}
