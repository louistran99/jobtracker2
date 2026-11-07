import Domain
import SwiftUI

/// A form row for choosing a stage. Shows the stage's colored dot, which a
/// plain menu-style `Picker` can't.
public struct StagePicker: View {
    @Binding private var selection: Stage

    public init(selection: Binding<Stage>) {
        _selection = selection
    }

    public var body: some View {
        LabeledContent("Stage") {
            Menu {
                Picker("Stage", selection: $selection) {
                    ForEach(Stage.allCases, id: \.self) { stage in
                        Text(stage.title).tag(stage)
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    StageBadge(stage: selection)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.footnote.weight(.semibold))
                        .imageScale(.small)
                }
            }
            // Forms tint menu labels with the accent color; a value reads as secondary text.
            .tint(Color(.secondaryLabel))
            .accessibilityLabel("Stage")
            .accessibilityValue(selection.title)
        }
    }
}

#Preview {
    @Previewable @State var stage = Stage.onsite
    Form {
        StagePicker(selection: $stage)
    }
}
