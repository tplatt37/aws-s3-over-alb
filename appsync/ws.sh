#!/bin/bash

# --- Variables ---
API_ID="xxxxxxxxxxx"
REGION="us-east-1"
API_KEY="da2-xxxxxxxxxxxxxxsa"
VPCE_HOST=xxxxxxxxxxx.appsync-realtime-api.us-east-1.amazonaws.com
VPCE_HOST=appsync.dev.example.com

# --- Build header (note: appsync-realtime-api in host!) ---
HEADER_JSON="{\"host\":\"${API_ID}.appsync-api.${REGION}.amazonaws.com\",\"x-api-key\":\"${API_KEY}\"}"

HEADER_B64=$(echo -n "$HEADER_JSON" | base64 -w 0)
echo "$HEADER_B64"

# --- Connect ---
wscat -c "wss://${VPCE_HOST}/graphql?header=${HEADER_B64}&payload=e30=" -s graphql-ws
