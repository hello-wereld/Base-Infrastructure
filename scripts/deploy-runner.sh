#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
PROJECT_NAME="github-runner"
AWS_REGION="us-east-1"
INSTANCE_TYPE="t2.micro"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --project-name NAME    Project name (default: github-runner)"
    echo "  --region REGION        AWS region (default: us-east-1)"
    echo "  --instance-type TYPE   EC2 instance type (default: t2.micro)"
    echo "  --github-repo URL      GitHub repository URL"
    echo "  --github-token TOKEN   GitHub runner token"
    echo "  --public-key-file FILE Path to public key file"
    echo "  --help                 Show this help message"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --project-name)
            PROJECT_NAME="$2"
            shift 2
            ;;
        --region)
            AWS_REGION="$2"
            shift 2
            ;;
        --instance-type)
            INSTANCE_TYPE="$2"
            shift 2
            ;;
        --github-repo)
            GITHUB_REPO="$2"
            shift 2
            ;;
        --github-token)
            GITHUB_TOKEN="$2"
            shift 2
            ;;
        --public-key-file)
            PUBLIC_KEY_FILE="$2"
            shift 2
            ;;
        --help)
            usage
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate required parameters
if [[ -z "$GITHUB_REPO" ]]; then
    print_error "GitHub repository URL is required (--github-repo)"
    exit 1
fi

if [[ -z "$GITHUB_TOKEN" ]]; then
    print_error "GitHub token is required (--github-token)"
    exit 1
fi

if [[ -z "$PUBLIC_KEY_FILE" ]]; then
    print_error "Public key file is required (--public-key-file)"
    exit 1
fi

if [[ ! -f "$PUBLIC_KEY_FILE" ]]; then
    print_error "Public key file not found: $PUBLIC_KEY_FILE"
    exit 1
fi

# Read public key
PUBLIC_KEY=$(cat "$PUBLIC_KEY_FILE")

print_status "Deploying GitHub runner infrastructure..."
print_status "Project: $PROJECT_NAME"
print_status "Region: $AWS_REGION"
print_status "Instance Type: $INSTANCE_TYPE"
print_status "GitHub Repo: $GITHUB_REPO"

# Change to runner infrastructure directory
cd runner-infrastructure

# Initialize Terraform
print_status "Initializing Terraform..."
terraform init

# Plan deployment
print_status "Planning deployment..."
terraform plan \
    -var="project_name=$PROJECT_NAME" \
    -var="aws_region=$AWS_REGION" \
    -var="instance_type=$INSTANCE_TYPE" \
    -var="github_repo=$GITHUB_REPO" \
    -var="github_token=$GITHUB_TOKEN" \
    -var="public_key=$PUBLIC_KEY"

# Ask for confirmation
echo
read -p "Do you want to proceed with the deployment? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Deployment cancelled."
    exit 0
fi

# Apply deployment
print_status "Deploying infrastructure..."
terraform apply -auto-approve \
    -var="project_name=$PROJECT_NAME" \
    -var="aws_region=$AWS_REGION" \
    -var="instance_type=$INSTANCE_TYPE" \
    -var="github_repo=$GITHUB_REPO" \
    -var="github_token=$GITHUB_TOKEN" \
    -var="public_key=$PUBLIC_KEY"

# Show outputs
print_status "Deployment completed!"
echo
print_status "Runner details:"
terraform output

print_status "The runner will be available in GitHub in 2-3 minutes."
print_warning "Remember to destroy the infrastructure when done: ./scripts/destroy-runner.sh"