#!/bin/bash

# Run this on VPC connected EC2 to test using wscat
# Or run remotely when connectivity to the ALB DNS name is available.
# pre-reqs:
# sudo dnf install nodejs
# sudo npm -g install wscat

# Must set these with export XXX=XXX
# This is where the request is going
echo "ENDPOINT=$ENDPOINT"
# this is used to identify the AppSync API, this is NOT where the request is being sent.
echo "HOST=$HOST"
echo "TOKEN=$TOKEN"

# --- Build header (note: appsync-realtime-api in host!) ---
# https://docs.aws.amazon.com/appsync/latest/devguide/real-time-websocket-client.html
HEADER_JSON="{\"host\":\"${HOST}\",\"Authorization\":\"${TOKEN}\"}"
echo "HEADER_JSON=$HEADER_JSON"
HEADER_B64=$(echo -n "$HEADER_JSON" | base64 -w 0)
echo "HEADER_B64=$HEADER_B64"

# e30= is {} base64 encoded.  This empty JSON payload is required

# --- Connect ---
URL="wss://${ENDPOINT}/graphql/realtime?header=${HEADER_B64}&payload=e30="
echo $URL
wscat -n -c $URL -s graphql-ws

