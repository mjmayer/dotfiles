#!/bin/bash

# Variables
AWS_REGION="us-west-2" # Set your AWS region

# Run the command on all instances
TASK_ID=$(aws ssm start-automation-execution \
    --region "$AWS_REGION" \
    --document-name "AWS-RestartEC2Instance" \
    --targets "Key=InstanceIds,Values=*" \
    --target-parameter-name InstanceId \
    --max-concurrency "1" \
    --max-errors "1" \
    --output text)

if [ -z "$TASK_ID" ]; then
    echo "Failed to send command."
    exit 1
fi

echo "Automation Task Submitted successfully. Task ID: $TASK_ID"

echo "Command completed. Check SSM Task Automation console for detailed results."

