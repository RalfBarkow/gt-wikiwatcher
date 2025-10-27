# GT-WikiWatcher

A tiny Glamorous Toolkit/Pharo tool that watches a Federated Wiki sitemap (`/system/sitemap.json`), keeps a history of snapshots, and shows a computed diff (added / updated / removed slugs).

## Features (current)

* Fetch sitemap on demand (`Fetch now` in the Status view).
* History of snapshots (in-image).
* Diff view with `added / updated / removed`.
* “Raw” inspector for internals.
* Transcript logging during fetch.

## Requirements

* Glamorous Toolkit (GT) **or** Pharo with GT/Brick/Phlow loaded.
* ZnNetworking for HTTP (usually present in GT).
* No background processes; everything happens when you click.

## Installation

### Option A — Iceberg (works now)

1. In GT/Pharo: **Iceberg → Clone repository**
   `https://github.com/RalfBarkow/gt-wikiwatcher`
2. Open the repo in Iceberg → **Packages… → Add package from repository**
   Select `GT-WikiWatcher`.
3. Load. (The Tonel files live under `src/`.)

### Option B — Metacello (once a Baseline is present)

```smalltalk
Metacello new
  baseline: 'GTWikiWatcher';
  repository: 'github://RalfBarkow/gt-wikiwatcher:main/src';
  load.
```

## Quick start

```smalltalk
watcher := GTWikiSitemapWatcher new
  url: 'http://wiki.ralfbarkow.ch/system/sitemap.json';
  yourself.

"Open an inspector and use the Status/Diff/History/Raw tabs"
watcher inspect.
```

* Click **Fetch now** in the **Status** tab.
  You’ll see progress in the Transcript.
* Open **Diff** to see changes between the last two snapshots.

## Tips

* If you don’t see new data after fetching, click **Reload** on Diff/History (or click **Fetch now** again; the tool also asks Phlow to refresh the inspector).
* For debugging, open **Raw** and expand `history` and `lastDiff`.

## Roadmap

* Optional file-based/offline mode (guard HTTP via `self useHTTP`).
* ETag/Last-Modified support.
* File mtime watcher for local sitemaps.
* Baseline + CI.
