#!/bin/bash

curl -X POST https://appsync.dev.awstrainer.com/graphql \
  -H "Content-Type: application/json" \
  -H "x-api-key: $1" \
  -d '{
    "query": "{ __schema { queryType { name } types { name kind description } } }"
  }'
