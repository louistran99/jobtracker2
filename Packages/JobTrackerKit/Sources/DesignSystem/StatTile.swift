import SwiftUI

/// A card with a large number over a short label, as on the Summary screen.
public struct StatTile: View {
    private let value: String
    private let label: String

    public init(value: String, label: String) {
        self.value = value
        self.label = label
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.largeTitle.bold())
                .monospacedDigit()
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    HStack(spacing: 10) {
        StatTile(value: "9", label: "Active")
        StatTile(value: "14", label: "Total")
        StatTile(value: "1", label: "Offer")
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
