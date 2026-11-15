#!/bin/sh
# Rendert de headscale- en headplane-config uit de templates in deze repo naar de
# twee config-volumes (/hs = headscale-config, /hp = headplane-config).
# Draait als eenmalige init-container bij elke deploy; env-variabelen komen uit de
# Dockhand-stackvariabelen (COOKIE_SECRET, HEADSCALE_API_KEY, OIDC_*, BASE_URL).
# Let op: dit bestand wordt door de init-container gedownload en met `sh` uitgevoerd;
# houd het dus POSIX (busybox ash) en zonder multiline-YAML-trucs.
set -eu

B="${TEMPLATE_BASE:-https://raw.githubusercontent.com/s4ndyp/compose/main/headscale}"

wget -q -O /hs/hs.tmpl "$B/headscale-config.template.yaml"
wget -q -O /hp/hp.tmpl "$B/headplane-config.template.yaml"
wget -q -O /hs/acl.hujson "$B/acl.hujson"

[ -f /hs/extra_records.json ] || printf '[]' > /hs/extra_records.json

if [ -n "${OIDC_CLIENT_ID:-}" ]; then
  sed -e "s|__OIDC_CLIENT_ID__|${OIDC_CLIENT_ID}|g" \
      -e "s|__OIDC_CLIENT_SECRET__|${OIDC_CLIENT_SECRET}|g" /hs/hs.tmpl > /hs/config.yaml
  OE=true
else
  sed '/# >>>OIDC/,/# <<<OIDC/d' /hs/hs.tmpl > /hs/config.yaml
  OE=false
fi

sed -e "s|__BASE_URL__|${BASE_URL:-https://headplane.xdio.nl}|g" \
    -e "s|__COOKIE_SECRET__|${COOKIE_SECRET:-}|g" \
    -e "s|__API_KEY__|${HEADSCALE_API_KEY:-}|g" \
    -e "s|__OIDC_ENABLED__|$OE|g" \
    -e "s|__OIDC_CLIENT_ID__|${OIDC_CLIENT_ID:-}|g" \
    -e "s|__OIDC_CLIENT_SECRET__|${OIDC_CLIENT_SECRET:-}|g" \
    /hp/hp.tmpl > /hp/config.yaml

rm -f /hs/hs.tmpl /hp/hp.tmpl
chmod 666 /hs/config.yaml /hs/acl.hujson /hs/extra_records.json /hp/config.yaml
echo "repo-init: configs gerenderd (OIDC=$OE)"
