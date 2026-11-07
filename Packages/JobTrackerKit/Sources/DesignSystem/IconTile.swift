import SwiftUI

/// A small colored tile with a white symbol, used to label rows (as in Settings).
public struct IconTile: View {
    private let systemImage: String
    private let color: Color

    public init(systemImage: String, color: Color) {
        self.systemImage = systemImage
        self.color = color
    }

    public var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 29, height: 29)
            .background(color, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .accessibilityHidden(true)
    }
}

#Preview {
    HStack {
        IconTile(systemImage: "flag", color: .orange)
        IconTile(systemImage: "calendar", color: .red)
        IconTile(systemImage: "link", color: .blue)
    }
}
