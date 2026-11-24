import DesignSystem
import Domain
import SwiftUI

/// The job posting link field and what the app found out about the link: a
/// form section that checks the link as the user types or pastes it.
public struct JobLinkSection: View {
    @Binding private var text: String
    private let checker: JobLinkChecker

    public init(text: Binding<String>, checker: JobLinkChecker) {
        _text = text
        self.checker = checker
    }

    public var body: some View {
        Section {
            HStack(spacing: 12) {
                IconTile(systemImage: "link", color: .blue)
                TextField("Job link", text: $text, prompt: Text("Paste a job link"))
                    .keyboardType(.URL)
                    .textContentType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .accessibilityLabel(Text("Job link"))
                JobLinkStatusIcon(state: checker.state)
            }
            // The separator above the duplicate row starts under the icon.
            .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
            .task(id: text) { await checker.check(text) }
            .onChange(of: checker.state) {
                if let announcement = checker.announcement {
                    AccessibilityNotification.Announcement(announcement).post()
                }
            }

            if let duplicateMessage = checker.duplicateMessage {
                Text(duplicateMessage)
                    .font(.subheadline)
            }
        } footer: {
            if let footer {
                Text(footer)
            }
        }
    }

    private var footer: String? {
        switch checker.state {
        case .loading: "Fetching details. You can keep filling in the form."
        case .failed: "This posting couldn't be read. Fill in the company and role below. The link is still saved."
        case .invalid: "Enter a web address, like stripe.com/jobs/123."
        case .empty, .loaded, .duplicate: nil
        }
    }
}

/// The symbol at the end of the link field that shows the link's state.
private struct JobLinkStatusIcon: View {
    let state: JobLinkState

    @ScaledMetric(relativeTo: .body) private var size: CGFloat = 18

    var body: some View {
        switch state {
        case .empty:
            EmptyView()
        case .loading:
            ProgressView()
                .accessibilityLabel("Checking link")
        case .loaded:
            badge("checkmark.circle.fill", color: .green, label: "Posting found")
        case .failed:
            badge("exclamationmark.triangle.fill", color: .warning, label: "Couldn't read posting")
        case .invalid:
            badge("exclamationmark.triangle.fill", color: .warning, label: "Not a web address")
        case .duplicate:
            Image(systemName: "square.on.square")
                .font(.system(size: size))
                .foregroundStyle(.tint)
                .accessibilityLabel("Already added")
        }
    }

    /// A white glyph on a colored shape, in light and dark mode alike.
    private func badge(_ name: String, color: Color, label: String) -> some View {
        Image(systemName: name)
            .font(.system(size: size))
            .symbolRenderingMode(.palette)
            .foregroundStyle(.white, color)
            .accessibilityLabel(label)
    }
}

#if DEBUG
    #Preview("States") {
        @Previewable @State var found = "stripe.com/jobs/listing/6519024"
        @Previewable @State var unreadable = "linkedin.com/jobs/view/4021198765"
        @Previewable @State var duplicate = "https://stripe.com/jobs/listing/6519024"
        @Previewable @State var invalid = "stripe"
        @Previewable @State var checking = "ramp.com/careers/em-mobile"
        let store = ApplicationStore.preview()

        Form {
            JobLinkSection(text: .constant(""), checker: JobLinkChecker(store: store, fetcher: StubJobPostingFetcher()))
            JobLinkSection(
                text: $checking,
                checker: JobLinkChecker(
                    store: .preview(applications: []),
                    fetcher: StubJobPostingFetcher { _ in try await Task.sleep(for: .seconds(3600)) }
                )
            )
            JobLinkSection(
                text: $found,
                checker: JobLinkChecker(store: .preview(applications: []), fetcher: StubJobPostingFetcher())
            )
            JobLinkSection(
                text: $unreadable,
                checker: JobLinkChecker(
                    store: store,
                    fetcher: StubJobPostingFetcher { _ in throw JobPostingFetchError.httpStatus(403) }
                )
            )
            JobLinkSection(text: $duplicate, checker: JobLinkChecker(store: store, fetcher: StubJobPostingFetcher()))
            JobLinkSection(text: $invalid, checker: JobLinkChecker(store: store, fetcher: StubJobPostingFetcher()))
        }
    }
#endif
