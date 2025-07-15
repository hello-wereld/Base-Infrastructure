#!/bin/bash

# Bootstrap script for Terraform S3 backend setup
# This script creates the S3 bucket and DynamoDB table for Terraform state management

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
PROJECT_NAME="my-app"
ENVIRONMENT="dev"
AWS_REGION="us-west-2"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -p|--project)
      PROJECT_NAME="$2"
      shift 2
      ;;
    -e|--environment)
      ENVIRONMENT="$2"
      shift 2
      ;;
    -r|--region)
      AWS_REGION="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo "Options:"
      echo "  -p, --project     Project name (default: my-app)"
      echo "  -e, --environment Environment (default: dev)"
      echo "  -r, --region      AWS region (default: us-west-2)"
      echo "  -h, --help        Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option $1"
      exit 1
      ;;
  esac
done

echo -e "${GREEN}Starting Terraform backend bootstrap...${NC}"
echo "Project: $PROJECT_NAME"
echo "Environment: $ENVIRONMENT"
echo "Region: $AWS_REGION"
echo

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}Error: AWS CLI is not configured or credentials are invalid${NC}"
    echo "Please run 'aws configure' first"
    exit 1
fi

# Check if bucket already exists for this project/environment
BUCKET_PREFIX="terraform-state-${PROJECT_NAME}-${ENVIRONMENT}-"
TABLE_NAME="terraform-state-lock-${PROJECT_NAME}"

echo -e "${YELLOW}Checking for existing S3 bucket with prefix: $BUCKET_PREFIX${NC}"

# Look for existing bucket (get first match only)
EXISTING_BUCKET=$(aws s3api list-buckets --query "Buckets[?starts_with(Name, \`$BUCKET_PREFIX\`)].Name | [0]" --output text --region "$AWS_REGION" 2>/dev/null || echo "")

if [ -n "$EXISTING_BUCKET" ]; then
    BUCKET_NAME="$EXISTING_BUCKET"
    echo -e "${YELLOW}Found existing S3 bucket: $BUCKET_NAME${NC}"
else
    # Generate random suffix for new bucket name
    RANDOM_SUFFIX=$(openssl rand -hex 4)
    BUCKET_NAME="terraform-state-${PROJECT_NAME}-${ENVIRONMENT}-${RANDOM_SUFFIX}"
    
    echo -e "${YELLOW}Creating new S3 bucket: $BUCKET_NAME${NC}"
    
    # Create S3 bucket (handle us-east-1 special case)
    if [ "$AWS_REGION" = "us-east-1" ]; then
        aws s3api create-bucket \
            --bucket "$BUCKET_NAME" \
            --region "$AWS_REGION" \
            --no-cli-pager
    else
        aws s3api create-bucket \
            --bucket "$BUCKET_NAME" \
            --region "$AWS_REGION" \
            --create-bucket-configuration LocationConstraint="$AWS_REGION" \
            --no-cli-pager
    fi
    echo -e "${GREEN}S3 bucket created successfully${NC}"
fi

# Enable versioning
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled \
    --no-cli-pager

# Enable encryption
aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }' \
    --no-cli-pager

# Block public access
aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration \
        BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true \
    --no-cli-pager

echo -e "${GREEN}S3 bucket created successfully${NC}"

echo -e "${YELLOW}Creating DynamoDB table: $TABLE_NAME${NC}"

# Check if DynamoDB table already exists
if aws dynamodb describe-table --table-name "$TABLE_NAME" --region "$AWS_REGION" &> /dev/null; then
    echo -e "${YELLOW}DynamoDB table $TABLE_NAME already exists, skipping creation${NC}"
else
    # Create DynamoDB table
    aws dynamodb create-table \
        --table-name "$TABLE_NAME" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "$AWS_REGION" \
        --no-cli-pager

    # Wait for table to be active
    echo "Waiting for DynamoDB table to be active..."
    aws dynamodb wait table-exists --table-name "$TABLE_NAME" --region "$AWS_REGION"
    
    echo -e "${GREEN}DynamoDB table created successfully${NC}"
fi

# Create backend configuration file
cat > backend-config.hcl << EOF
bucket         = "$BUCKET_NAME"
key            = "terraform.tfstate"
region         = "$AWS_REGION"
dynamodb_table = "$TABLE_NAME"
encrypt        = true
EOF

echo -e "${GREEN}Backend configuration saved to backend-config.hcl${NC}"

echo
echo -e "${GREEN}Bootstrap completed successfully!${NC}"
echo
echo "Next steps:"
echo "1. Update your terraform.tfvars with your project settings"
echo "2. Initialize Terraform with the backend:"
echo "   terraform init -backend-config=backend-config.hcl"
echo "3. Plan and apply your infrastructure:"
echo "   terraform plan"
echo "   terraform apply"
echo
echo "Backend details:"
echo "  S3 Bucket: $BUCKET_NAME"
echo "  DynamoDB Table: $TABLE_NAME"
echo "  Region: $AWS_REGION"