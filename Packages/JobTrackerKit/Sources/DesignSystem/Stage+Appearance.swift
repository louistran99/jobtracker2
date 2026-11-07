import Domain
import SwiftUI

extension Stage {
    /// The user-facing name of the stage.
    public var title: String {
        switch self {
        case .applied: "Applied"
        case .screening: "Screening"
        case .onsite: "Onsite"
        case .offer: "Offer"
        case .rejected: "Rejected"
        }
    }

    /// The stage's color everywhere it appears: badges, chips and charts.
    /// System colors, so they adapt to dark mode and Increase Contrast.
    public var color: Color {
        switch self {
        case .applied: .gray
        case .screening: .indigo
        case .onsite: .orange
        case .offer: .green
        case .rejected: .red
        }
    }
}
