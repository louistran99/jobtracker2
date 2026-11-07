import Domain
import Foundation
import Testing

struct StageTests {
    /// Raw values are written to disk; changing one silently breaks saved data.
    @Test func rawValuesAreAStableStorageContract() {
        #expect(Stage.allCases.map(\.rawValue) == ["applied", "screening", "onsite", "offer", "rejected"])
    }

    @Test func onlyOpenStagesAreInProgress() {
        #expect(Stage.allCases.filter(\.isInProgress) == [.applied, .screening, .onsite])
    }
}
