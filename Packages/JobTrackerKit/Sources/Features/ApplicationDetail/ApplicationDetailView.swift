import DesignSystem
import Domain
import SwiftUI

struct ApplicationDetailView: View {
    @State private var viewModel: ApplicationDetailViewModel

    init(viewModel: ApplicationDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if let application = viewModel.application {
                details(of: application)
            } else {
                ContentUnavailableView("Application Not Found", systemImage: "questionmark.folder")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func details(of application: Application) -> some View {
        List {
            Section {
                header(of: application)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            Section("Status") {
                LabeledContent {
                    StageBadge(stage: application.stage)
                } label: {
                    Label {
                        Text("Stage")
                    } icon: {
                        IconTile(systemImage: "flag", color: .orange)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(.compact)
    }

    private func header(of application: Application) -> some View {
        HStack(spacing: 14) {
            CompanyAvatar(name: application.company, size: .large)
            VStack(alignment: .leading, spacing: 2) {
                Text(application.company)
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)
                Text(application.role)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    let store = ApplicationStore.preview()
    NavigationStack {
        ApplicationDetailView(
            viewModel: ApplicationDetailViewModel(applicationID: store.applications[1].id, store: store)
        )
    }
}
