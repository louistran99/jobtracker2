import Foundation

/// A job application the user is tracking.
///
/// The property names are encoded in the saved file, so they are a storage
/// contract: never rename one without a migration.
public struct Application: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var company: String
    public var role: String
    public var stage: Stage
    public var appliedOn: CalendarDate
    /// The job posting's address, if the user has one.
    public var jobURL: URL?
    /// What happens next, or `nil` when nothing is scheduled.
    public var nextStep: NextStep?
    /// Free-form notes. Empty when there are none.
    public var notes: String
    public let createdAt: Date

    public init(
        id: UUID,
        company: String,
        role: String,
        stage: Stage,
        appliedOn: CalendarDate,
        jobURL: URL? = nil,
        nextStep: NextStep? = nil,
        notes: String = "",
        createdAt: Date
    ) {
        self.id = id
        self.company = company
        self.role = role
        self.stage = stage
        self.appliedOn = appliedOn
        self.jobURL = jobURL
        self.nextStep = nextStep
        self.notes = notes
        self.createdAt = createdAt
    }
}

extension Application {
    /// Who the application is waiting on. The Applications list groups rows by it.
    public enum FollowUp: Hashable, Sendable {
        /// Something is scheduled, such as an interview or a call.
        case nextStep
        /// Still in the pipeline with nothing scheduled: waiting to hear back
        /// from the company.
        case awaitingResponse
        /// Ended with an offer or a rejection, and nothing is scheduled.
        case closed
    }

    /// Worked out from the stage and the next step rather than stored, so it
    /// can never disagree with them.
    ///
    /// A scheduled next step comes first, whatever the stage: a call to
    /// negotiate an offer still needs the user's attention.
    public var followUp: FollowUp {
        if nextStep != nil {
            .nextStep
        } else if stage.isInProgress {
            .awaitingResponse
        } else {
            .closed
        }
    }
}

extension Sequence<Application> {
    /// Applications whose next step is at or after `date`, soonest first. Ties
    /// are ordered by company name so the order is stable.
    public func withUpcomingNextSteps(from start: Date) -> [Application] {
        let upcoming = compactMap { application -> (application: Application, date: Date)? in
            guard let date = application.nextStep?.date, date >= start else { return nil }
            return (application, date)
        }
        return
            upcoming
            .sorted { lhs, rhs in
                if lhs.date != rhs.date { return lhs.date < rhs.date }
                return lhs.application.company.localizedStandardCompare(rhs.application.company) == .orderedAscending
            }
            .map(\.application)
    }
}
