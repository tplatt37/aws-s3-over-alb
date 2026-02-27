# Making Internet-Facing Web Services Private Only

This is a demonstration of making Internet-Facing Web Services Private Only.

Examples include:
* S3 Bucket 
* Private API Gateway REST API 
* Private AppSync API

All are placed behind an Internal (non-Internet-Facing) Application Load Balancer (ALB)

We'll also setup a Client VPN connection, so we can demonstrate accessing these things over a VPN connection (using the internal IPs/DNS Names of the ALBs)

NOTE: We're going to use a Public Hosted Zone in Route 53 for the records.  This is NOT a best practice as it exposes internal IPs via name resolution over the Internet.  I'm doing this because I only maintain one hosted zone in my AWS account - and it is public.  For a real-world use case you would use a Private Hosted Zone in Route 53, which would leave the DNS names of the ALBs resolvable only internally.

The basic idea is shown in this diagram. Please note the ALB(s) are internal - meaning they are NOT Internet facing.  
![VPC with AWS Client VPN access](docs/VPC%20with%20AWS%20Client%20VPN.drawio.png)

## AWS Client VPN Setup

First, we'll setup a VPC with public and private subnets, and an AWS Client VPN connection.

Relevant files are in the vpn folder.

1. Using CloudShell, run the easy-rsa.sh to create VPN Server and Client certificates and import into ACM
2. Create the VPN stack.  Name it "myvpn"
3. Using CloudShell, run the after-stack-config.sh
4. Download or otherwise copy the client-config.ovpn file and add a Profile in the AWS VPN Client
4. Create the other stack(s) (S3, API Gateway, AppSync, AppSync ALB )

Note that there will be a PUBLIC DNS record with a PRIVATE 10.* IP for the ALB.  This is convenient for this TECH DEMO, not a best practice for production.

Connect to VPN and then try to access one of the resources (for example the API Gateway via):

curl https://whateverdomainyouused.com/prod/data 

This should return a JSON output when connected to VPN, and the name will be unresolvable / unreachable if not connected to VPN

NOTE: Health checks seem to fail with a 403.  Probably because the Host Header isn't what is expected.  This will cause both Target Group entries to be Unhealthy , but the ALB will "Fail Open" such that one of the endpoints will be available.  You can simply redefine success to be a 403 and then they will be healthy.  Because the Target Group is interface endpoints, we don't really want to use the Health Checks.

## VPN Cleanup

1. Delete the ALB stack(s)
2. Delete the VPN stack
3. Manually delete the ACM certs that were imported during VPN setup.
4. OPTIONAL: Delete the certificate files created for VPN 


# S3 Over ALB

A simple test implementation of accessing S3 bucket via an ALB with a custom domain name.

This uses the new Header Rewrite ability of an ALB to replace the Host header with the proper information required by the AWS S3 service.


# API Gateway Private REST API over ALB

There's also an example for this too.  

It's real similar to the S3 solution and leverages the HostHeader rewrite capability


# AppSync Private API

The AppSync template will create a PRIVATE API.  You'll need an AppSync Interface Endpoint to get to it - which is created by the VPN template.

You can use the EC2 Jumpbox in the VPN stack to test it (You cannot use the console query feature because it is a PRIVATE API):

NOTE: The EC2 Jumpbox doesn't have access to CloudFormation service, you'll have to run this elsewhere and manually set the environment variables.
```
STACK_NAME="appsync-private-api-stack"

# Get the GraphQL endpoint URL
GRAPHQL_ENDPOINT=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --query "Stacks[0].Outputs[?OutputKey=='GraphQLEndpoint'].OutputValue" \
  --output text)

# Get the API key
API_KEY=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --query "Stacks[0].Outputs[?OutputKey=='APIKey'].OutputValue" \
  --output text)

echo "Endpoint: $GRAPHQL_ENDPOINT"
echo "API Key:  $API_KEY"
```

Create an Item (a Mutation)
```
curl -s -X POST "$GRAPHQL_ENDPOINT" \
  -H "Content-Type: application/json" \
  -H "x-api-key: $API_KEY" \
  -d '{
    "query": "mutation CreateItem($input: CreateItemInput!) { createItem(input: $input) { id name description createdAt } }",
    "variables": {
      "input": {
        "id": "item-001",
        "name": "Test Item",
        "description": "This is a test item from the jumpbox"
      }
    }
  }' | python3 -m json.tool
```

Get an Item (Query)
```
curl -s -X POST "$GRAPHQL_ENDPOINT" \
  -H "Content-Type: application/json" \
  -H "x-api-key: $API_KEY" \
  -d '{
    "query": "query GetItem($id: ID!) { getItem(id: $id) { id name description createdAt } }",
    "variables": { "id": "item-001" }
  }' | python3 -m json.tool
```

List all Items (Query)
```
curl -s -X POST "$GRAPHQL_ENDPOINT" \
  -H "Content-Type: application/json" \
  -H "x-api-key: $API_KEY" \
  -d '{
    "query": "query { listItems { id name description createdAt } }"
  }' | python3 -m json.tool
```

Update an Item (Mutation)
```
curl -s -X POST "$GRAPHQL_ENDPOINT" \
  -H "Content-Type: application/json" \
  -H "x-api-key: $API_KEY" \
  -d '{
    "query": "mutation UpdateItem($input: UpdateItemInput!) { updateItem(input: $input) { id name description } }",
    "variables": {
      "input": {
        "id": "item-001",
        "name": "Updated Item Name",
        "description": "Updated description"
      }
    }
  }' | python3 -m json.tool
```

Delete an Item (Mutation)
```
curl -s -X POST "$GRAPHQL_ENDPOINT" \
  -H "Content-Type: application/json" \
  -H "x-api-key: $API_KEY" \
  -d '{
    "query": "mutation DeleteItem($id: ID!) { deleteItem(id: $id) { id name } }",
    "variables": { "id": "item-001" }
  }' | python3 -m json.tool
```



