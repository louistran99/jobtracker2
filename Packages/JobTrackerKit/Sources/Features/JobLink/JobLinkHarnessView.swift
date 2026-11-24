#if DEBUG
    import Domain
    import SwiftUI

    /// A debug-only screen that shows `JobLinkSection` on its own, so UI tests
    /// and manual testing can reach it before it is part of a real screen.
    /// Open it by launching with `-screen job-link`.
    ///
    /// Temporary: delete it once the New Application sheet shows the link
    /// field (A4).
    public struct JobLinkHarnessView: View {
        private let store: ApplicationStore
        @State private var checker: JobLinkChecker
        @State private var text = ""

        public init(store: ApplicationStore, fetcher: any JobPostingFetcher) {
            self.store = store
            _checker = State(initialValue: JobLinkChecker(store: store, fetcher: fetcher))
        }

        public var body: some View {
            NavigationStack {
                Form {
                    // Duplicates are found among saved applications, so wait
                    // until they have loaded.
                    switch store.loadState {
                    case .idle, .loading:
                        EmptyView()
                    case .loaded:
                        JobLinkSection(text: $text, checker: checker)
                    case .failed(let error):
                        Text("Couldn't load applications: \(error.localizedDescription)")
                    }
                }
                .navigationTitle("Job Link")
                .navigationBarTitleDisplayMode(.inline)
            }
            .task { await store.load() }
        }
    }

    #Preview {
        JobLinkHarnessView(store: .preview(), fetcher: StubJobPostingFetcher())
    }
#endif
