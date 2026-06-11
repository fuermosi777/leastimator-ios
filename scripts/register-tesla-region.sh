#!/usr/bin/env bash
#
# Register your Tesla Fleet API partner account in a given region.
#
# Tesla's Fleet API is regionally sharded. You must register your partner
# account (POST /api/1/partner_accounts) in EACH region you serve, otherwise
# users in that region get HTTP 421 "user out of region".
#
# Prerequisite: your public key must be reachable at
#   https://<domain>/.well-known/appspecific/com.tesla.3p.public-key.pem
# Tesla fetches and validates it during registration. (If NA registration
# already succeeded, this is already in place.)
#
# Usage:
#   export TESLA_CLIENT_ID=...
#   export TESLA_CLIENT_SECRET=...
#   ./scripts/register-tesla-region.sh EU        # region: NA | EU | CN
#
# Optional:
#   export TESLA_DOMAIN=liuhao.im                # defaults to liuhao.im
#
# Requires: curl, jq

set -euo pipefail

REGION="${1:?Usage: $0 <NA|EU|CN>}"
DOMAIN="${TESLA_DOMAIN:-liuhao.im}"
CLIENT_ID="${TESLA_CLIENT_ID:?Set TESLA_CLIENT_ID}"
CLIENT_SECRET="${TESLA_CLIENT_SECRET:?Set TESLA_CLIENT_SECRET}"

region_host() {
  case "$1" in
    NA) echo "fleet-api.prd.na.vn.cloud.tesla.com" ;;
    EU) echo "fleet-api.prd.eu.vn.cloud.tesla.com" ;;
    CN) echo "fleet-api.prd.cn.vn.cloud.tesla.cn" ;;
    *)  echo "" ;;
  esac
}

HOST="$(region_host "$REGION")"
if [[ -z "$HOST" ]]; then
  echo "ERROR: unknown region '$REGION' (expected NA, EU, or CN)" >&2
  exit 1
fi

AUTH_URL="https://auth.tesla.com/oauth2/v3/token"
AUDIENCE="https://$HOST"
SCOPE="openid vehicle_device_data"

echo "Region:  $REGION ($HOST)"
echo "Domain:  $DOMAIN"
echo "Requesting partner token (client-credentials, audience=$AUDIENCE)..."

TOKEN_RESP="$(curl -sS -X POST "$AUTH_URL" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode "grant_type=client_credentials" \
  --data-urlencode "client_id=$CLIENT_ID" \
  --data-urlencode "client_secret=$CLIENT_SECRET" \
  --data-urlencode "scope=$SCOPE" \
  --data-urlencode "audience=$AUDIENCE")"

PARTNER_TOKEN="$(echo "$TOKEN_RESP" | jq -r '.access_token // empty')"
if [[ -z "$PARTNER_TOKEN" ]]; then
  echo "ERROR: failed to obtain partner token. Response:" >&2
  echo "$TOKEN_RESP" | jq . >&2 || echo "$TOKEN_RESP" >&2
  exit 1
fi

echo "Registering $DOMAIN in $REGION..."
RESP="$(curl -sS -w $'\n%{http_code}' -X POST "https://$HOST/api/1/partner_accounts" \
  -H "Authorization: Bearer $PARTNER_TOKEN" \
  -H 'Content-Type: application/json' \
  -d "{\"domain\": \"$DOMAIN\"}")"

HTTP_CODE="$(echo "$RESP" | tail -n1)"
PAYLOAD="$(echo "$RESP" | sed '$d')"

echo "HTTP $HTTP_CODE"
echo "$PAYLOAD" | jq . 2>/dev/null || echo "$PAYLOAD"

if [[ "$HTTP_CODE" == "200" ]]; then
  echo
  echo "Registered. Re-run check-tesla-regions.sh to confirm $REGION shows YES."
else
  echo
  echo "Registration did not return 200. Common causes:" >&2
  echo "  - public key not reachable at https://$DOMAIN/.well-known/appspecific/com.tesla.3p.public-key.pem" >&2
  echo "  - token scope lacks partner permissions" >&2
fi
