import SwiftUI

/// A rounded tile showing a company's initial on a color derived from its name.
public struct CompanyAvatar: View {
    public enum Size {
        /// List rows.
        case regular
        /// Screen headers.
        case large

        var side: CGFloat {
            switch self {
            case .regular: 40
            case .large: 60
            }
        }

        var font: Font {
            switch self {
            case .regular: .system(size: 19, weight: .semibold)
            case .large: .system(size: 30, weight: .semibold)
            }
        }
    }

    private let name: String
    private let size: Size

    public init(name: String, size: Size = .regular) {
        self.name = name
        self.size = size
    }

    public var body: some View {
        Text(AvatarPalette.initial(for: name))
            .font(size.font)
            .foregroundStyle(.white)
            .frame(width: size.side, height: size.side)
            .background(
                AvatarPalette.color(for: name),
                in: RoundedRectangle(cornerRadius: size.side * 0.225, style: .continuous)
            )
            .accessibilityHidden(true)
    }
}

/// Picks an avatar's initial and color. Deterministic across launches, so a
/// company keeps its color.
public enum AvatarPalette {
    static let colors: [Color] = [.red, .orange, .green, .teal, .blue, .indigo, .purple, .pink, graphite]

    /// Near-black, for brands that use black. Stays distinct from the dark mode cell background.
    private static let graphite = Color(red: 0.17, green: 0.17, blue: 0.18)

    public static func initial(for name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).first.map { String($0).uppercased() } ?? "?"
    }

    public static func color(for name: String) -> Color {
        colors[colorIndex(for: name)]
    }

    /// FNV-1a over the normalized name. `String.hashValue` can't be used
    /// because it is randomly seeded on every launch.
    public static func colorIndex(for name: String) -> Int {
        let normalized = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in normalized.utf8 {
            hash ^= UInt64(byte)
            hash &*= 0x0000_0100_0000_01b3
        }
        return Int(hash % UInt64(colors.count))
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack {
            ForEach(["Airbnb", "Stripe", "Ramp", "Duolingo", "Linear", "Spotify"], id: \.self) {
                CompanyAvatar(name: $0)
            }
        }
        CompanyAvatar(name: "Stripe", size: .large)
    }
}
