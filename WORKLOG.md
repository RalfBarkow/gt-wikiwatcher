# WORKLOG.md

# Worklog

## 2025-10-27

* Split package into `gt-wikiwatcher` repository.
* Normalized Tonel layout under `src/`.
* Implemented/cleaned GT views:
  * Status with **Fetch now**, Transcript logging, inspector refresh.
  * Diff shows rows (added/updated/removed) or explanatory text.
  * History lists snapshot summaries.
  * Raw exposes internals; verified `history` and `lastDiff`.

* Fixed inconsistencies caused by stale Phlow contents:
  * After fetch, refresh whole inspector.
  * Added manual **Reload** to Diff/History.

* Next: add Baseline; write smoke tests on tiny fixtures; implement `useHTTP` and file mode; ETag/Last-Modified optional support.
