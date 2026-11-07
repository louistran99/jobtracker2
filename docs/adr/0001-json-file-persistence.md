# 1. Store applications in a versioned JSON file

- Status: Accepted, amended by [ADR 2](0002-application-model-v2.md)
- Date: 2026-11-06
- Ticket: KAN-70

## Context

The app tracks one person's job search: tens to a few hundred applications.
Every query the designs need (filter by stage, sort, find duplicates, count per
stage) is trivial in memory. The app follows MVVM, and view models must be
unit-testable without a database or the UI.

## Options considered

- **SwiftData.** `@Query` and `@Bindable` are its main benefits, and both put
  data access in the view, which works against MVVM. Keeping it behind a
  repository instead means maintaining `@Model` classes alongside domain
  structs, plus mapping code. It is also awkward under Swift 6 strict concurrency.
  Its real advantage is near-free iCloud sync through CloudKit.
- **UserDefaults.** Meant for small preferences that are loaded at launch, not
  user data. The system controls when writes happen, and it is process-wide
  state, which makes tests leak into each other.
- **A JSON file.** About as little code as UserDefaults. It lives in the right
  place (Application Support), writes are atomic and their failures can be
  reported, the format is readable and versioned, and each test gets its own
  temporary file.

## Decision

Domain types are plain `Codable` values. Persistence sits behind the
`ApplicationRepository` protocol:

- `JSONFileApplicationRepository` (app): one file,
  `{ "schemaVersion": 1, "applications": [...] }`, written atomically as a
  complete snapshot on every change.
- `InMemoryApplicationRepository` (previews, tests, UI tests).

A file that can't be read, or comes from a newer schema version, is never
overwritten. The error is shown and no changes are allowed until it's resolved.

## Consequences

- No built-in sync. If sync becomes a requirement, add a new
  `ApplicationRepository` implementation; view models and views don't change.
- Every save rewrites the whole file. That's fine at this scale (a few hundred
  KB at most). Revisit if a single user's data grows by orders of magnitude.
- Changing the file format requires bumping `schemaVersion` and adding a
  migration. `StorageTests.readsVersionOneFileFormat` pins the current format.
