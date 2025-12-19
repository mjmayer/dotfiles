#!/usr/bin/env bash
# wso2_check_token.sh
# Purpose: get OAuth2 client_credentials token from WSO2 and run a test API request.
# Usage:
#   WSO2_TOKEN_URL="https://wso2.example.edu/oauth2/token" \
#   WSO2_API_URL="https://wso2.example.edu/ait-prd/1" \
#   ./wso2_check_token.sh
#
# Or interactively:
#   ./wso2_check_token.sh

set -euo pipefail

# ---------- CONFIG (override via env) ----------
: "${WSO2_TOKEN_URL:=https://wso2.example.com/oauth2/token}"
: "${WSO2_API_URL:=https://wso2.example.com/ait-prd/1}"
# The API payload to POST (change to GET or adjust as needed)
: "${WSO2_API_PAYLOAD:='{"query": "query { erpEntityAll { name }}"}'}"
# Content-Type for the API call
: "${WSO2_API_CONTENT_TYPE:=application/json}"
# Curl common options (insecure -k included because your example used it; remove -k for prod with trusted certs)
CURL_OPTS="-sS -k"

# ---------- HELPER: show usage ----------
usage() {
  cat <<EOF
Usage:
  Provide consumer key & secret via environment:
    export CONSUMER_KEY="your_key"
    export CONSUMER_SECRET="your_secret"
    ./wso2_check_token.sh

  Or run and enter interactively:
    ./wso2_check_token.sh

Environment overrides:
  WSO2_TOKEN_URL       token endpoint (default: $WSO2_TOKEN_URL)
  WSO2_API_URL         API endpoint to call (default: $WSO2_API_URL)
  WSO2_API_PAYLOAD     JSON payload to send to API (default: GraphQL example)
  WSO2_API_CONTENT_TYPE HTTP Content-Type header for API request

Note: jq is required to parse JSON responses.
EOF
}

# ---------- PARSE ARGS ----------
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

# ---------- GET CREDENTIALS ----------
# Allow env vars first, otherwise prompt (secret input hidden)
if [[ -z "${CONSUMER_KEY:-}" ]]; then
  read -r -p "Consumer Key: " CONSUMER_KEY
fi

if [[ -z "${CONSUMER_SECRET:-}" ]]; then
  # -s hides input
  read -s -r -p "Consumer Secret: " CONSUMER_SECRET
  echo
fi

# Basic validation
if [[ -z "$CONSUMER_KEY" || -z "$CONSUMER_SECRET" ]]; then
  echo "Error: consumer key and secret are required." >&2
  exit 2
fi

# ---------- BUILD BASIC AUTH HEADER (portable) ----------
# Use printf to avoid adding a newline; pipe through base64 and strip newlines
B64=$(printf '%s:%s' "$CONSUMER_KEY" "$CONSUMER_SECRET" | base64 | tr -d '\n')

# ---------- REQUEST TOKEN ----------
echo "Requesting token from $WSO2_TOKEN_URL ..."
TOKEN_JSON=$(curl $CURL_OPTS -X POST "$WSO2_TOKEN_URL" \
  -d "grant_type=client_credentials" \
  -H "Authorization: Basic ${B64}" \
  -H "Content-Type: application/x-www-form-urlencoded")

# require jq
if ! command -v jq >/dev/null 2>&1; then
  echo "jq required" >&2; exit 1
fi

# extract raw token (no surrounding quotes)
ACCESS_TOKEN=$(printf '%s' "$TOKEN_JSON" | jq -r '.access_token // empty')

if [[ -z "$ACCESS_TOKEN" ]]; then
  echo "Failed to obtain access_token. Token endpoint returned:"
  printf '%s\n' "$TOKEN_JSON" >&2
  exit 4
fi

# Debug check (optional)
printf 'DEBUG: token length=%d\n' "${#ACCESS_TOKEN}"
printf 'DEBUG: token sample=<%.8s...>\n' "$ACCESS_TOKEN"

# Build payload safely with jq
WSO2_API_PAYLOAD=$(jq -n --arg q 'query { erpEntityAll { name }}' '{query: ("query " + $q)}')

# Now call API using --data-raw and the safely built payload variable
API_RESPONSE=$(curl -sS -k -X POST "$WSO2_API_URL" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  --data-raw "$WSO2_API_PAYLOAD")

# Print pretty JSON if possible, otherwise raw
if printf '%s' "$API_RESPONSE" | jq . >/dev/null 2>&1; then
  printf '%s\n' "$API_RESPONSE" | jq .
else
  echo "$API_RESPONSE"
fi

# Exit success
exit 0
