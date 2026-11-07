# Compose-stacks voor s4ndyp-repo's

Elke submap bevat een `compose.yaml` met de benodigde gegevens om die app te draaien.
Starten: `cd <repo-naam> && docker compose up -d` (of via Dockhand als stack-plak).

De meeste stacks gebruiken de publieke GHCR-image `ghcr.io/s4ndyp/<repo>:latest`;
host-poorten zijn te overschrijven via env-var (zie het bestand).

| Map | App | Poort (host) | Gegevens |
|---|---|---|---|
| assetvault | AssetVault (PocketBase) | `ASSETVAULT_PORT` 8090 | image, volume |
| backai | BackAI (PocketBase + UI) | `BACKAI_HTTP_PORT` 8090 | env `BACKAI_AGENT_REGISTER_KEY` |
| dyncompare | DynCompare (app + sync) | 8097 / 8098 | image x2, volume |
| filehog | FileHog (PocketBase) | `FILEHOG_PORT` 8080 | image, volume |
| fileshare | FileShare (Node) | `FILESHARE_PORT` 3000 | build vanaf GitHub, volume, `MAX_FILE_SIZE` |
| financepro | FinancePro (PocketBase) | `FINANCEPRO_PORT` 7104 | image, volume |
| gpstag | GPSTag (PocketBase + hooks) | `GPSTAG_PORT` 8090 | image, volume |
| iconator | Iconator (PocketBase) | `ICONATOR_PORT` 8080 | image, volume |
| ipey | iPEY (Node + nginx) | `IPEY_PORT` 80 | image |
| listvault | ListVault (PocketBase) | `LISTVAULT_PORT` 8099 | image, volume |
| locator | Locator (PocketBase) | `LOCATOR_PORT` 8090 | image, volume |
| notelight | NoteLight (PocketBase) | `NOTELIGHT_PORT` 8084 | image, volume |
| onvif-explorer | OnvifExplorer + go2rtc | 8080 / `GO2RTC_PORT` 1984 | image x2, env `GO2RTC_PUBLIC_URL` |
| quicknote | QuickNote capture-proxy | `CAPTURE_PORT` 8080 | image, env `IGNIS_UPSTREAM` |
| rclone_ui | Rclone UI (manager + rclone) | 8080 / 5572 | image x2, fuse/privileged, volumes |
| rtsp2onvif | RTSP→ONVIF UI + go2rtc | 8088 / 1984 / 8554 / 8555 | go2rtc-image + inline-build UI, inline config |
| snapzilla | SnapZilla (PB + web + analyzer) | `SNAPZILLA_PORT` 3000 | build vanaf GitHub, env `OPENROUTER_API_KEY` |
| supermarkey | SuperMarkey (nginx PWA) | `SUPERMARKEY_PORT` 7107 | image |
| sync-ms | Sync-MS (PocketBase + collector) | `SYNCMS_HTTP_PORT` 8096 | image, volume, interval/retention |
| tinynote | TinyNote (PocketBase) | `TINYNOTE_PORT` 8080 | image, volume |
| tracknote | TrackNote (PocketBase + UI) | `TRACKNOTE_PORT` 8095 | image, volume |
| wasmme | WasmMe (admin + publiek) | 8080 / 80 | image x2, gedeeld volume |
| webkey | WebKey sitebouwer (Python) | 5050 / 5051 | image `:beta`, 3 volumes |
| webtool | WebTool (Node + PocketBase) | `WEBTOOL_PORT` 3000 | image, volume |

## Overgeslagen repo's (geen draaibare server-app)

- `scripts` — shell-scripts, geen app
- `date_line`, `shortag`, `xport` — Obsidian-plugins (draaien in Obsidian, niet in Docker)
- `ignis_capture` — browserextensie
- `tolaria` — desktop-app (markdown knowledge base)
- `onvifviewer` — Qt/C++ desktop-app
- `f1-race-replay` — Python/pyglet-visualisatie met lokaal venster, geen web-service

## Opmerkingen

- **Portcollisie**: veel apps luisteren standaard op dezelfde poort (8080/8090). Op één
  host tegelijk draaien? Overschrijf de host-poort via de env-var van die stack.
- **snapzilla**: geen publieke GHCR-image; web/analyzer worden vanaf GitHub gebouwd en
  `pb_migrations` komen via een eenmalige `repo-init`-container in een volume.
  Zet `OPENROUTER_API_KEY` in `.env` om AI-analyse werkend te krijgen.
- **fileshare / rtsp2onvif**: bouwen eveneens vanaf GitHub (BuildKit git-context).
- PocketBase-apps: eerste login via `/_/` admin-aanmaken op de gemapte poort.
