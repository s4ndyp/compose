#!/bin/sh
# Rendert de headscale- en headplane-config uit de templates in deze repo naar de
# twee config-volumes (/hs = headscale-config, /hp = headplane-config).
#
# Draait als eenmalige init-container bij elke deploy. De repo-tarball wordt door de
# entrypoint uit codeload.github.com gehaald (niet raw.githubusercontent.com: dat cachet
# ±5 minuten en levert dan een verouderde template) en hier uitgepakt.
# Env-variabelen komen uit de Dockhand-stackvariabelen (COOKIE_SECRET,
# HEADSCALE_API_KEY, OIDC_*, BASE_URL).
set -eu

SRC="${SRC:-$(ls -d /tmp/compose-src/*/headscale 2>/dev/null | head -1)}"

cp "$SRC/headscale-config.template.yaml" /hs/hs.tmpl
cp "$SRC/headplane-config.template.yaml" /hp/hp.tmpl
cp "$SRC/acl.hujson" /hs/acl.hujson

[ -f /hs/extra_records.json ] || printf '[]' > /hs/extra_records.json

if [ -n "${OIDC_CLIENT_ID:-}" ]; then
  sed -e "s|__OIDC_CLIENT_ID__|${OIDC_CLIENT_ID}|g" \
      -e "s|__OIDC_CLIENT_SECRET__|${OIDC_CLIENT_SECRET}|g" /hs/hs.tmpl > /hs/config.yaml
  OE=true
else
  sed '/# OIDC-BEGIN/,/# OIDC-END/d' /hs/hs.tmpl > /hs/config.yaml
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
