#!/bin/bash

# Variables
AWS_REGION="us-west-2" # Set your AWS region
COMMAND="sudo yum upgrade -y" # Command to run on the instances
INSTANCE_FILTER="tag:component=nifi" # Example filter to select instances

# Fetch the list of instance IDs that are managed by SSM
echo "Fetching list of managed EC2 instances..."
INSTANCE_IDS=$(aws ssm describe-instance-information \
    --region "$AWS_REGION" \
    --query "InstanceInformationList[].InstanceId" \
    --output text)

if [ -z "$INSTANCE_IDS" ]; then
    echo "No managed instances found."
    exit 0
fi

# Print list of instance ids before converting for debugging
echo "Instances IDs before formatting: $INSTANCE_IDS"

# Convert space-separated instance IDs to comma-separated
INSTANCE_IDS_CSV=$(echo "$INSTANCE_IDS" | tr '\n\r' ',' |tr '[:blank:]' ',' | sed 's/,$//')

# Print the list of instances
echo "Managed EC2 instances: $INSTANCE_IDS_CSV"

# Run the command on all instances
echo "Executing command: $COMMAND"
COMMAND_ID=$(aws ssm send-command \
    --region "$AWS_REGION" \
    --document-name "AWS-RunShellScript" \
    --targets "Key=InstanceIds,Values=$INSTANCE_IDS_CSV" \
    --comment "Running yum upgrade on all instances" \
    --parameters commands=["$COMMAND"] \
    --query "Command.CommandId" \
    --output text)

if [ -z "$COMMAND_ID" ]; then
    echo "Failed to send command."
    exit 1
fi

echo "Command sent successfully. Command ID: $COMMAND_ID"

# Wait for the command to complete
echo "Waiting for the command to finish..."
aws ssm list-command-invocations \
    --region "$AWS_REGION" \
    --command-id "$COMMAND_ID" \
    --details \
    --output table

echo "Command completed. Check SSM Run Command console for detailed results."

