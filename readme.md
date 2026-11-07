# Compose-stacks voor s4ndyp-repo's

Elke submap bevat een `compose.yaml` met de benodigde gegevens om die app te draaien.
Starten: `cd <repo-naam> && docker compose up -d` (of via Dockhand als stack-plak).

**Deploy-model:** elke app draait op een eigen LXC. De browser-toegang is daarom
altijd **host-poort 80**; de container-interne poort blijft zoals de app zelf luistert.
De host-poort blijft via de env-var overschrijfbaar mocht het ooit nodig zijn.

De meeste stacks gebruiken de publieke GHCR-image `ghcr.io/s4ndyp/<repo>:latest`.

| Map | App | Host → intern | Gegevens |
|---|---|---|---|
| assetvault | AssetVault (PocketBase) | 80 → 8090 | image, volume |
| backai | BackAI (PocketBase + UI) | 80 → 8090 | env `BACKAI_AGENT_REGISTER_KEY` |
| dyncompare | DynCompare (app + sync) | 80 → 8090; sync 8098 → 8091 | image x2, volume |
| filehog | FileHog (PocketBase) | 80 → 8080 | image, volume |
| fileshare | FileShare (Node) | 80 → 3000 | build vanaf GitHub, volume, `MAX_FILE_SIZE` |
| financepro | FinancePro (PocketBase) | 80 → 8090 | image, volume |
| gpstag | GPSTag (PocketBase + hooks) | 80 → 8090 | image, volume |
| iconator | Iconator (PocketBase) | 80 → 8080 | image, volume |
| ipey | iPEY (Node + nginx) | 80 → 80 | image |
| infisical | Infisical secrets-manager (backend + Postgres + Redis) | 80 → 8080 | image `v0.167.6` (gepind), **verplichte `.env`** (zie `.env.example`); db/redis niet gepubliceerd |
| listvault | ListVault (PocketBase) | 80 → 80 | image, volume |
| locator | Locator (PocketBase) | 80 → 8090 | image, volume |
| notelight | NoteLight (PocketBase) | 80 → 8080 | image, volume |
| onvif-explorer | OnvifExplorer + go2rtc | 80 → 8080; go2rtc 1984 | image x2, env `GO2RTC_PUBLIC_URL` |
| pocket-id | Pocket ID (extern; OIDC met passkeys, Go+SQLite) | 80 → 1411 | image `pocketid/pocket-id:v2`, volume `pocketid_data`, stack-var `APP_URL` + Infisical-secret `ENCRYPTION_KEY` |
| quicknote | QuickNote capture-proxy | 80 → 80 | image, env `IGNIS_UPSTREAM` |
| rclone_ui | Rclone UI (manager + rclone) | 80 → 8080 | image x2, fuse/privileged, volumes; rclone-rc alleen intern |
| rtsp2onvif | RTSP→ONVIF UI + go2rtc | 80 → 80 (UI); go2rtc 1984/8554/8555 | go2rtc-image + inline-build UI, inline config |
| snapzilla | SnapZilla (PB + web + analyzer) | 80 → 80 (web) | build vanaf GitHub, env `OPENROUTER_API_KEY`; PB/analyzer intern |
| supermarkey | SuperMarkey (nginx PWA) | 80 → 80 | image |
| dashbrr | Dashbrr (extern dashboard + Postgres) | 8080 → 8080 (eigen opzet, wijkt af van de 80-norm; db 5432 publiek) | image x2 |
| uptime-kotlin | UptimeKotlin (extern; Quarkus native + Postgres) | 80 → 8080; db intern | image x2, verplichte `.env`-variabelen (ENCRYPTION_MASTER_KEY, UPTIME_DB_PASSWORD) |
| sync-ms | Sync-MS (PocketBase + collector) | 80 → 8090 | image, volume, interval/retention |
| tinynote | TinyNote (PocketBase) | 80 → 8080 | image, volume |
| tracknote | TrackNote (PocketBase + UI) | 80 → 8090 | image, volume |
| wasmme | WasmMe (admin + publiek) | 80 → 80 (publiek); admin 8080 | image x2, gedeeld volume |
| webkey | WebKey sitebouwer (Python) | 80 → 5050; preview 5051 | image `:beta`, 3 volumes |
| webtool | WebTool (Node + PocketBase) | 80 → 3000 | image, volume |

## Diensten die níét op 80 kunnen (binnen één stack)

Eén LXC bindt poort 80 maar één keer; secundaire diensten houden een eigen poort:
dyncompare `sync` (8098, peer-endpoint), onvif-explorer/rtsp2onvif `go2rtc` (1984 en
stream-poorten), wasmme `admin` (8080), webkey `preview` (5051). Snapzilla's PocketBase
en analyzer zijn alleen intern bereikbaar — de web-nginx proxyt `/api/` en `/_/` naar
PocketBase, dus alles wat de browser nodig heeft zit achter poort 80.

## Overgeslagen repo's (geen draaibare server-app)

- `scripts` — shell-scripts, geen app
- `date_line`, `shortag`, `xport` — Obsidian-plugins (draaien in Obsidian, niet in Docker)
- `ignis_capture` — browserextensie
- `tolaria` — desktop-app (markdown knowledge base)
- `onvifviewer` — Qt/C++ desktop-app
- `f1-race-replay` — Python/pyglet-visualisatie met lokaal venster, geen web-service

## Opmerkingen

- **snapzilla**: geen publieke GHCR-image; web/analyzer worden vanaf GitHub gebouwd en
  `pb_migrations` komen via een eenmalige `repo-init`-container in een volume.
  Zet `OPENROUTER_API_KEY` in `.env` om AI-analyse werkend te krijgen.
- **fileshare / rtsp2onvif**: bouwen eveneens vanaf GitHub (BuildKit git-context).
- **infisical**: externe (niet-s4ndyp) app; ook dashbrr en uptime-kotlin zijn extern. Doe `cp .env.example .env`
  op de host, gegenereer eigen `ENCRYPTION_KEY`/`AUTH_SECRET` en bewaar `ENCRYPTION_KEY`
  offline — zonder die sleutel is een `pg_data`-backup onleesbaar. Minimaal 4 GB RAM aanbevolen.
- **uptime-kotlin**: externe uptime-monitor (één Quarkus-image + Postgres). Vereist eigen
  `ENCRYPTION_MASTER_KEY` (openssl rand -base64 32) en `UPTIME_DB_PASSWORD` via `${VAR:?}` —
  de deploy faalt expliciet zonder; zet ze in Dockhand Stack → Environment.
- PocketBase-apps: eerste login via `http://<lxc-ip>/_/` admin-aanmaken.
