# RESEARCH.md

# Research Notes

* **FedWiki sitemap shape**
  Confirm minimal fields needed to detect “updated”. Use `date` when present; fall back to checksum of page JSON if required.

* **HTTP**

  * ZnClient with short timeouts and friendly errors.
  * ETag/If-None-Match vs Last-Modified/If-Modified-Since trade-offs.

* **GT/Phlow refresh**

  * `fireToolUpdateWish` is available in newer GT; keep graceful fallbacks for older builds.
  * Consider `updateWhen:` in future, gated by feature detection.

* **File watching**

  * Simple mtime poll vs OS notifications. Start with explicit “Reload”.

* **Testing**

  * Use tiny canned sitemaps to cover added/removed/updated paths.
  * Golden tests for diff output (strings / sets).
