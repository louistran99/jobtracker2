import Domain

/// Screens that can be pushed onto the Applications tab's navigation stack.
public enum ApplicationsRoute: Hashable, Sendable {
    case detail(Application.ID)
}
