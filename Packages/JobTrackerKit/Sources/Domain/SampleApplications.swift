import Foundation

/// Realistic sample data for previews and UI tests.
public enum SampleApplications {
    /// Applications dated relative to `now`, so they always look current.
    public static func make(relativeTo now: Date) -> [Application] {
        let entries: [(company: String, role: String, stage: Stage, daysAgo: Int)] = [
            ("Airbnb", "EM, Guest Apps", .screening, 3),
            ("Stripe", "EM, Mobile Platform", .onsite, 25),
            ("Ramp", "EM, Mobile", .screening, 9),
            ("Duolingo", "EM, iOS", .applied, 6),
            ("Linear", "Head of Mobile", .applied, 12),
            ("Spotify", "EM, iOS Client", .applied, 18),
        ]
        return entries.map { entry in
            let date = now.addingTimeInterval(-Double(entry.daysAgo) * 86_400)
            return Application(
                id: UUID(),
                company: entry.company,
                role: entry.role,
                stage: entry.stage,
                appliedOn: date,
                createdAt: date
            )
        }
    }
}
