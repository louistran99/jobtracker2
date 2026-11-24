import Foundation

/// What the app knows about the job link in the link field.
///
/// One value covers every state, so the field can never show two at once,
/// such as checking and failed.
public enum JobLinkState: Equatable, Sendable {
    /// No link, or a link still being typed.
    case empty
    /// The text isn't a web address, so it can't be saved or checked.
    case invalid
    /// The posting is being fetched.
    case loading
    /// The posting was read.
    case loaded
    /// The posting couldn't be read: a login wall, a timeout, an error, or
    /// something other than a web page. The link can still be saved.
    case failed
    /// An application already has a link to this posting. `addedOn` is when
    /// that application was added.
    case duplicate(addedOn: Date)
}
