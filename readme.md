# Compose-stacks voor s4ndyp-repo's

Elke submap bevat een `compose.yaml` met de benodigde gegevens om die app te draaien.
Starten: `cd <repo-naam> && docker compose up -d` (of via Dockhand als stack-plak).

**Deploy-model:** elke app draait op een eigen LXC. De browser-toegang is daarom
altijd **host-poort 80**; de container-interne poort blijft zoals de app zelf luistert.
De host-poort blijft via de env-var overschrijfbaar mocht het ooit nodig zijn.

De meeste stacks gebruiken de publieke GHCR-image `ghcr.io/s4ndyp/<repo>:latest`.

| Map | App | Host → intern | Gegevens |
|---|---|---|---|
| appflowy | AppFlowy Cloud (extern; self-hosted workspace-/notitie-app: Rust-API + Postgres + Redis + S3-opslag + web-client + admin-console) | 80 → 80 (eigen nginx) | images gepind (`appflowy_cloud`/`appflowy_worker`/`appflowy_search` 0.21.9, `gotrue` 0.20.6, `admin_frontend` 0.20.4, `appflowy_web` 0.20.15), **`pgsty/silo`** i.p.v. de verdwenen `minio/minio`-images, 4 volumes; db/redis/opslag blijven intern; verplichte stackvariabelen uit Infisical-map `/appflowy` + `APPFLOWY_CONF_REF` (commit-SHA) |
| assetvault | AssetVault (PocketBase) | 80 → 8090 | image, volume |
| backai | BackAI (PocketBase + UI) | 80 → 8090 | env `BACKAI_AGENT_REGISTER_KEY` |
| beszel | Beszel hub (extern; monitoring-dashboard voor de eigen agents, PocketBase) | 80 → 8090; 8090 → 8090 (agent-contract) | image `0.21.1` (gepind), bind-mount `/opt/beszel/beszel_data` (overgenomen van de native installatie) |
| dyncompare | DynCompare (app + sync) | 80 → 8090; sync 8080 → 8091 | image x2, volume |
| fileshare | FileShare (Node) | 80 → 3000 | build vanaf GitHub, volume, `MAX_FILE_SIZE` |
| financepro | FinancePro (PocketBase) | 80 → 8090 | image, volume |
| forgejo | Forgejo (extern; self-hosted Git-service, Gitea-fork) | 80 → 3000; SSH 2222 → 2222 | image `codeberg.org/forgejo/forgejo:17.0.1` (gepind), volume `forgejo_data`, OIDC via Pocket ID (auth-bron in DB) |
| gpstag | GPSTag (PocketBase + hooks) | 80 → 8090 | image, volume |
| gods-eye-view | God's Eye View (extern; Vite-dev-server = client + API-proxies) | 80 → 4173 | build vanaf GitHub, env `GEV_ALLOWED_HOSTS`; geen volumes (caches zijn regeneratief) |
| headscale | Headscale + Headplane (extern; Tailscale-controlserver + web-UI) | 80 → 3000 (UI op `/admin`); control/API 8080 → 8080 | images gepind (`headscale 0.29.7`, `headplane 0.8.2`), 4 volumes; stack-variabelen COOKIE_SECRET/HEADSCALE_API_KEY/OIDC_* (Infisical map `/headscale`) |
| iconator | Iconator (PocketBase) | 80 → 8080 | image, volume |
| ipey | iPEY (Node + nginx) | 80 → 80 | image |
| infisical | Infisical secrets-manager (backend + Postgres + Redis) | 80 → 8080 | image `v0.167.6` (gepind), **verplichte `.env`** (zie `.env.example`); db/redis niet gepubliceerd |
| listvault | ListVault (PocketBase) | 80 → 80 | image, volume |
| netdata | Netdata parent (extern; metrics-centralisatiepunt + eigen dashboards + eigen SABnzbd-collector) | 80 → 19999; 19999 → 19999 | image `v2.12.3` (gepind), 3 volumes, **verplichte** stack-variabelen NETDATA_STREAM_API_KEY + SABNZBD_APIKEY (Infisical map /netdata) |
| netdata-child-ugnaz | Netdata child-agent op de Unraid-host UGNAZ (10.1.1.4) — streamt naar de parent | geen (stream-only) | image `v2.12.3` (gepind), 3 volumes, `SYS_PTRACE` + `pid: host`, **verplichte** stack-var NETDATA_STREAM_API_KEY (Infisical map /netdata), Dockhand-env 11 |
| netdata-child-rnaz | Netdata child-agent op de Unraid-host RNAZ (10.1.1.2) — streamt naar de parent | geen (stream-only) | idem, maar **vereist eerst een Dockhand-env voor RNAZ** (Docker-API aanzetten op de NAS) |
| netronome | Netronome (extern; netwerk-snelheidstest + monitoring, Go+React) | 80 → 7575 | image `v0.16.0` (gepind), volume, `NET_RAW` (ping/mtr), stack-var `NETRONOME_SPEEDTEST_TIMEOUT` (default 120) |
| notelight | NoteLight (PocketBase) | 80 → 8080 | image, volume |
| onvif-explorer | OnvifExplorer + go2rtc | 80 → 8080; go2rtc 1984 | image x2, env `GO2RTC_PUBLIC_URL` |
| pocket-id | Pocket ID (extern; OIDC met passkeys, Go+SQLite) | 80 → 1411 | image `pocketid/pocket-id:v2`, volume `pocketid_data`, stack-var `APP_URL` (MOET een domein zijn — passkeys/RPID) + Infisical-secret `ENCRYPTION_KEY` |
| quicknote | QuickNote capture-proxy | 80 → 80 | image, env `IGNIS_UPSTREAM` |
| rclone_ui | Rclone UI (manager + rclone) | 80 → 8080 | image x2, fuse/privileged, volumes; rclone-rc alleen intern |
| rtsp2onvif | RTSP→ONVIF UI + go2rtc | 80 → 80 (UI); go2rtc 1984/8554/8555 | go2rtc-image + inline-build UI, inline config |
| snapzilla | SnapZilla (PB + web + analyzer) | 80 → 80 (web) | build vanaf GitHub, env `OPENROUTER_API_KEY`; PB/analyzer intern |
| signoz | SigNoz observability (extern; UI + OTel-ingester + ClickHouse + Keeper + Postgres) | 80 → 8080 (UI); OTLP 4317/4318 | images gepind (`signoz v0.149.0`, `otel-collector v0.144.15`, clickhouse 25.12.5, postgres 16), 4 volumes; db/keeper/clickhouse intern |
| supermemory-dashboard | Supermemory-dashboard (extern; webinterface voor de self-hosted Supermemory, SPA + nginx-`/api`-proxy) | 80 → 80 | image, env `SUPERMEMORY_UPSTREAM` (default de supermemory-instance op dezelfde LXC) |
| supermarkey | SuperMarkey (nginx PWA) | 80 → 80 | image |
| dashbrr | Dashbrr (extern dashboard + Postgres) | 8080 → 8080 (eigen opzet, wijkt af van de 80-norm; db 5432 publiek) | image x2 |
| uptime-kotlin | UptimeKotlin (extern; Quarkus native + Postgres) | 80 → 8080; db intern | image x2, verplichte `.env`-variabelen (ENCRYPTION_MASTER_KEY, UPTIME_DB_PASSWORD) |
| sync-ms | Sync-MS (PocketBase + collector) | 80 → 8090 | image, volume, interval/retention |
| tinynote | TinyNote (PocketBase) | 80 → 8080 | image, volume |
| tracknote | TrackNote (PocketBase + UI) | 80 → 8090 | image, volume |
| wallpaparr | Wallpaparr (PocketBase + donkere web-UI) | 80 → 8090 | image, volume |
| wasmme | WasmMe (admin + publiek) | 80 → 80 (publiek); admin 8080 | image x2, gedeeld volume |
| webkey | WebKey sitebouwer (Python) | 80 → 5050; preview 5051 | image `:beta`, 3 volumes |
| webtool | WebTool (Node + PocketBase) | 80 → 3000 | image, volume |

