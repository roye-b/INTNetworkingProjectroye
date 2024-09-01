#!/bin/bash

# Check if the private instance IP is provided
if [ -z "$1" ]; then
  echo "Usage: ./ssh_keys_rotation.sh <private-instance-ip>"
  exit 1
fi

PRIVATE_INSTANCE_IP="$1"
NEW_KEY_NAME="$HOME/.ssh/id_rsa_new"
NEW_KEY_PATH="$HOME/.ssh/$NEW_KEY_NAME.pub"
OLD_KEY_PATH="$HOME/.ssh/id_rsa"  # Assuming the old key is named id_rsa

# Step 1: Generate a new SSH key pair
ssh-keygen -t rsa -b 4096  -f "$NEW_KEY_PATH" -N ""
chmod 600 $NEW_KEY_PATH
if [ $? -ne 0 ]; then
  echo "Error: Failed to generate new SSH key pair."
  exit 1
fi

# Step 2: Copy the new public key to the private instance
NEW_PUBLIC_KEY=$(cat "$NEW_KEY_PATH.pub")
ssh -i "$OLD_KEY_PATH" ubuntu@"$PRIVATE_INSTANCE_IP" "echo '$NEW_PUBLIC_KEY' >> ~/.ssh/authorized_keys"
if [ $? -ne 0 ]; then
  echo "Error: Failed to copy new public key to the private instance."
  exit 1
fi

# Step 3: Remove the old SSH key from the private instance's authorized_keys file
OLD_PUBLIC_KEY=$(cat "$OLD_KEY_PATH.pub")
ssh -i "$OLD_KEY_PATH" ubuntu@"$PRIVATE_INSTANCE_IP" "sed -i '/$OLD_PUBLIC_KEY/d' ~/.ssh/authorized_keys"
if [ $? -ne 0 ]; then
  echo "Error: Failed to remove the old SSH key from the authorized_keys file."
  exit 1
fi

# Step 4: Test the connection to the private instance using the new SSH key
ssh -i "$NEW_KEY_PATH" ubuntu@"$PRIVATE_INSTANCE_IP" "echo 'SSH key rotation successful.'"
if [ $? -ne 0 ]; then
  echo "Error: Failed to connect to the private instance using the new SSH key."
  exit 1
fi

echo "SSH key rotation completed successfully."
