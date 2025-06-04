#!/bin/zsh

# Usage: ./aws-lookup.sh <resource-type> <resource-name>

aws-resource-lookup() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: ./aws-lookup.sh <resource-type> <resource-name>"
        return 1
    fi

    if [ "$1" = "ec2" ]; then
        # Lookup EC2 instance by name
        instance_id=$(aws ec2 describe-instances \
            --filters "Name=tag:Name,Values=$2" \
            --query 'Reservations[*].Instances[*].[InstanceId]' \
            --output text)

        if [ -z "$instance_id" ]; then
            echo "No EC2 instances found with name '$2'"
            return 1
        fi

        echo "$instance_id"

    elif [ "$1" = "ecs" ]; then
        # Lookup ECS cluster by name
        cluster_arn=$(aws ecs list-clusters \
            --query 'clusterArns[?contains(@, `'$2'`)]' \
            --output text)

        if [ -z "$cluster_arn" ]; then
            echo "No ECS clusters found with name '$2'"
            return 1
        fi

        echo "Cluster ARN: $cluster_arn"

    elif [ "$1" = "rds" ]; then
        # Lookup RDS instance by name
        rds_instance_id=$(aws rds describe-db-instances \
            --filters "Name=db-instance-id,Values=$2" \
            --query 'DBInstances[*].[DBInstanceIdentifier]' \
            --output text)

        if [ -z "$rds_instance_id" ]; then
            echo "No RDS instances found with name '$2'"
            return 1
        fi

        echo "$rds_instance_id"

    elif [ "$1" = "rds-secret" ]; then
        # Lookup RDS instance secret by name
        rds_instance_id=$(aws rds describe-db-instances \
            --filters "Name=db-instance-id,Values=$2" \
            --query 'DBInstances[*].[DBInstanceIdentifier]' \
            --output text)

        if [ -z "$rds_instance_id" ]; then
            echo "No RDS instances found with name '$2'"
            return 1
        fi

        secret_arn=$(aws rds describe-db-instances \
            --db-instance-identifier "$rds_instance_id" \
            --query 'DBInstances[0].MasterUserSecret.SecretArn' \
            --output text)

        if [ "$secret_arn" = "None" ] || [ -z "$secret_arn" ]; then
            echo "RDS instance '$rds_instance_id' does not use Secrets Manager for its password."
            return 1
        fi

        secret_value=$(aws secretsmanager get-secret-value \
            --secret-id "$secret_arn" \
            --query 'SecretString' \
            --output text)
        echo "$secret_value"

    else
        echo "Unsupported resource type: $1"
        return 1
    fi
}

autoload -Uz aws-resource-lookup
# alias aws-resource-lookup='aws-resource-lookup'
alias alu=aws-resource-lookup
