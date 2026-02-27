#!/bin/bash

# After the VPN stack is setup, run this to generate the .ovpn VPN Client configuration file

#
# NOTE: Some of these require customization!
#
#

ENDPOINTID=$(aws cloudformation describe-stacks \
  --stack-name myvpn \
  --query "Stacks[0].Outputs[?OutputKey=='ClientVpnEndpointId'].OutputValue" \
  --output text)
echo "ENDPOINTID=$ENDPOINTID"

aws ec2 export-client-vpn-client-configuration \
  --client-vpn-endpoint-id $ENDPOINTID \
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