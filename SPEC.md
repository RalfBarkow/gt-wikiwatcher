# SPEC.md

# Specification — GT-WikiWatcher

## Terms

* **Sitemap**: JSON at `/system/sitemap.json` (FedWiki).
* **Snapshot**: The parsed sitemap at a moment in time.
* **Diff**: `(added : Set, updated : Set, removed : Set)` between the last two snapshots.

## Model

* `GTWikiSitemapWatcher`
  * `url : String | nil`
  * `history : OrderedCollection<GTWikiSitemapSnapshot>`
  * `lastDiff : GTWikiSitemapDiff | nil`
  * (optional) `useHTTP : Boolean = true` (for offline/file mode)

* `GTWikiSitemapSnapshot`
  * `pages : Dictionary slug → { date?, title?, links?, ... }`
  * `takenAt : DateAndTime`

* `GTWikiSitemapDiff`
  * `added, updated, removed : Set<String>`
  * `isEmpty`, `fingerprint`

## Operations

* `fetchNow`

  * If `useHTTP`, GET `url` with timeout; else use file input.
  * Parse JSON → `GTWikiSitemapSnapshot`.
  * Append to `history`.
  * If `history size >= 2`, compute `lastDiff`.
  * Log to Transcript.
  * Politely request Phlow to refresh views.

* `computeDiff(previous, current)`

  * `added = currentSlugs − previousSlugs`
  * `removed = previousSlugs − currentSlugs`
  * `updated = { s | s ∈ ∩ and relevant metadata changed }`
    (initially compare `date` if present, else fallback to structural equality)

* `checkAndReloadIfNeeded`

  * For file paths: compare `mtime`; reload when changed.

## Views

* **Status**: shows `url`, snapshot count, **Fetch now** action.
* **Diff**: list with columns `Change / Slug / Date` or explanatory text when no data.
* **History**: list of snapshot summaries.
* **Raw**: variable tree for debugging.

## Invariants

* `history` is append-only; last two entries define `lastDiff`.
* A `Diff` is computed only when `history size >= 2`.
* “Initial snapshot” message only appears when `history size == 1`.

## Acceptance (MVP)

* Clicking **Fetch now** with a valid URL increases snapshot count by 1.
* With 2+ snapshots, Diff lists at least one row whenever the sitemap changed.
* History lists each snapshot with timestamp.
* Transcript shows start and completion (or error).
