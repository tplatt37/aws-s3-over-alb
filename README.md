# S3 Over ALB

A simple test implementation of accessing S3 bucket via an ALB with a custom domain name.

This uses the new Header Rewrite ability of an ALB to replace the Host header with the proper information required by the AWS S3 service.


# API Gateway Private REST API over ALB

There's also an example for this too.  

It's real similar to the S3 solution and leverages the HostHeader rewrite capability

# AWS Client VPN Setup

You can also set the ALB to be Scheme: internal (not internet-facing) and then setup AWS Client VPN. 

Relevant files are in the vpn folder.

You would setup VPN first, then setup one of the other two stacks in that VPC (NOTE: An ALB Must have two subnets)

1. Use the easy-rsa.sh to create certificates and import into ACM
2. create the VPN stack
3. Perform the after-stack-config.sh
4. Create the other stack (S3 or API Gateway) - make sure the ALB is defined as scheme: internal 

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
