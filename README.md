# S3 Over ALB

A simple test implementation of accessing S3 bucket via an ALB with a custom domain name.

This uses the new Header Rewrite ability of an ALB to replace the Host header with the proper information required by the AWS S3 service.


# API Gateway Private REST API over ALB

There's also an example for this too.  

It's real similar to the S3 solution and leverages the HostHeader rewrite capability
