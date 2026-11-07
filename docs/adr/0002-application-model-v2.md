# 2. Application model and file format version 2

- Status: Accepted
- Date: 2026-11-06
- Ticket: KAN-71
- Amends: [ADR 1](0001-json-file-persistence.md)

## Context

The mockups (A1 to A6) need more than the first model held: the job posting's
link, a next step with a date, time, and reminder, notes, and a way to show
which applications are waiting to hear back. The first model also saved the
applied date as a moment in time, so an application sent "on Nov 3" in San
Francisco showed as Nov 4 in Tokyo.

## Decision

`Application` gains three fields, and its applied date changes type:

| Field | Type | Notes |
| --- | --- | --- |
| `appliedOn` | `CalendarDate` | A Gregorian day with no time zone, saved as `"2026-11-03"`. Was a `Date`. |
| `jobURL` | `URL?` | Typed links are read leniently: `stripe.com/jobs/1` becomes `https://stripe.com/jobs/1`. Only http and https are accepted. |
| `nextStep` | `NextStep?` | Title, date (a moment, since it has a time), and `remindsDayBefore`. Set and cleared as one value, so a date never exists without a title. |
| `notes` | `String` | Empty when there are none. An empty note and a missing note mean the same thing. |

**Derived, not stored.** These come from the fields above, so they can never
disagree with them:

- `Application.followUp`: `.nextStep` when one is scheduled (whatever the
  stage, since a call about an offer still needs attention), otherwise
  `.awaitingResponse` while the stage is in progress, otherwise `.closed`. The
  Applications list groups rows by it.
- `PipelineStats.heardBack`: every stage after Applied, rejections included.
- `withUpcomingNextSteps(from:)`: the Summary's Coming up list.

**File format version 2.** `schemaVersion` goes from 1 to 2. Version 1 files are
converted as they load. Each saved moment becomes the day it fell on in the
device's time zone, which is the day the user saw. The file is written as
version 2 on the next change.

Bumping the version is required even for added fields. An older build ignores
keys it doesn't know, so without the bump it would read a version 2 file, drop
the new fields, and save over them. With the bump, an older build refuses the
file and leaves it untouched.

## Options not taken

- **A stored "waiting to hear back" flag.** It could disagree with the stage and
  next step, and nothing needs it to be set by hand.
- **Next step duration or format** (the "30 min" in the Summary mockup). Not in
  the acceptance criteria; the title carries it ("Onsite loop, 4 rounds").
- **Saving the posting's location, workplace type, and date** shown under the
  link in A2 and A5. They come from fetching the posting, a later ticket, and
  can be added as optional fields then.
- **`updatedAt`.** No screen shows it.

## Consequences

- `JSONFileApplicationRepositoryTests` pins version 2 byte for byte in both
  directions, and keeps a version 1 fixture that must always load.
- Any change to the encoded property names of `Application`, `NextStep`, or
  `CalendarDate` needs a new schema version and a migration.
