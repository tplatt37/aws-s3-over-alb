#!/bin/bash

host=xxxxxxxxxxxxxxxxxxxxxx.appsync-api.us-east-1.amazonaws.com
api_key=da2-xxxxxxxxxxc


header=$(echo "{\"host\":\"$host\",\"x-api-key\":\"$api_key\"}" | base64 | tr -d '\n')
echo $header
echo $header | base64 -d

url=appsync.dev.example.com
wscat -p 13 -s graphql-ws -c  "wss://$url/graphql?header=$header&payload=e30="