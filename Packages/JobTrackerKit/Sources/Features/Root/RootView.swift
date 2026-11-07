import SwiftUI

/// The app's top-level screen: one tab per area.
public struct RootView: View {
    private let viewModel: RootViewModel

    /// - Parameter viewModel: Owned by the caller, which keeps it alive for the app's lifetime.
    public init(viewModel: RootViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        TabView {
            Tab("Applications", systemImage: "list.bullet.rectangle") {
                ApplicationListView(viewModel: viewModel.applications)
            }
            Tab("Summary", systemImage: "chart.bar") {
                SummaryView(viewModel: viewModel.summary)
            }
        }
        .task { await viewModel.load() }
        .alert(
            "Couldn't Save Changes",
            isPresented: Binding(
                get: { viewModel.saveErrorMessage != nil },
                set: { isPresented in
                    if !isPresented { viewModel.dismissSaveError() }
                }
            ),
            actions: {},
            message: { Text(viewModel.saveErrorMessage ?? "") }
        )
    }
}

#Preview {
    RootView(viewModel: RootViewModel(store: .preview()))
}
