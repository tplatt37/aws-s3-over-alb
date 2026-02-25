# Clone easy-rsa
git clone https://github.com/OpenVPN/easy-rsa.git
cd easy-rsa/easyrsa3

# Initialize PKI and create CA
./easyrsa init-pki
./easyrsa build-ca nopass

# Use a domain-like CN for the server cert — doesn't need to be real/resolvable
./easyrsa build-server-full vpn.example.com nopass

# Client cert CN also benefits from a domain-like name
./easyrsa build-client-full client.vpn.example.com nopass

# Import SERVER cert to ACM — note the returned ARN
aws acm import-certificate \
  --certificate fileb://pki/issued/vpn.example.com.crt \
  --private-key fileb://pki/private/vpn.example.com.key \
  --certificate-chain fileb://pki/ca.crt \
  --region "us-east-1"

# Import CLIENT cert to ACM — note the returned ARN
aws acm import-certificate \
  --certificate fileb://pki/issued/client.vpn.example.com.crt \
  --private-key fileb://pki/private/client.vpn.example.com.key \
  --certificate-chain fileb://pki/ca.crt \
  --region "us-east-1"
