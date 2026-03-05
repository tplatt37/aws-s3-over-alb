#!/bin/bash

# Run this on VPC connected EC2 to test using wscat
# pre-reqs:
# sudo dnf install nodejs
# sudo npm -g install wscat

# Must set these with export XXX=XXX
echo "ENDPOINT=$ENDPOINT"
echo "HOST=$HOST"
echo "TOKEN=$TOKEN"

# --- Build header (note: appsync-realtime-api in host!) ---
# https://docs.aws.amazon.com/appsync/latest/devguide/real-time-websocket-client.html
HEADER_JSON="{\"host\":\"${HOST}\",\"Authorization\":\"${TOKEN}\"}"
echo "HEADER_JSON=$HEADER_JSON"
HEADER_B64=$(echo -n "$HEADER_JSON" | base64 -w 0)
echo "HEADER_B64=$HEADER_B64"

# --- Connect ---
URL="wss://${ENDPOINT}/graphql?header=${HEADER_B64}&payload=e30="
echo $URL
wscat -n -c $URL -s graphql-ws

