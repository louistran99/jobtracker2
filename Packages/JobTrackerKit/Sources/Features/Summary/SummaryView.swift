import DesignSystem
import SwiftUI

struct SummaryView: View {
    let viewModel: SummaryViewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        NavigationStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(Color(.systemGroupedBackground))
                .navigationTitle("Summary")
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.content {
        case .loading:
            ProgressView()
                .frame(maxHeight: .infinity)
        case .failed(let message):
            ContentUnavailableView(
                "Couldn't Load Summary",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
        case .loaded(let tiles):
            ScrollView {
                tileLayout {
                    StatTile(value: "\(tiles.active)", label: "Active")
                    StatTile(value: "\(tiles.total)", label: "Total")
                    StatTile(value: "\(tiles.offers)", label: tiles.offersLabel)
                }
                // Tiles in a row share the tallest tile's height.
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
    }

    /// Three across, or stacked when accessibility text sizes leave too little width.
    private var tileLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 10))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 10))
    }
}

#Preview {
    SummaryView(viewModel: SummaryViewModel(store: .preview()))
}
