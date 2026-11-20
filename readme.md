# Compose-stacks voor s4ndyp-repo's

Elke submap bevat een `compose.yaml` met de benodigde gegevens om die app te draaien.
Starten: `cd <repo-naam> && docker compose up -d` (of via Dockhand als stack-plak).

**Deploy-model:** elke app draait op een eigen LXC. De browser-toegang is daarom
altijd **host-poort 80**; de container-interne poort blijft zoals de app zelf luistert.
De host-poort blijft via de env-var overschrijfbaar mocht het ooit nodig zijn.

> **Deze repo bevat sinds 18-11-2026 alleen nog externe/third-party stacks** (Forgejo, Infisical,
> Homarr, Pocket ID, RustDesk, Beszel, Netronome, Dashbrr, AppFlowy, Uptime-Kotlin,
> God's Eye View en de Forgejo-runner).
>
> De **eigen apps** (`fileshare`, `listvault`, `tinynote`, `wallpaparr`, `financepro`, `gpstag`, `iconator`,
> `quicknote`, `sync-ms`, `dyncompare`, `snapzilla`, `supermemory-dashboard`, `assetvault`, `backai`,
> `notelight`, `onvif-explorer`, `supermarkey`, `tracknote`, `wasmme`, `webkey`, `webtool`, `rclone_ui`,
> `ipey`) hebben hun `compose.yaml` in **hun eigen repo op Forgejo** (`forgejo.xdio.nl/sandman/<app>`),
> met een image uit de eigen registry `forgejo.xdio.nl/sandman/<app>:latest`, gebouwd door
> `.forgejo/workflows/build.yml` in die repo. Dockhand hangt die stacks aan de Forgejo-repo, niet meer aan deze.

| Map | App | Host → intern | Gegevens |
|---|---|---|---|
| appflowy | AppFlowy Cloud (extern; self-hosted workspace-/notitie-app: Rust-API + Postgres + Redis + S3-opslag + web-client + admin-console) | 80 → 80 (eigen nginx) | images gepind (`appflowy_cloud`/`appflowy_worker`/`appflowy_search` 0.21.9, `gotrue` 0.20.6, `admin_frontend` 0.20.4, `appflowy_web` 0.20.15), **`pgsty/silo`** i.p.v. de verdwenen `minio/minio`-images, 4 volumes; db/redis/opslag blijven intern; verplichte stackvariabelen uit Infisical-map `/appflowy` + `APPFLOWY_CONF_REF` (commit-SHA) |
| beszel | Beszel hub (extern; monitoring-dashboard voor de eigen agents, PocketBase) | 80 → 8090; 8090 → 8090 (agent-contract) | image `0.21.1` (gepind), bind-mount `/opt/beszel/beszel_data` (overgenomen van de native installatie) |
| forgejo | Forgejo (extern; self-hosted Git-service, Gitea-fork) | 80 → 3000; SSH 2222 → 2222 | image `codeberg.org/forgejo/forgejo:17.0.1` (gepind), volume `forgejo_data`, OIDC via Pocket ID (auth-bron in DB) |
| forgejo-runner | Forgejo Actions runner (eigen LXC CT138; DinD + forgejo-runner 13.2.1 + docker:29-dind) | geen browser-poort | 3 volumes (runner_data/dind_data/docker_certs); **verplichte** stack-variabelen FORGEJO_RUNNER_UUID + FORGEJO_RUNNER_SECRET (Infisical map `/forgejo/runner`, selector `DOCKHAND_SECRET_SELECTOR`); labels ubuntu-latest/ubuntu-22.04/ubuntu-24.04/docker |
| gods-eye-view | God's Eye View (extern; Vite-dev-server = client + API-proxies) | 80 → 4173 | build vanaf GitHub, env `GEV_ALLOWED_HOSTS`; geen volumes (caches zijn regeneratief) |
| infisical | Infisical secrets-manager (backend + Postgres + Redis) | 80 → 8080 | image `v0.167.6` (gepind), **verplichte `.env`** (zie `.env.example`); db/redis niet gepubliceerd |
| netronome | Netronome (extern; netwerk-snelheidstest + monitoring, Go+React) | 80 → 7575 | image `v0.16.0` (gepind), volume, `NET_RAW` (ping/mtr), stack-var `NETRONOME_SPEEDTEST_TIMEOUT` (default 120) |
| pocket-id | Pocket ID (extern; OIDC met passkeys, Go+SQLite) | 80 → 1411 | image `pocketid/pocket-id:v2`, volume `pocketid_data`, stack-var `APP_URL` (MOET een domein zijn — passkeys/RPID) + Infisical-secret `ENCRYPTION_KEY` |
| prometheus-grafana | Prometheus + Grafana (extern; metrics-TSDB + dashboard-UI, samen in één stack/LXC) | 80 → 3000 (Grafana); Prometheus 9090 → 9090 | images gepind (`prom/prometheus v3.16.0`, `grafana/grafana 13.3.1`), 2 volumes, **inline configs** (scrape-config + voorgprovisioneerde Prometheus-datasource + dashboard-provider met Syncthing-dashboard), verplichte stackvariabele `GF_ADMIN_PASSWORD` (Infisical map `/prometheus_grafana`) |
| dashbrr | Dashbrr (extern dashboard + Postgres) | 8080 → 8080 (eigen opzet, wijkt af van de 80-norm; db 5432 publiek) | image x2 |
| uptime-kotlin | UptimeKotlin (extern; Quarkus native + Postgres) | 80 → 8080; db intern | image x2, verplichte `.env`-variabelen (ENCRYPTION_MASTER_KEY, UPTIME_DB_PASSWORD) |

## Diensten die níét op 80 kunnen (binnen één stack)

Eén LXC bindt poort 80 maar één keer; secundaire diensten houden een eigen poort:
beszel `hub` (8090 — de vaste `HUB_URL` van álle agents, geen browserdienst),
prometheus-grafana `prometheus` (9090 — eigen domein `prometheus.xdio.nl`, Grafana houdt 80) en dashbrr (8080, eigen opzet).
De eigen apps houden hun eigen poortafspraken in hun eigen repo (o.a. dyncompare `sync` 8080,
onvif-explorer `go2rtc` 1984, wasmme `admin` 8080, webkey `preview` 5051).

## Overgeslagen repo's (geen draaibare server-app)

- `scripts` — shell-scripts, geen app
- `date_line`, `shortag`, `xport` — Obsidian-plugins (draaien in Obsidian, niet in Docker)
- `ignis_capture` — browserextensie
- `tolaria` — desktop-app (markdown knowledge base)
- `onvifviewer` — Qt/C++ desktop-app
- `f1-race-replay` — Python/pyglet-visualisatie met lokaal venster, geen web-service

## Opmerkingen

- **prometheus-grafana**: externe (niet-s4ndyp) apps in één stack, want ze horen bij elkaar: Grafana
  haalt zijn metrics bij `http://prometheus:9090` over het compose-netwerk. Twee routes: `grafana.xdio.nl` →
  `<lxc>:80` en `prometheus.xdio.nl` → `<lxc>:9090` (Zoraxy + AdGuard-rewrite, beide). Configs staan
  **inline** in de compose (scrape-config, een voorgprovisioneerde Prometheus-datasource in Grafana én
  een dashboard-provider + dashboard-JSON); een target of dashboard toevoegen = hier aanpassen + redeploy.
  Het Grafana-admin-wachtwoord staat in
  Infisical-map `/prometheus_grafana` (gestuurd door de stackvariabele
  `DOCKHAND_SECRET_SELECTOR`). Prometheus bewaart 30 dagen in `prometheus_data`.
  Grafana heeft **native Pocket ID-OIDC** (generic OAuth, client 'Grafana', callback
  `https://grafana.xdio.nl/login/generic_oauth`; client-id/secret uit dezelfde Infisical-map),
  de lokale admin-login blijft als break-glass. Prometheus heeft géén auth van zichzelf en blijft
  daarom LAN-only (geen gate). Als scrape-target loopt er een derde job mee: **wg-easy**
  (CT170, `http://10.5.0.170:51821/metrics/prometheus`, Bearer-token uit Infisical — aanzetten/roteren in
  wg-easy → Admin → General), met het WireGuard-dashboard 21733 in Grafana.
  Daarnaast loopt er een **Syncthing-job** (twee instanties, native `/metrics` op de GUI-poort 8384:
  CT139 `sync-naz` en 10.5.0.134 `ignis`), met het **Syncthing-dashboard** (uid `syncthing-homelab`,
  provisioned uit deze stack): bereikbaarheid, verbindingen en doorvoer per apparaat (device-ID's
  via `syncthing_config_device_info` naar namen), mapgroottes/need-bytes per map, scans/pulls,
  conflicten en proces-CPU/geheugen.

- **Audit nov 2026 (valkuilen externe daemon):** alle stacks gecontroleerd op file-binds, `service_healthy`
  zonder healthcheck, shell-command-interpretatie en `$`-interpolatie. Enige treffer: dashbrr `./data` →
  omgezet naar named volume `dashbrr_data` (sessions.json gemigreerd).

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
