#!/usr/bin/env bash
#
# Check Tesla Fleet API partner registration status across regions.
#
# Tesla's Fleet API is regionally sharded. Your app's partner account must be
# registered (POST /api/1/partner_accounts) against EACH region you want to
# serve. A user whose account lives in a region where you are NOT registered
# will get HTTP 421 "user out of region".
#
# This script obtains a PARTNER token (client-credentials grant — not a user
# token) and queries the partner public_key endpoint in every region. If a
# region returns your public key, you are registered there.
#
# Usage:
#   export TESLA_CLIENT_ID=...        # from developer.tesla.com
#   export TESLA_CLIENT_SECRET=...
#   ./scripts/check-tesla-regions.sh
#
# Optional:
#   export TESLA_DOMAIN=liuhao.im     # defaults to liuhao.im
#
# Requires: curl, jq

set -euo pipefail

DOMAIN="${TESLA_DOMAIN:-liuhao.im}"
CLIENT_ID="${TESLA_CLIENT_ID:?Set TESLA_CLIENT_ID}"
CLIENT_SECRET="${TESLA_CLIENT_SECRET:?Set TESLA_CLIENT_SECRET}"

# Audience must be a valid regional Fleet API host. NA works for issuing the
# partner token regardless of which regions you query afterward.
AUTH_URL="https://auth.tesla.com/oauth2/v3/token"
AUDIENCE="https://fleet-api.prd.na.vn.cloud.tesla.com"

# scope must include the partner-management scope. openid/offline_access not
# needed for client-credentials.
SCOPE="openid vehicle_device_data"

# Region host lookup. Plain function instead of an associative array so this
# runs on macOS's stock bash 3.2 (no `declare -A`).
region_host() {
  case "$1" in
    NA) echo "fleet-api.prd.na.vn.cloud.tesla.com" ;;
    EU) echo "fleet-api.prd.eu.vn.cloud.tesla.com" ;;
    CN) echo "fleet-api.prd.cn.vn.cloud.tesla.cn" ;;
  esac
}

echo "Domain under test: $DOMAIN"
echo "Requesting partner token (client-credentials)..."

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

echo "Got partner token. Checking each region..."
echo

printf '%-4s  %-12s  %s\n' "REGION" "REGISTERED?" "DETAIL"
printf '%-4s  %-12s  %s\n' "------" "-----------" "------"

for region in NA EU CN; do
  host="$(region_host "$region")"
  url="https://$host/api/1/partner_accounts/public_key?domain=$DOMAIN"

  body="$(curl -sS -w $'\n%{http_code}' \
    -H "Authorization: Bearer $PARTNER_TOKEN" \
    "$url" || echo $'\n000')"

  http_code="$(echo "$body" | tail -n1)"
  payload="$(echo "$body" | sed '$d')"

  case "$http_code" in
    200)
      pubkey="$(echo "$payload" | jq -r '.response.public_key // empty')"
      if [[ -n "$pubkey" ]]; then
        printf '%-4s  %-12s  key=%.16s...\n' "$region" "YES" "$pubkey"
      else
        printf '%-4s  %-12s  200 but no public_key (NOT registered)\n' "$region" "NO"
      fi
      ;;
    404)
      printf '%-4s  %-12s  404 not found (NOT registered)\n' "$region" "NO"
      ;;
    *)
      detail="$(echo "$payload" | jq -rc '.error // .' 2>/dev/null || echo "$payload")"
      printf '%-4s  %-12s  HTTP %s: %s\n' "$region" "?" "$http_code" "$detail"
      ;;
  esac
done

echo
echo "If EU shows NO, that is why your UK users get 421. Register there with:"
echo "  POST https://fleet-api.prd.eu.vn.cloud.tesla.com/api/1/partner_accounts"
echo "  body: {\"domain\": \"$DOMAIN\"}  (with the same partner token)"
