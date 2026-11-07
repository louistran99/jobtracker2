import Domain
import SwiftUI

/// A stage's colored dot followed by its name.
public struct StageBadge: View {
    private let stage: Stage

    public init(stage: Stage) {
        self.stage = stage
    }

    public var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(stage.color)
                .frame(width: 8, height: 8)
            Text(stage.title)
        }
    }
}

#Preview {
    VStack(alignment: .leading) {
        ForEach(Stage.allCases, id: \.self) { StageBadge(stage: $0) }
    }
}
