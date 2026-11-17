# AGENTS.md — Radar de sensores

Instructions for AI coding agents (Antigravity, Claude, Cursor) working in this repository.
The owner is José Noel; reply to him in Latin American Spanish. Code comments and docs stay in English.

## What this is

A personal native macOS app (Apple Silicon) to discover sensors for ESP32 projects: a curated,
filterable catalog, a personal shortlist ("Mi radar") and a manual **Actualizar** button that scans
RSS feeds for newly released sensors.

## Architecture

| File | Role |
|---|---|
| `main.swift` | AppKit shell: one `NSWindow` with a `WKWebView`. Loads data files, injects them, fetches/parses RSS (`FeedParser`), writes JSON, opens links in the default browser. |
| `index.html` | The whole UI in one file (HTML + CSS + JS). **Edit this file directly**; there is no build step for it. |
| `catalogo.json` | Bundled default catalog. Copied to the data folder on first launch. |
| `LEEME.md` | Data-folder readme and the **catalog schema** (source of truth for the format). |
| `validar.py` | Validates `catalogo.json`. Run it after any catalog change. |
| `icon1024.png` | App icon source (converted to `.icns` by `build.sh`). |
| `build.sh` | Compiles and packages `~/Applications/Radar de sensores.app`, then ad-hoc signs it. |

### Data folder (not in git)

`~/Applications/RadarSensores-datos/` holds the live data:
`catalogo.json` (curated catalog), `novedades.json` (RSS findings), `radar.json` (shortlist),
`meta.json` (last scan date, dismissed items), plus copies of `LEEME.md` and `validar.py`.
On launch the app uses whichever catalog is newer by (`actualizado`, `version`): the bundled one or the data-folder one.

### JS ⇄ Swift bridge

JS → Swift: `window.webkit.messageHandlers.radar.postMessage({cmd, ...})`

| `cmd` | Payload | Effect |
|---|---|---|
| `actualizar` | `fuentes: [{n,u,tema}]` | Re-reads the catalog, fetches all feeds, replies via `radarRecibir` |
| `guardar` | `nombre: "radar"\|"novedades"\|"meta"`, `datos` | Writes `<nombre>.json` to the data folder (other names are ignored) |
| `abrir` | `url` | Opens an http(s) URL in the default browser |
| `copiar` | `texto` | Copies text to the clipboard |
| `carpeta` | — | Reveals the data folder in Finder |

Swift → JS:
- At document start: `window.__RADAR__ = {catalogo, radar, novedades, meta, carpeta}`
- After `actualizar`: `window.radarRecibir({catalogo, fuentes: [{n, ok, error, items: [{t, l, d, s}]}]})`
- Menu ⌘R calls `window.radarActualizar()`
- Menu ⌘T calls `window.radarTema()` (cycles `Auto` → `Oscuro` → `Claro` and persists in `meta.json`)
- Menu ⌘F focuses `#q` search input; Menu ⌘D opens `~/Applications/RadarSensores-datos/` in Finder

### Views and the lab (v2, `index.html`)

`<body data-view>` switches four views through the top `#vnav`: **Explorar** (original catalog), **Panel** (dashboard: KPIs, sector cards, family/bus bars, I²C address map, price × difficulty heatmap, recipes), **Comparar** (up to N sensors side by side, persisted in `localStorage` key `radar-sensores-cmp`) and **Banco de proyecto** (pin allocator, block diagram, audit, copyable snippets for the shortlist).
The sensor dialog (`#ficha`) is a *laboratory* with six tabs: **Anatomía** (clickable parts on a board SVG, archetype templates `ANAT` + per-sensor overrides `ANAT_ID`), **Conexión al ESP32** (wiring engine, clickable wires), **Industrias**, **Cómo funciona** (principle / Feynman), **Modelo 3D y CAD**, **Ficha y proyectos**.
Wiring engine: `wiringFor(s, ctx, opts)` picks the primary bus (`primBus`), classifies each pin (`classifyPin` + per-sensor `PIN_OV`), and allocates ESP32 GPIOs from pools (`POOLS`: ADC1, digital, chip-select) while shared buses use fixed pins (I²C 21/22, SPI 18/19/23, UART2 16/17). Optional pins (INT, RST…) are not allocated unless "mostrar opcionales" is on. The map is indicative (classic ESP32 DevKit numbering); keep that disclaimer in the UI.
Click handling for the new views uses its own `data-*` names (`data-view, data-tab, data-part, data-wire, data-cmp, data-bench-*, data-lab*`) so it never collides with the original delegated handler (`data-open`, `data-radar`, `data-sector`, …). Keep it that way.

Relevance filtering, cross-language (ES ↔ EN) feed matching, bidirectional combination indexing (`_combos`), project recipes (`RECIPES`), 3D isometric models and CAD/scale diagrams (`PHYS`, `isoSVG`, `cadBlueprintSVG`, `scaleCompareSVG`), Fusion 360 enclosure hints (`enclosureHint`), ESP32 electrical/bus auditing (`conflicts`, `nodeAudit`), and `ESPHome YAML` / `ESP32 pinout` generation (`esphomeYAML`, `pinoutText`) happen in JS in `index.html`.

If you add a bridge command, implement **both** sides and add it to this table.

## Build and run

```bash
bash build.sh                          # builds and signs ~/Applications/Radar de sensores.app
open ~/Applications/"Radar de sensores.app"
python3 validar.py catalogo.json       # must print OK
```

- Keep `-target arm64-apple-macos13.0` in `build.sh`. Without it swiftc targets the SDK version (macOS 28) and the app refuses to launch on macOS 27 (LaunchServices error -10825).
- Quit the running app before rebuilding.
- `index.html` can be previewed in a browser for layout work; bridge features are disabled there (`BRIDGE` is null).

## Rules

0. Catalog schema additions in v2 (all optional, `esquema` stays 1): `ind` (`[[industria, uso], …]`), `eq` (industrial equivalent), `how` (physical principle); sector `defensa` ("Defensa y campo": dual-use, defensive / civil-protection framing, keeps its note on responsible use and export controls), family `com` (communication), bus `CAN`. Update `LEEME.md` and `validar.py` together with any further change and tell José Noel so the monthly task prompt can be updated.
1. **Do not break the catalog schema** in `LEEME.md`. A monthly Claude scheduled task edits `~/Applications/RadarSensores-datos/catalogo.json` following that schema and `validar.py`. If a feature needs a schema change, update `LEEME.md`, `validar.py` and the bundled `catalogo.json` together, bump `esquema` only if old files become invalid, and tell José Noel so the monthly task prompt can be updated.
2. Never write secrets, tokens or personal data into the repo. The data folder stays out of git.
3. UI text is Latin American Spanish. Keep the existing design tokens in the `:root` block (light and dark themes).
4. No external network calls from JS; all fetching goes through Swift (`actualizar`). New feeds go in `catalogo.json` → `fuentes`.
5. Escape all untrusted text (feed titles, summaries, catalog strings) with `esc()` before inserting HTML.
6. After changes: run `validar.py`, rebuild with `build.sh`, open the app, and check the browser console is clean (Safari → Develop menu, if enabled).
7. Commit in small steps with clear messages; do not commit `build.log` or the `.app`.
