#!/bin/bash

#KEY_PATH=/home/roye/Desktop/roye-key.pem
# Check if KEY_PATH environment variable is set
if [ -z "$KEY_PATH" ]; then
    echo "KEY_PATH env var is expected"
    exit 5
fi

# Check for required arguments
if [ -z "$KEY_PATH" ]; then
    echo "Please provide bastion IP address"
    exit 5
fi

# Assign input arguments to variables
BASTION_IP="$1"
PRIVATE_IP="$2"
COMMAND="$3"

# Connect to the public instance (bastion) and optionally to the private instance
if [ -z "$PRIVATE_IP" ]; then
    # Case 2: Connect to the public instance only
    ssh -i "$KEY_PATH" ubuntu@"$BASTION_IP"
elif [ -z "$COMMAND" ]; then
    # Case 1: Connect to the private instance through the bastion
    ssh -i "$KEY_PATH" -o "ProxyCommand ssh -W %h:%p -i $KEY_PATH ubuntu@$BASTION_IP" ubuntu@"$PRIVATE_IP"
else
    # Case 3: Run a command in the private machine
    ssh -i "$KEY_PATH" -o "ProxyCommand ssh -W %h:%p -i $KEY_PATH ubuntu@$BASTION_IP" ubuntu@"$PRIVATE_IP" "$COMMAND"
fi
