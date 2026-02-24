# S3 Over ALB

A simple test implementation of accessing S3 bucket via an ALB with a custom domain name.

This uses the new Header Rewrite ability of an ALB to replace the Host header with the proper information required by the AWS S3 service.


# API Gateway Private REST API over ALB

There's also an example for this too.  

It's real similar to the S3 solution and leverages the HostHeader rewrite capability

# Client VPN

You can also set the ALB to be Scheme: internal (not internet-facing) and then setup AWS Client VPN. 

Steps are in the vpn folder.

You would setup VPN first, then setup one of the other two stacks in that VPC (NOTE: An ALB Must have two subnets)

1. Use the easy-rsa.sh to create certificates and import into ACM
2. create the VPN stack
3. Perform the after-stack-config.sh
4. Create the other stack (S3 or API Gateway) - make sure the ALB is defined as scheme: internal 

Note that there will be a PUBLIC DNS record with a PRIVATE 10.* IP for the ALB.  This is convenient for this TECH DEMO.

Connect to VPN and then try to access one of the resources (for example the API Gateway via):

curl https://whateverdomainyouused.com/prod/data 

This should return a JSON output when connected to VPN, and the name will be unresolvable / unreachable if not connected to VPN