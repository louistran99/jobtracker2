import DesignSystem
import Domain
import SwiftUI

struct ApplicationListView: View {
    @Bindable var viewModel: ApplicationListViewModel

    var body: some View {
        NavigationStack(path: $viewModel.path) {
            content
                .navigationTitle("Applications")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Add Application", systemImage: "plus", action: viewModel.addApplicationTapped)
                            .disabled(!viewModel.canAddApplication)
                    }
                }
                .navigationDestination(for: ApplicationsRoute.self) { route in
                    switch route {
                    case .detail(let id):
                        ApplicationDetailView(viewModel: viewModel.makeDetailViewModel(applicationID: id))
                    }
                }
                .sheet(item: $viewModel.newApplication) { newApplication in
                    NewApplicationView(viewModel: newApplication)
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.content {
        case .loading:
            ProgressView()
                .groupedBackground()
        case .failed(let message):
            ContentUnavailableView(
                "Couldn't Load Applications",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
            .groupedBackground()
        case .empty:
            ContentUnavailableView {
                Label("No Applications", systemImage: "tray")
            } description: {
                Text("Applications you add appear here.")
            } actions: {
                Button("Add Application", action: viewModel.addApplicationTapped)
            }
            .groupedBackground()
        case .list(let rows):
            List {
                Section {
                    ForEach(rows) { row in
                        Button {
                            viewModel.select(row)
                        } label: {
                            ApplicationRow(row: row)
                        }
                        .tint(.primary)
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }
}

private struct ApplicationRow: View {
    let row: ApplicationListViewModel.Row

    var body: some View {
        HStack(spacing: 12) {
            CompanyAvatar(name: row.company)
            VStack(alignment: .leading, spacing: 1) {
                Text(row.company)
                    .font(.headline)
                Text(row.role)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            // By default the separator starts at the first glyph, so it shifts
            // with each name's first letter. Pin it to the text column instead.
            .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
        }
        .accessibilityElement(children: .combine)
    }
}

extension View {
    /// Fills the screen with the grouped background, so non-list states match the list.
    fileprivate func groupedBackground() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
    }
}

#Preview("List") {
    ApplicationListView(viewModel: ApplicationListViewModel(store: .preview()))
}

#Preview("Empty") {
    ApplicationListView(viewModel: ApplicationListViewModel(store: .preview(applications: [])))
}
