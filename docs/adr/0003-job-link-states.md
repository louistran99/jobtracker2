# 3. Job link states

- Status: Accepted
- Date: 2026-11-23
- Ticket: KAN-75

## Context

When the user types or pastes a job link, the field should say whether the
link works (A6): it is being checked, the posting was found, the posting
couldn't be read, or the posting has already been added. Reading the
posting's details (company, role) comes in a later ticket, so for now
"found" only means the page could be read.

The New Application sheet doesn't show a link field yet. Adding it (A4) is a
separate ticket.

## Decision

**One state value.** `JobLinkState` has the cases `.empty`, `.invalid`,
`.loading`, `.loaded`, `.failed`, and `.duplicate(addedOn:)`. Because a single
value holds the state, the field can never show two states at once.

`.invalid` isn't in the mockup. It covers text that isn't a web address, such
as `stripe`, which can't be saved and isn't fetched. Folding it into
`.failed` would make that state's footnote ("The link is still saved") false.

**Checking order** (`JobLinkChecker`):

1. Empty text: `.empty`.
2. A link to a posting that is already saved: `.duplicate`, straight away.
   The check is local, so it is instant and works offline.
3. Otherwise wait for typing to pause (400 ms), then report `.invalid` or
   fetch the posting. A valid link shows `.loading` while it waits; invalid
   text shows `.empty`, so a half-typed link doesn't flash a warning.
4. A check that has been cancelled or overtaken by a newer one never changes
   the state.

**What "read" means** (`URLSessionJobPostingFetcher`): a GET that succeeds
(2xx after redirects) with an HTML response. The body isn't downloaded. The
session is ephemeral, so no cookies, cache, or credentials are saved to disk,
and it gives up after 10 seconds. An http link is requested over https, since
App Transport Security blocks plain http; the saved link is unchanged.

**Matching postings** (`URL.jobPostingKey`): two links point to the same
posting when they differ only in scheme, host case, a leading `www.`, the
default port, the fragment, a trailing slash, the order of query parameters,
or tracking parameters (`utm_*`, `gclid`, `fbclid`, `mc_cid`, `mc_eid`,
`gh_src`, `trk`, `trackingId`, `refId`, `ref`, `source`). The path keeps its
case.

**A new `Networking` module** holds the URLSession adapter behind the
`JobPostingFetcher` protocol in `Domain`, the same way `Storage` holds the
file adapter behind `ApplicationRepository`. UI tests and previews use
`StubJobPostingFetcher`, so they never touch the network.

**A temporary debug screen.** Until A4 puts the field in the New Application
sheet, debug builds launched with `-screen job-link` show it on its own
(`JobLinkHarnessView`). The UI tests run against it. Delete it with A4.

## Options not taken

- **HEAD instead of GET.** Many sites answer HEAD with an error or a different
  status than GET, so it would report readable postings as unreadable.
- **Blocking Add for a duplicate.** People sometimes apply to the same posting
  again. Whether to block it is left to the A4 ticket.
- **Checking duplicates by exact URL.** Links copied from LinkedIn, email, or
  a job board carry different tracking parameters, so the same posting would
  look new.

## Consequences

- Some sites turn away requests that don't look like a browser. Those
  postings show as "couldn't be read", which is a normal path: the user types
  the company and role, and the link is still saved.
- When posting details are parsed later, `fetchPosting(at:)` returns them and
  `.loaded` gains a payload.
