#!/bin/bash
set -e

# Update system
apt-get update
apt-get upgrade -y

# Install essential tools
apt-get install -y curl git unzip wget jq awscli

# Install Terraform
TERRAFORM_VERSION="1.6.6"
wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip
mv terraform /usr/local/bin/
rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Install Node.js (for some GitHub Actions)
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Create runner directory
mkdir -p /home/ubuntu/actions-runner
cd /home/ubuntu/actions-runner

# Download GitHub runner
RUNNER_VERSION="2.311.0"
curl -o actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz
tar xzf ./actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz
rm actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# Set ownership
chown -R ubuntu:ubuntu /home/ubuntu/actions-runner

# Configure runner as ubuntu user
sudo -u ubuntu bash << 'EOF'
cd /home/ubuntu/actions-runner
./config.sh --url ${github_repo} --token ${github_token} --name ${runner_name} --labels linux,x64,aws --unattended
EOF

# Install and start runner service
cd /home/ubuntu/actions-runner
./svc.sh install ubuntu
./svc.sh start

# Verify installation
systemctl status actions.runner.ubuntu.* || true

# Log completion
echo "GitHub runner setup completed at $(date)" >> /var/log/runner-setup.log