#!/bin/bash

echo "ENDPOINT=$ENDPOINT"
echo "TOKEN=$TOKEN"

# This is an introspection query - Introspection is on by default in AppSync
# If you get "could not locate private api" your NGINX is not configured properly
curl -X POST https://$ENDPOINT/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: $TOKEN" \
  -d '{
    "query": "{ __schema { queryType { name } types { name kind description } } }"
  }'
