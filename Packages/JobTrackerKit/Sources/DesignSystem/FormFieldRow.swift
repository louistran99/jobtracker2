import SwiftUI

/// A form row with a fixed-width label, so values in consecutive rows line up
/// in one column. At accessibility text sizes the label sits above the value.
///
/// `content` should be a single control. It gets `title` as its accessibility
/// label, so VoiceOver announces e.g. "Company, text field" and reads the
/// title only once.
public struct FormFieldRow<Content: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var labelWidth: CGFloat = 108

    private let title: String
    private let content: Content

    public init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    public var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 4) {
                label
                labeledContent
            }
        } else {
            HStack(spacing: 0) {
                label
                    .frame(width: labelWidth, alignment: .leading)
                labeledContent
            }
        }
    }

    private var labeledContent: some View {
        content.accessibilityLabel(Text(title))
    }

    private var label: some View {
        Text(title)
            .accessibilityHidden(true)
    }
}

#Preview {
    Form {
        FormFieldRow("Company") { TextField("Company", text: .constant("Stripe")) }
        FormFieldRow("Role") { TextField("Role", text: .constant(""), prompt: Text("Required")) }
    }
}
