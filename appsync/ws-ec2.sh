!/bin/bash

# NOTE: I have this working on 3/3
# When running on the EC2 instance (Nginx proxy)
# NOTE: If you uncomment the localhost if fails with 400.
# It's something with the nginx

# --- Variables ---
API_ID="xxxxxx"
REGION="us-east-1"
API_KEY="da2-xxxxxxxxxxxxxx"
VPCE_HOST=vpce-xxxxxxxxx-xxxxxx.appsync-api.us-east-1.vpce.amazonaws.com
VPCE_HOST=xxxxxxxxx.appsync-realtime-api.us-east-1.amazonaws.com
#VPCE_HOST="appsync.dev.example.com"
#VPCE_HOST=localhost

# --- Build header (note: appsync-realtime-api in host!) ---
HEADER_JSON="{\"host\":\"${API_ID}.appsync-api.${REGION}.amazonaws.com\",\"x-api-key\":\"${API_KEY}\"}"

HEADER_B64=$(echo -n "$HEADER_JSON" | base64 -w 0)


# --- Connect ---
wscat -n -c "wss://${VPCE_HOST}/graphql?header=${HEADER_B64}&payload=e30=" -s graphql-ws

