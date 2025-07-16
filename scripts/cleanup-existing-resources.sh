#!/bin/bash

# Script to clean up existing AWS resources that conflict with Terraform
# This script will delete existing resources so Terraform can create them fresh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
PROJECT_NAME=""
AWS_REGION=""
AUTO_CONFIRM=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -p|--project)
      PROJECT_NAME="$2"
      shift 2
      ;;
    -r|--region)
      AWS_REGION="$2"
      shift 2
      ;;
    --auto-confirm)
      AUTO_CONFIRM=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo "Options:"
      echo "  -p, --project     Project name (required)"
      echo "  -r, --region      AWS region (required)"
      echo "  --auto-confirm    Skip confirmation prompt"
      echo "  -h, --help        Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option $1"
      exit 1
      ;;
  esac
done

if [ -z "$PROJECT_NAME" ] || [ -z "$AWS_REGION" ]; then
    echo -e "${RED}Error: Project name and region are required${NC}"
    echo "Usage: $0 --project PROJECT_NAME --region AWS_REGION"
    exit 1
fi

echo -e "${YELLOW}WARNING: This script will delete existing AWS resources!${NC}"
echo "Project: $PROJECT_NAME"
echo "Region: $AWS_REGION"
echo
echo "Resources that will be deleted:"
echo "- IAM Role: ${PROJECT_NAME}-ecs-task-execution-role"
echo "- ECR Repository: ${PROJECT_NAME}-app"
echo "- Target Group: ${PROJECT_NAME}-tg"
echo

if [ "$AUTO_CONFIRM" = false ]; then
    read -p "Are you sure you want to continue? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "Operation cancelled."
        exit 0
    fi
else
    echo "Auto-confirm enabled, proceeding with cleanup..."
fi

echo -e "${GREEN}Starting cleanup...${NC}"

# Delete IAM Role (detach policies first)
echo -e "${YELLOW}Cleaning up IAM Role...${NC}"
ROLE_NAME="${PROJECT_NAME}-ecs-task-execution-role"

# Detach managed policies
aws iam list-attached-role-policies --role-name "$ROLE_NAME" --region "$AWS_REGION" --query 'AttachedPolicies[].PolicyArn' --output text 2>/dev/null | while read -r policy_arn; do
    if [ -n "$policy_arn" ]; then
        echo "Detaching policy: $policy_arn"
        aws iam detach-role-policy --role-name "$ROLE_NAME" --policy-arn "$policy_arn" --region "$AWS_REGION" 2>/dev/null || true
    fi
done

# Delete inline policies
aws iam list-role-policies --role-name "$ROLE_NAME" --region "$AWS_REGION" --query 'PolicyNames' --output text 2>/dev/null | while read -r policy_name; do
    if [ -n "$policy_name" ]; then
        echo "Deleting inline policy: $policy_name"
        aws iam delete-role-policy --role-name "$ROLE_NAME" --policy-name "$policy_name" --region "$AWS_REGION" 2>/dev/null || true
    fi
done

# Delete the role
aws iam delete-role --role-name "$ROLE_NAME" --region "$AWS_REGION" 2>/dev/null && echo "IAM Role deleted" || echo "IAM Role not found or already deleted"

# Delete ECR Repository
echo -e "${YELLOW}Cleaning up ECR Repository...${NC}"
REPO_NAME="${PROJECT_NAME}-app"
aws ecr delete-repository --repository-name "$REPO_NAME" --region "$AWS_REGION" --force 2>/dev/null && echo "ECR Repository deleted" || echo "ECR Repository not found or already deleted"

# Delete Target Group
echo -e "${YELLOW}Cleaning up Target Group...${NC}"
TG_NAME="${PROJECT_NAME}-tg"

# Get target group ARN
TG_ARN=$(aws elbv2 describe-target-groups --names "$TG_NAME" --region "$AWS_REGION" --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || echo "")

if [ -n "$TG_ARN" ] && [ "$TG_ARN" != "None" ]; then
    aws elbv2 delete-target-group --target-group-arn "$TG_ARN" --region "$AWS_REGION" 2>/dev/null && echo "Target Group deleted" || echo "Failed to delete Target Group"
else
    echo "Target Group not found or already deleted"
fi

echo -e "${GREEN}Cleanup completed!${NC}"
echo
echo "You can now run 'terraform apply' to create fresh resources."