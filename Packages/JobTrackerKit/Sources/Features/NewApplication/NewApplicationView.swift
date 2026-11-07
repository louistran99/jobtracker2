import DesignSystem
import Domain
import SwiftUI

struct NewApplicationView: View {
    @Bindable var viewModel: NewApplicationViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    private enum Field {
        case company
        case role
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    FormFieldRow("Company") {
                        TextField("Company", text: $viewModel.draft.company, prompt: Text("Required"))
                            .focused($focusedField, equals: .company)
                            .textContentType(.organizationName)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .role }
                    }
                    FormFieldRow("Role") {
                        TextField("Role", text: $viewModel.draft.role, prompt: Text("Required"))
                            .focused($focusedField, equals: .role)
                            .textContentType(.jobTitle)
                            .submitLabel(.done)
                    }
                    StagePicker(selection: $viewModel.draft.stage)
                    DatePicker("Applied on", selection: $viewModel.draft.appliedOn, displayedComponents: .date)
                }
            }
            .navigationTitle("New Application")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if viewModel.cancel() { dismiss() }
                    }
                    .confirmationDialog(
                        "Discard this application?",
                        isPresented: $viewModel.isConfirmingDiscard,
                        titleVisibility: .visible
                    ) {
                        Button("Discard", role: .destructive) { dismiss() }
                        Button("Keep Editing", role: .cancel) {}
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if viewModel.add() { dismiss() }
                    }
                    .disabled(!viewModel.canAdd)
                }
            }
            .interactiveDismissDisabled(viewModel.hasChanges)
            .onAppear { focusedField = .company }
        }
    }
}

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        NewApplicationView(viewModel: NewApplicationViewModel(store: .preview()))
    }
}
