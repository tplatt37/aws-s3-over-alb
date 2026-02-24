#!/bin/bash


#
# NOTE: Some of these require customization!
#
#

aws cloudformation describe-stacks \
  --stack-name YOUR_STACK_NAME \
  --query "Stacks[0].Outputs[?OutputKey=='ClientVpnEndpointId'].OutputValue" \
  --output text


aws ec2 export-client-vpn-client-configuration \
  --client-vpn-endpoint-id cvpn-endpoint-XXXXXXXXXXXXXXXXX \
  --output text > client-config.ovpn


# Append the client certificate
echo "<cert>" >> client-config.ovpn
cat ~/easy-rsa/easyrsa3/pki/issued/client.vpn.example.com.crt >> client-config.ovpn
echo "</cert>" >> client-config.ovpn

# Append the client private key
echo "<key>" >> client-config.ovpn
cat ~/easy-rsa/easyrsa3/pki/private/client.vpn.example.com.key >> client-config.ovpn
echo "</key>" >> client-config.ovpn


# Then copy or download client-config.ovpn and import that as a Profile in AWS OpenVPN client

# then you should be able to connect.