# IMPLEMENTATION_PLAN.md

# Implementation Plan

## Phase 0 — Repo hygiene

* [x] Split into `RalfBarkow/gt-wikiwatcher`.
* [ ] Add `BaselineOfGTWikiWatcher` (Metacello).
* [ ] CI: load baseline in headless Pharo/GT.

## Phase 1 — Core snapshots & diff (done/ongoing)

* [x] Fetch + parse sitemap JSON into `GTWikiSitemapSnapshot`.
* [x] Keep `history` and compute `GTWikiSitemapDiff`.
* [x] GT Status/Diff/History/Raw views.
* [x] Transcript logging and inspector refresh after fetch.
* [ ] Unit smoke tests for diff on tiny fixtures.

## Phase 2 — Offline / file-based mode

* [ ] Add `useHTTP` flag; guard network with `self useHTTP ifTrue: [...]`.
* [ ] Load from `FileReference` path when `useHTTP = false`.
* [ ] `checkAndReloadIfNeeded` via file mtime.
* [ ] Spec fixtures under `resources/fixtures/`.

## Phase 3 — HTTP hardening

* [ ] Timeouts and error messaging.
* [ ] Optional ETag / If-None-Match and Last-Modified.
* [ ] Host registry (friendly name, URL preset).

## Phase 4 — UX

* [ ] Open page in browser on row click (optional).
* [ ] Export diff as CSV/JSON.
* [ ] Persist history between sessions (opt-in).
