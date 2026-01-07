#!/bin/bash
set -e

KEY_NAME="mint-eks-key"
REGION="us-east-1"
KEY_FILE="${KEY_NAME}.pem"

# Create the key pair and save the private key locally
aws ec2 create-key-pair --key-name "$KEY_NAME" --region "$REGION" --query 'KeyMaterial' --output text > "$KEY_FILE"

# Set permissions for the private key file
chmod 400 "$KEY_FILE"

echo "Key pair '$KEY_NAME' created in region '$REGION'. Private key saved to '$KEY_FILE'."
echo "You must keep this file secure. Do not share it or commit it to source control."

