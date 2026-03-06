# Making Internet-Facing Web Services Private Only

This is a demonstration of making Internet-Facing Web Services Private Only.

Examples include:
* S3 Bucket 
* Private API Gateway REST API 
* Private AppSync API (Graphql and WebSocket/Real Time)

All are placed behind an Internal (non-Internet-Facing) Application Load Balancer (ALB)

We'll also setup a Client VPN connection, so we can demonstrate accessing these things over a VPN connection (using the internal IPs/DNS Names of the ALBs)

NOTE: We're going to use a Public Hosted Zone in Route 53 for the records.  This is NOT a best practice as it exposes internal IPs via name resolution over the Internet.  I'm doing this because I only maintain one hosted zone in my AWS account - and it is public.  For a real-world use case you would use a Private Hosted Zone in Route 53, which would leave the DNS names of the ALBs resolvable only internally.

The basic idea is shown in this diagram. Please note the ALB(s) are internal - meaning they are NOT Internet facing.  
![VPC with AWS Client VPN access](docs/VPC%20with%20AWS%20Client%20VPN.drawio.png)

NOTE: The above is a simplification of how the ALB actually connects , see the additional diagrams below for further details.

## Pre-Requisites

* Route 53 Hosted Zone (Public)

## AWS Client VPN Setup

First, we'll setup a VPC with public and private subnets, and an AWS Client VPN connection.

Relevant files are in the vpn folder.

1. Using CloudShell, clone this git repo
2. Run the easy-rsa.sh to create VPN Server and Client certificates and import into ACM
```
cd vpn
./easy-rsa.sh
```
2. Create the VPN stack.  Name it "myvpn"
3. Using CloudShell, run the after-stack-config.sh (cd into vpn folder)
```
./after-stack-config.sh
```
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

The ALB will have a Target Group populated with the Interface Endpoints for the S3 service, as shown in this diagram:
![Access to S3 via ALB](docs/S3%20via%20AWS%20Client%20VPN.drawio.png)

Create the stack using the s3-over-alb.yaml file.

How can you test this?   
1. Upload an object into the S3 bucket
2. Create a GET Pre-Signed URL (via "Open" button in the console, for example) and replace the FQDN with your custom bucket name.   
3. Try accessing the modified Pre-Signed URL while connected to VPN, it should work.  When NOT connected to VPN it won't work


NOTE: The Bucket Policy is not currently limiting access via VPCE only. This is for convenience.  It's easy to lock yourself out of the bucket.


# API Gateway Private REST API over ALB

There's also an example for this too.  

It's real similar to the S3 solution and leverages the HostHeader rewrite capability.

Simply create the stack using apigw-over-alb.yaml

... and then curl (while connected to VPN, of course) :
```
curl https://yourcustomdomainname.com/prod/data
```
or
```
curl https://yourcustomdomainname.com/prod/healthcheck
```

Similar to S3, the ALB's Target Groups have the IPs of the ENIs associated with the Interface Endpoints for the API Gateway service:
![API GW over ALB](docs/API%20GW%20via%20AWS%20Client%20VPN.drawio.png)

# AppSync Private API via ALB

As of March 2026, you'll find blog posts that mention Nginx is needed in front of an AppSync Private API.  I do not believe this is necessary.

AppSync supports custom domain names, but DOES NOT support Private APIs with custom domain names.   

We can put an ALB in front of the AppSync Interface Endpoints (just as we have done with the S3 and API Gateway) and use the new-ish Header modification capability to transform the Host header.  This seems to work perfect - No NGINX needed, no "X-AppSync-Domain" header required either. 

This approach is demonstrated with appsync/appsync-via-alb.yaml.  

Please also note there are TWO rules (/graphql for regular requests and /graphql/realtime for WebSocket requests) that modify the Host header appropriately.  This allows us to use one custom domain with both endpoints, just like you can do with Custom Domain Names (public).

The AppSync examples are split up into two stacks.

First, use appsync/appsync-private-lambda-auth.yaml to create the PRIVATE AppSync API.  It's a simple setup using a DynamoDB table, protected with an overly simplistic Lambda Authorizer.

## Setup the AppSync Private API and test it

The AppSync template will create a PRIVATE API.  You'll need an AppSync Interface Endpoint to get to it - which is created by the VPN template.


You can use the EC2 Jumpbox in the VPN stack to test it (You cannot use the console query feature because it is a PRIVATE API):