## Diensten die níét op 80 kunnen (binnen één stack)

Eén LXC bindt poort 80 maar één keer; secundaire diensten houden een eigen poort:
dyncompare `sync` (8080, peer-endpoint), beszel `hub` (8090 — de vaste `HUB_URL` van
álle agents, geen browserdienst), onvif-explorer/rtsp2onvif `go2rtc` (1984 en
stream-poorten), wasmme `admin` (8080), webkey `preview` (5051), signoz `ingester`
(4317/4318, OTLP-inname voor telemetry van andere hosts), headscale `headscale`
(8080 — de control-poort waarop de Tailscale-clients verbinden; de web-UI van headplane
houdt 80). Snapzilla's PocketBase
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
- **gods-eye-view**: externe (niet-s4ndyp) app. Geen publieke image → de image wordt bij de deploy
  door BuildKit uit de GitHub-context gebouwd (Dockhand-git-stack vereist daarom `buildOnDeploy: true`).
  Dit is géén statische site: de Vite-dev-server draait óók de API-proxies en bemiddelt provider-keys.
  Keyless werkt de app (Esri World Imagery + 21 van de 23 lagen); zodra je keys zet kan iedereen die
  poort 80 haalt je quota opmaken → dan een Pocket-ID-gate ervoor (recept: skill `proxlan-dns-management`).
  De Host-allowlist accepteert IP + localhost automatisch; de Zoraxy-route vergt `GEV_ALLOWED_HOSTS`
  met de hostnaam (default in de compose: `gods-eye-view.xdio.nl`). De build (`npm ci`) is zwaar → 4 GB RAM.
