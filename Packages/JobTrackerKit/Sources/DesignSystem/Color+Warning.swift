import SwiftUI
import UIKit

extension Color {
    /// For warnings that don't block the user, such as a job posting that
    /// couldn't be read. In light mode it is darker than system orange, so a
    /// small icon stands out on white; in dark mode it is system orange.
    public static let warning = Color(
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 1, green: 159 / 255, blue: 10 / 255, alpha: 1)
                : UIColor(red: 194 / 255, green: 106 / 255, blue: 0, alpha: 1)
        }
    )
}
