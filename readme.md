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
| netdata | Netdata parent (extern; metrics-centralisatiepunt + eigen dashboards) | 80 → 19999 | image `v2.12.3` (gepind), 3 volumes, **verplichte** stack-variabele NETDATA_STREAM_API_KEY (Infisical map /netdata) |
| netronome | Netronome (extern; netwerk-snelheidstest + monitoring, Go+React) | 80 → 7575 | image `v0.6.0` (gepind), volume, `NET_RAW` (ping/mtr) |
| notelight | NoteLight (PocketBase) | 80 → 8080 | image, volume |
| onvif-explorer | OnvifExplorer + go2rtc | 80 → 8080; go2rtc 1984 | image x2, env `GO2RTC_PUBLIC_URL` |
| pocket-id | Pocket ID (extern; OIDC met passkeys, Go+SQLite) | 80 → 1411 | image `pocketid/pocket-id:v2`, volume `pocketid_data`, stack-var `APP_URL` (MOET een domein zijn — passkeys/RPID) + Infisical-secret `ENCRYPTION_KEY` |
| quicknote | QuickNote capture-proxy | 80 → 80 | image, env `IGNIS_UPSTREAM` |
| rclone_ui | Rclone UI (manager + rclone) | 80 → 8080 | image x2, fuse/privileged, volumes; rclone-rc alleen intern |
| rtsp2onvif | RTSP→ONVIF UI + go2rtc | 80 → 80 (UI); go2rtc 1984/8554/8555 | go2rtc-image + inline-build UI, inline config |
| snapzilla | SnapZilla (PB + web + analyzer) | 80 → 80 (web) | build vanaf GitHub, env `OPENROUTER_API_KEY`; PB/analyzer intern |
| signoz | SigNoz observability (extern; UI + OTel-ingester + ClickHouse + Keeper + Postgres) | 80 → 8080 (UI); OTLP 4317/4318 | images gepind (`signoz v0.149.0`, `otel-collector v0.144.15`, clickhouse 25.12.5, postgres 16), 4 volumes; db/keeper/clickhouse intern |
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
stream-poorten), wasmme `admin` (8080), webkey `preview` (5051), signoz `ingester`
(4317/4318, OTLP-inname voor telemetry van andere hosts). Snapzilla's PocketBase
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

- **Audit nov 2026 (valkuilen externe daemon):** alle stacks gecontroleerd op file-binds, `service_healthy`
  zonder healthcheck, shell-command-interpretatie en `$`-interpolatie. Enige treffer: dashbrr `./data` →
  omgezet naar named volume `dashbrr_data` (sessions.json gemigreerd). fileshare en rtsp2onvif bevatten
  `build:`-services maar zijn níét als Dockhand-git-stack gedeployed — bij een latere Dockhand-deploy daar
  `buildOnDeploy: true` zetten, anders faalt de pull op de lokale buildnamen.

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
- **signoz**: externe (niet-s4ndyp) app. Upstream distributed geen losse compose meer
  (deprecated sinds v0.130.0); deze stack is gegenereerd met `foundryctl forge`
  (Foundry, flavor=compose) en handmatig gepind op de image-tags uit de tabel.
  Upgrade via nieuwe Foundry-forge of tags rechtstreeks ophogen. Minimaal 8 GB RAM
  op de LXC (ClickHouse + Postgres + Keeper + collector). Eerste login: open `http://<lxc-ip>/`
  en registreer de instance-admin vóór eerste gebruik.
- **netdata**: externe (niet-s4ndyp) app; draait als metrics-PARENT (centralisatiepunt) waarop je
  later child-agents laat streamen. Container-intern 19999; gepubliceerd op host 80 (browser-route) én
  host 19999 (streaming-endpoint voor child-agents — de netdata-standaardpoort, geen HTTP dus geen
  browser-dienst). Die 19999 moet vanaf de child-hosts bereikbaar blijven (niet dichtzetten).
  De API-sleutel staat niet in git: de template `netdata/stream.conf` bevat de placeholder
  `@NETDATA_STREAM_API_KEY@`, die de `repo-init`-container bij de deploy vervangt door de waarde van de
  stack-variabele NETDATA_STREAM_API_KEY uit Infisical (map `/netdata`, via `DOCKHAND_SECRET_SELECTOR`).
  **Lokaal dashboard = `http://<lxc-ip>/v3/`** (of https://netdata.xdio.nl/v3/): de root `/` toont de
  v2-onboarding-splash met een **Sign-in**-knop die naar app.netdata.cloud leidt — die overslaan
  (of op de splash "Skip and use the dashboard anonymously" kiezen; op `/v3/` is er geen splash).
  Alles blijft lokaal: geen claim-token (cloud.d leeg → ACLK uit), DISABLE_TELEMETRY/DO_NOT_TRACK aan,
  en de browser-toegang op het domein loopt via de Pocket ID-gate.
  Retentie en web-ACL staan in `netdata.conf` (tiers 2GiB/1GiB/1GiB). Child toevoegen: zet in
  `/etc/netdata/stream.conf` van die host `[stream]` met `enabled = yes`,
  `destination = 10.5.0.<parent-vmid>:19999` en dezelfde `api key`.
- **netronome**: externe (niet-s4ndyp) app. Container-intern 7575, host 80. SQLite-variant
  (upstream levert ook een postgres-compose; niet nodig voor één LXC). Data in het named volume
  `netronome_data` (/data: db, gegenereerde config.toml met session secret, logs). `NET_RAW` is
  vereist voor ping/mtr/traceroute (packet-loss-monitor). Eigen gebruikerslogin: registreer de
  eerste admin via `POST /api/auth/register` (`{"username":…,"password":…}`) vóór de app publiek
  staat — daarna is registratie gesloten. Zonder login is alleen 127.0.0.1 toegestaan (whitelist).
  OIDC kan later via `NETRONOME__OIDC_ISSUER`/`_CLIENT_ID`/`_CLIENT_SECRET`/`_REDIRECT_URL`.