- **infisical**: externe (niet-s4ndyp) app; ook dashbrr en uptime-kotlin zijn extern. Doe `cp .env.example .env`
  op de host, gegenereer eigen `ENCRYPTION_KEY`/`AUTH_SECRET` en bewaar `ENCRYPTION_KEY`
  offline — zonder die sleutel is een `pg_data`-backup onleesbaar. Minimaal 4 GB RAM aanbevolen.
- **uptime-kotlin**: externe uptime-monitor (één Quarkus-image + Postgres). Vereist eigen
  `ENCRYPTION_MASTER_KEY` (openssl rand -base64 32) en `UPTIME_DB_PASSWORD` via `${VAR:?}` —
  de deploy faalt expliciet zonder; zet ze in Dockhand Stack → Environment.
- PocketBase-apps: eerste login via `http://<lxc-ip>/_/` admin-aanmaken.
- **wallpaparr**: PocketBase-wallpaperopslag met donkere web-UI; alle API-regels staan open
  (geen login). Uploaden/taggen/filteren kan in de browser; de Windows/Unix-client
  (`ghcr.io`-loos: losse binaries uit de repo-releases) haalt wallpapers op via
  `/api/collections/wallpapers/records` en zet ze als achtergrond, met per-monitor
  ondersteuning. Voor het toevoegen van wallpapers volstaat poort 80.
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
  **Eigen collector `sabnzbd`**: `netdata/custom-plugins.d/sabnzbd.plugin` (Netdata external-plugin
  line protocol, Python) leest de SABnzbd-API op CT123 (`10.5.0.123:7777`) en zet vijf charts onder
  het dashboard-menu `sabnzbd`: `speed` (bytes/s), `queue` (nog te gaan / totale wachtrij),
  `transfer` (**cumulatieve verzonden bytes** uit `mode=server_stats`, absolute teller — dit is de
  reeks die de transferhistorie bewaart), `transfer_rate` (incremental, uit dezelfde teller) en
  `downloaded` (vandaag / deze maand). De collector wordt niet door een image geleverd: hij staat in
  het config-volume en Netdata vindt hem via `[directories] plugins = /usr/libexec/netdata/plugins.d
  /etc/netdata/custom-plugins.d` plus `[plugins] sabnzbd = yes` in `netdata/netdata.conf`
  (interval via `[plugin:sabnzbd] update every`). De API-sleutel van SABnzbd staat **niet** in de conf:
  Dockhand injecteert `SABNZBD_APIKEY` uit Infisical map `/netdata` als omgevingsvariabele.
  Uitzetten = `sabnzbd = no` in dat bestand en redeployen; debuggen met
  `docker exec netdata /etc/netdata/custom-plugins.d/sabnzbd.plugin 5` of `docker logs netdata | grep sabnzbd`.
  **Lokaal dashboard = `http://<lxc-ip>/v3/`** (of https://netdata.xdio.nl/v3/): de root `/` toont de
  v2-onboarding-splash met een **Sign-in**-knop die naar app.netdata.cloud leidt — die overslaan
  (of op de splash "Skip and use the dashboard anonymously" kiezen; op `/v3/` is er geen splash).
  Alles blijft lokaal: geen claim-token (cloud.d leeg → ACLK uit), DISABLE_TELEMETRY/DO_NOT_TRACK aan,
  en de browser-toegang op het domein loopt via de Pocket ID-gate.
  Retentie en web-ACL staan in `netdata.conf` (tiers 2GiB/1GiB/1GiB). Child toevoegen: zet in
  `/etc/netdata/stream.conf` van die host `[stream]` met `enabled = yes`,
  `destination = 10.5.0.<parent-vmid>:19999` en dezelfde `api key`.
  **Child-agents die al klaarstaan**: `netdata-child-ugnaz` (Unraid-host UGNAZ, 10.1.1.4) en
  `netdata-child-rnaz` (Unraid-host RNAZ, 10.1.1.2). Beide zijn dezelfde stack: netdata-agent als
  Docker-container met `pid: host` + `/proc`, `/sys`, `/etc/{os-release,passwd,group}` en de
  Docker-socket read-only gemount, **geen gepubliceerde poort** (de parent toont de node; één
  80-mapping is hier dus niet nodig) en `hostname: ugnaz`/`rnaz` = de nodenaam in het dashboard.
  De repo-init-container schrijft `netdata.conf` (web alleen op 127.0.0.1, `[db] mode = ram` —
  de historie staat bij de parent) en `stream.conf` met de sleutel uit Infisical. Beheer via
  Dockhand: env **11** voor UGNAZ; RNAZ heeft nog géén env (poort 2376 staat daar dicht) en
  verschijnt pas als op die NAS de Docker-API wordt aangezet. Unraid zelf levert geen
  netdata-integratie — de agent in een container is de route (geen CA-plugin nodig).
- **headscale + headplane**: externe (niet-s4ndyp) app. Headscale is een self-hosted
  Tailscale-controlserver (WireGuard-mesh zonder Tailscale-account); headplane is de web-UI
  erboven (upstream image `ghcr.io/tale/headplane`, draait als root in de container).
  Twee routes: `headplane.xdio.nl` → `<lxc>:80` (UI op het pad **`/admin`**) en
  `headscale.xdio.nl` → `<lxc>:8080` (de `server_url` waarop Tailscale-clients verbinden —
  via Zoraxy, met het wildcard-certificaat; clients hebben https nodig).
  Headplane praat server-side met `http://headscale:8080` over het compose-netwerk.
  Beide configs zijn **templates in de repo**: `repo-init` rendert ze met de stackvariabelen
  COOKIE_SECRET, HEADSCALE_API_KEY en OIDC_CLIENT_ID/OIDC_CLIENT_SECRET (Infisical map
  `/headscale`) naar de volumes `headscale-config` en `headplane-config`. Zonder OIDC-variabelen
  start de stack met SSO uit; het OIDC-blok in `headscale-config.template.yaml` staat tussen
  `# OIDC-BEGIN` / `# OIDC-END` en wordt dan weggelaten. De templates komen uit de repo-tarball
  van **codeload.github.com**, gepind op de commit in de stackvariabele `HEADSCALE_REF`
  (zet die na elke wijziging op de nieuwe SHA — raw.githubusercontent én codeload cachen
  enkele minuten, en dan rendert een verse deploy nog de oude template). De headscale-API-key
  maak je ná de eerste deploy: `docker exec headscale /ko-app/headscale apikeys create
  --expiration 365d` → als stackvariabele HEADSCALE_API_KEY zetten en opnieuw deployen.
  SSO loopt via Pocket ID met één client voor beide diensten (callbacks
  `https://headplane.xdio.nl/admin/oidc/callback` én `https://headscale.xdio.nl/oidc/callback`,
  `pkceEnabled=true`). OIDC `only_start_if_oidc_is_available` staat uit: de LXC-resolver moet
  `pocket.xdio.nl` kunnen resolven (PVE `nameserver`, zie skill `proxlan-dns-management`).
  MagicDNS draait met `base_domain: proxlan.nl` en de AdGuard-servers als nameservers, zodat
  tailnet-clients de LAN-namen (`*.xdio.nl`, `*.prolan.nl`) gewoon oplossen; extra A-records
  beheer je in de UI (bestand `extra_records.json`, dat headscale live inleest).
  Geen embedded DERP (de host is LAN-only, STUN/UDP naar buiten kan niet) — clients gebruiken
  de publieke DERP-map als relay. Minimaal 2 GB RAM.
- **netronome**: externe (niet-s4ndyp) app. Container-intern 7575, host 80. SQLite-variant
  (upstream levert ook een postgres-compose; niet nodig voor één LXC). Data in het named volume
  `netronome_data` (/data: db, gegenereerde config.toml met session secret, logs). `NET_RAW` is
  vereist voor ping/mtr/traceroute (packet-loss-monitor). Eigen gebruikerslogin: registreer de
  eerste admin via `POST /api/auth/register` (`{"username":…,"password":…}`) vóór de app publiek
  staat — daarna is registratie gesloten. Zonder login is alleen 127.0.0.1 toegestaan (whitelist).
  OIDC kan later via `NETRONOME__OIDC_ISSUER`/`_CLIENT_ID`/`_CLIENT_SECRET`/`_REDIRECT_URL`.
  **Gebruik v0.16.0 of nieuwer** — daar zitten twee fixes in die deze deploy nodig had:
  de serverselectie-lijst (v0.6.0 pingt elke server met één gedeeld deadline van 4 s en
  filtert daarna alles weg → lege lijst; v0.16.0 houdt een duurzame catalogus bij zonder
  elke server te pingen) en de uploadmeting (de Go-bibliotheek kan een POST-redirect niet
  volgen, en bijna alle Ookla-servers antwoorden met 307 naar https → upload werd ~3 Mbps;
  v0.16.0 resolve't die redirect vooraf met een HEAD). Test na een upgrade met een server
  die redirect (bv. KPN Amstelveen 61186): upload hoort dan in de honderden Mbps te zijn.
  Nieuwste tag bepalen met `gh release list -R autobrr/netronome` (de registry-tags-API
  pagineert en verbergt de nieuwste tags).
  Losse resultaten wissen kan NIET via UI of API — de enige opschoonroute is op leeftijd
  (`POST /api/history/purge` met `{"olderThanDays":N}`; 0 = alles). Selectief wissen doe je
  rechtstreeks: container stoppen, `sqlite3 /data/.config/netronome/netronome.db
  "delete from speed_tests where id in (…)"` via een wegwerpcontainer met hetzelfde volume
  (het image heeft sqlite3 aan boord; `cp -a` de db eerst als backup), container weer starten.
  De serverlijst toont per bron max. 10 servers (`nearestServerLimit`) en de bron kies je in de
  UI (tandwiel → Speedtest.net): Local = 10 naaste bij de door Ookla bepaalde locatie (KPN
  Amstelveen valt daar net buiten: ~47 km, #11), Coordinates = 10 naaste bij eigen lat/lon
  (52.3114 / 4.8701 zet KPN bovenaan), Global = alles wat in de catalogus is opgehaald.
  De bron-keuze staat in browser-localStorage, dus niet server-side te zetten; een expliciete
  server-id (61186) werkt ook als die niet in de zichtbare lijst staat.
- **beszel**: externe (niet-s4ndyp) app. De hub is een PocketBase-binary met één datamap
  (`beszel_data`) — géén named volume maar een **bind-mount naar `/opt/beszel/beszel_data`**, de
  plek van de oude native installatie (systemd-unit `beszel-hub` is gestopt/gedisabled maar nog
  aanwezig = terugrolpad zonder datamigratie). In die map zitten `data.db`, de **hub-key
  `id_ed25519`** (het publieke deel is de `KEY` van élke agent) en de universal tokens: raak die
  niet kwijt, want dan moeten alle agents opnieuw. De 8090-mapping is de vaste `HUB_URL` van alle
  agents (PVE-nodes, Unraid-flash, UniFi-appliances, HA-add-on) — niet hernummeren. Gepind op
  `0.21.1` (= de versie die native draaide, dus geen DB-migratie; upgraden = tag ophogen in
  Dockhand). Het image is `FROM scratch` (geen shell), dus healthcheck via `/beszel health`.
- **forgejo**: externe (niet-s4ndyp) app. Officiële image `codeberg.org/forgejo/forgejo` (Alpine;
  entrypoint chownt /data). Container-intern 3000 (web) + 22 (ingebouwde SSH), host 80 resp. 2222.
  Alle config via `FORGEJO__<sectie>__<SLEUTEL>` env-vars → de image schrijft die bij de start naar
  `/data/gitea/conf/app.ini`. `INSTALL_LOCK=true` slaat de web-installatiewizard over; de instance-admin
  maak je aan de CLI aan: `docker compose exec -u git forgejo forgejo admin user create --admin
  --username <naam> --email <mail> --password <pw>` (of `--random-password`). `SECRET_KEY` staat niet in
  de compose — Forgejo genereert en bewaart er zelf een in app.ini (hoort bij de back-up; versleutelt
  2FA-/Actions-secrets). OIDC (Pocket ID) is een **authenticatiebron in de DB**, niet in dit bestand:
  `forgejo admin auth add-oauth --provider openidConnect --name pocket --key <id> --secret <secret>
  --auto-discover-url https://pocket.xdio.nl/.well-known/openid-configuration --scopes 'openid email profile'`
  met callback `https://forgejo.xdio.nl/user/oauth2/pocket/callback` (pkceEnabled=false). De app-host
  moet `pocket.xdio.nl` server-side kunnen resolven (CT-resolver via PVE, zie skill proxlan-dns-management).
- **supermemory-dashboard**: externe (niet-s4ndyp) app — een fork van
  `Ansh-Sonkusare/supermemory-dashboard`, de open-source web-UI die het dashboard herstelt dat
  upstream uit de supermemory-binary haalde. De self-hosted binary is headless (alleen een
  minimale welkomstpagina) en stuurt **geen CORS-headers**, dus de statische SPA draait achter
  nginx die `/api/*` doorproxyt naar de supermemory-instance. Draait op **dezelfde LXC als de
  supermemory-stack** (CT157, Dockhand-env 22): poort 80 is de UI, de API blijft op 6767.
  De **API-key** voer je één keer in op de Settings-pagina (blijft in browser-localStorage;
  de server bewaart niets) — hetzelfde `sm_…`-token uit `/data/api-key` in het volume
  `supermemory-data`. Het gebruikt de legacy `/v3/documents|search`-routes die de binary
  naast de `/ns/{namespace}`-routes ook bedient. Route: https://supermemory.xdio.nl
  (Zoraxy → `10.5.0.157:80`, geen Pocket-ID-gate — bewust, het is een persoonlijke UI).
  De repo publiceert de image `ghcr.io/s4ndyp/supermemory-dashboard:latest` via GitHub Actions.
