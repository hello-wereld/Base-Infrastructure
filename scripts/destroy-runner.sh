#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning "This will destroy the GitHub runner infrastructure!"
print_warning "Make sure no workflows are currently running."

# Ask for confirmation
echo
read -p "Are you sure you want to destroy the runner? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_status "Destruction cancelled."
    exit 0
fi

# Change to runner infrastructure directory
cd runner-infrastructure

# Destroy infrastructure
print_status "Destroying GitHub runner infrastructure..."
terraform destroy -auto-approve

print_status "Infrastructure destroyed successfully!"
print_warning "Don't forget to remove the runner from GitHub if it's still listed."