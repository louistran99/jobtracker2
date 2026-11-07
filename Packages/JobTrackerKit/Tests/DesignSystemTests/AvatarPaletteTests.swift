import DesignSystem
import Testing

struct AvatarPaletteTests {
    @Test func initialIsTheUppercasedFirstLetter() {
        #expect(AvatarPalette.initial(for: "stripe") == "S")
        #expect(AvatarPalette.initial(for: "  airbnb") == "A")
    }

    @Test func blankNameHasPlaceholderInitial() {
        #expect(AvatarPalette.initial(for: "   ") == "?")
    }

    /// Pinned values: if the hash changed, every company would change color
    /// between app versions.
    @Test func colorIndexIsStableAcrossLaunches() {
        #expect(AvatarPalette.colorIndex(for: "Stripe") == AvatarPalette.colorIndex(for: " stripe "))
        #expect(
            ["Airbnb", "Stripe", "Ramp", "Duolingo", "Linear", "Spotify"].map(AvatarPalette.colorIndex)
                == [8, 4, 2, 5, 0, 2]
        )
    }
}
