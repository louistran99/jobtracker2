import Foundation

/// Realistic sample data for previews and UI tests. It matches the mockups:
/// four applications with a next step coming up and two waiting to hear back.
public enum SampleApplications {
    /// Applications dated relative to `now`, so they always look current.
    public static func make(relativeTo now: Date, calendar: Calendar = .current) -> [Application] {
        let samples = [
            Sample("Airbnb", "EM, Guest Apps", .screening, appliedDaysAgo: 3) {
                NextStep(title: "Recruiter call", date: $0.moment(inDays: 1, hour: 11, minute: 30))
            },
            Sample(
                "Stripe",
                "EM, Mobile Platform",
                .onsite,
                appliedDaysAgo: 25,
                jobURL: "https://stripe.com/jobs/listing/6519024",
                notes: """
                    Rounds: system design, people management, cross-functional, Swift pairing. \
                    Prep two STAR stories on the reorg
                    """
            ) {
                NextStep(
                    title: "Onsite loop, 4 rounds",
                    date: $0.moment(inDays: 2, hour: 10, minute: 0),
                    remindsDayBefore: true
                )
            },
            Sample("Ramp", "EM, Mobile", .screening, appliedDaysAgo: 9) {
                NextStep(title: "Hiring manager", date: $0.moment(inDays: 3, hour: 14, minute: 0))
            },
            Sample("Duolingo", "EM, iOS", .applied, appliedDaysAgo: 6) {
                NextStep(title: "Recruiter screen", date: $0.moment(inDays: 4, hour: 9, minute: 0))
            },
            Sample("Linear", "Head of Mobile", .applied, appliedDaysAgo: 12),
            Sample("Spotify", "EM, iOS Client", .applied, appliedDaysAgo: 18),
        ]
        let clock = Clock(now: now, calendar: calendar)
        return samples.map { $0.makeApplication(clock: clock) }
    }
}

extension SampleApplications {
    /// Works out sample dates relative to now.
    private struct Clock {
        let now: Date
        let calendar: Calendar

        func moment(daysAgo: Int) -> Date {
            calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now
        }

        func moment(inDays days: Int, hour: Int, minute: Int) -> Date {
            let day = calendar.date(byAdding: .day, value: days, to: calendar.startOfDay(for: now)) ?? now
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
        }
    }

    private struct Sample {
        let company: String
        let role: String
        let stage: Stage
        let appliedDaysAgo: Int
        let jobURL: String?
        let notes: String
        let nextStep: ((Clock) -> NextStep)?

        init(
            _ company: String,
            _ role: String,
            _ stage: Stage,
            appliedDaysAgo: Int,
            jobURL: String? = nil,
            notes: String = "",
            nextStep: ((Clock) -> NextStep)? = nil
        ) {
            self.company = company
            self.role = role
            self.stage = stage
            self.appliedDaysAgo = appliedDaysAgo
            self.jobURL = jobURL
            self.notes = notes
            self.nextStep = nextStep
        }

        func makeApplication(clock: Clock) -> Application {
            let appliedAt = clock.moment(daysAgo: appliedDaysAgo)
            return Application(
                id: UUID(),
                company: company,
                role: role,
                stage: stage,
                appliedOn: CalendarDate(appliedAt, in: clock.calendar.timeZone),
                jobURL: jobURL.flatMap(URL.init(string:)),
                nextStep: nextStep?(clock),
                notes: notes,
                createdAt: appliedAt
            )
        }
    }
}
