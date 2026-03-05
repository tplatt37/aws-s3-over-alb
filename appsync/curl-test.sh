#!/bin/bash
REALTIME_URL=appsync.dev.example.com
AMZ_DATE=$(date -u +"%Y%m%dT%H%M%SZ")
echo "$AMZ_DATE"

#header=$(echo "{\"host\":\"xxxxxxxxxxxx.appsync-api.us-east-1.amazonaws.com\",\"x-amz-date\":\"$AMZ_DATE\",\"x-api-key\":\"da2-ghtsc3cgwvbaxbs7iovoti5xsa\"}" | base64  | tr -d '\n')
header=$(echo "{\"host\":\"xxxxxxxxxxxx.appsync-api.us-east-1.amazonaws.com\",\"x-api-key\":\"da2-ghtsc3cgwvbaxbs7iovoti5xsa\"}" | base64  | tr -d '\n')
echo $header
echo $header | base64 -d

payload="e30="

HOST=appsync.dev.awstrainer.com
#HOST=vpce-0xxxxxxxx-xxxxxxx.appsync-realtime-api.us-east-1.vpce.amazonaws.com
URL="https://$HOST/graphql?header=$header&payload=$payload"
echo "URL=$URL"
curl -k -i -N \
  --http1.1 \
  $URL
