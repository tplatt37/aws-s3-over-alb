#!/bin/bash

# This is an introspection query - Introspection is on by default in AppSync
# If you get "cloud not locate private api" your NGINX is not configured properly
curl -X POST https://appsync.dev.awstrainer.com/graphql \
  -H "Content-Type: application/json" \
  -H "x-api-key: $1" \
  -d '{
    "query": "{ __schema { queryType { name } types { name kind description } } }"
  }'