NOTE: You are NOT attempting to use the custom domain yet.  These are basic tests run WITHIN THE VPC to make sure the AppSync Private API itself is functional.

```
STACK_NAME="appsync-private-api-stack"

# Get the GraphQL endpoint URL
ENDPOINT=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --query "Stacks[0].Outputs[?OutputKey=='GraphQLEndpoint'].OutputValue" \
  --output text)

# Set the token value
TOKEN="SET_SECRET_TOKEN_VALUE_HERE"

echo "Endpoint: $ENDPOINT"
echo "Authorization:  $TOKEN"
```

Create an Item (a Mutation)
```
curl -s -X POST "$ENDPOINT/graphql" \
  -H "Content-Type: application/json" \
  -H "Authorization: $TOKEN" \
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
curl -s -X POST "$ENDPOINT" \
  -H "Content-Type: application/json" \
  -H "Authorization: $TOKEN" \
  -d '{
    "query": "query GetItem($id: ID!) { getItem(id: $id) { id name description createdAt } }",
    "variables": { "id": "item-001" }
  }' | python3 -m json.tool
```

List all Items (Query)
```
curl -s -X POST "$ENDPOINT" \
  -H "Content-Type: application/json" \
  -H "Authorization: $TOKEN" \
  -d '{
    "query": "query { listItems { id name description createdAt } }"
  }' | python3 -m json.tool
```

Update an Item (Mutation)
```
curl -s -X POST "$ENDPOINT" \
  -H "Content-Type: application/json" \
  -H "Authorization: $TOKEN" \
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
curl -s -X POST "$ENDPOINT" \
  -H "Content-Type: application/json" \
  -H "Authorization: $TOKEN" \
  -d '{
    "query": "mutation DeleteItem($id: ID!) { deleteItem(id: $id) { id name } }",
    "variables": { "id": "item-001" }
  }' | python3 -m json.tool
```



## Setup an ALB to make the Private API accessible remotely over VPN


After you have confirmed the AppSync Private API is working...

Create EITHER (or both, I guess) the appsync/appsync-via-alb-nginx.yaml or appsync/appsync-via-alb.yaml stack to create the ALB sitting in front 

Either option works, but obviously, the solution that does NOT require a Target Group of EC2 instances running Nginx would be cheaper and simpler to maintain.

NOTE: [As per the AWS documentation](https://docs.aws.amazon.com/appsync/latest/devguide/real-time-websocket-client.html), to use the Private API for WebSocket/Realtime you will need to pass the Base64 encoded Host and relevent Authentication as "header" and empty JSON {} as "payload" in the querystring.  These are essential for the process.

My experiements conclude that you DO NOT need "X-AppSync-Domain" header.   

See curl-lambda.sh (Invoking Graphql via CURL) and ws-lambda (Invoking WebSocket via wscat) for examples of usage of the header and payload query strings

![AppSync via ALB](docs/AppSync%20Simplest%20Solution-Updated.drawio.png)

## Testing the AppSync Private API via ALB

From ANY machine that has connectivity to the ALB:

set TOKEN and ENDPOINT environment variables.

ENDPOINT should be your custom domain name

To test this one, modify test-appsync-over-alb.sh with your custom domain, then run:
(After setting environment variables used by the script)
```
./curl-lambda.sh
```


You should see valid JSON output.

## Testing Web Socket

Also set HOST to the appsync-api Domain Name.

The realtime endpoint (WebSocket) should work as well.
(After setting values)
```
./ws-lambda.sh
```

## AppSync Private API via ALB and Nginx

As mentioned above, this is not the optimal solution.  But I'm leaving it here to record the Nginx configuration required, in case there is some compelling reason to include Nginx in the architecture in the future.


NOTE: This setup will be different.  The Target Group will be an Auto Scaling Group (ASG) of EC2 instances running Nginx.  

I originally explored this technique with the belief that the X-AppSync-Header header would have to be added to the request. Note that at this time an ALB can MODIFY an existing header, but not add a new one.

Experimentation revealed that all the AppSync service really needs is the Host header, which can be easily modified from your custom domain name to the AWS issued domain name.


The setup looks like:

![AppSync via ALB with NGINX](docs/AppSync%20via%20AWS%20Client%20VPN.drawio.svg)


It doesn't have to be running on EC2s - a Fargate service running under ECS would work great too.

See the details of the LaunchTemplate in the appsync-alb.yaml file to see how NGINX needs to be configured.



