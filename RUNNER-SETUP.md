# GitHub Self-Hosted Runner Quick Setup

This template allows you to quickly deploy a GitHub Actions self-hosted runner on AWS EC2.

## Prerequisites

1. **AWS CLI configured** with appropriate permissions
2. **Terraform installed**
3. **SSH key pair** for EC2 access

## Quick Start

### 1. Generate SSH Key (if you don't have one)

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/github-runner-key
```

### 2. Get GitHub Token

1. Go to your repo → Settings → Actions → Runners
2. Click "New self-hosted runner"
3. Select Linux x64
4. Copy the token from the config command

### 3. Deploy Runner

```bash
# Make script executable
chmod +x scripts/deploy-runner.sh

# Deploy with your details
./scripts/deploy-runner.sh \
  --project-name "my-project" \
  --region "us-east-1" \
  --github-repo "https://github.com/USERNAME/REPO" \
  --github-token "YOUR_GITHUB_TOKEN" \
  --public-key-file ~/.ssh/github-runner-key.pub
```

### 4. Wait 2-3 Minutes

The runner will automatically:
- Install all required tools (terraform, aws-cli, git, etc.)
- Configure itself with GitHub
- Start running as a service

### 5. Verify Runner

Check your repo → Settings → Actions → Runners. You should see your runner online.

### 6. Update Your Workflows

Your workflows should already be configured with:
```yaml
runs-on: [self-hosted, linux, x64]
```

### 7. Destroy When Done

```bash
chmod +x scripts/destroy-runner.sh
./scripts/destroy-runner.sh
```

## Advanced Usage

### Custom Instance Type

```bash
./scripts/deploy-runner.sh \
  --instance-type "t3.small" \
  --github-repo "https://github.com/USERNAME/REPO" \
  --github-token "YOUR_TOKEN" \
  --public-key-file ~/.ssh/github-runner-key.pub
```

### Different Region

```bash
./scripts/deploy-runner.sh \
  --region "eu-west-1" \
  --github-repo "https://github.com/USERNAME/REPO" \
  --github-token "YOUR_TOKEN" \
  --public-key-file ~/.ssh/github-runner-key.pub
```

## Cost Optimization

- **t2.micro**: Free tier eligible, good for light workloads
- **t3.small**: ~$15/month, better for terraform workloads
- **Spot instances**: Add spot instance support for 70% cost savings

## Troubleshooting

### SSH to Runner

```bash
# Get SSH command from terraform output
cd runner-infrastructure
terraform output ssh_command

# Or manually
ssh -i ~/.ssh/github-runner-key ubuntu@RUNNER_PUBLIC_IP
```

### Check Runner Logs

```bash
# On the runner instance
sudo journalctl -u actions.runner.* -f
```

### Runner Not Appearing in GitHub

1. Check EC2 instance is running
2. Check security group allows outbound HTTPS (port 443)
3. SSH to instance and check `/var/log/runner-setup.log`

## Security Notes

- Runner has full AWS access (uses EC2 instance profile)
- Consider using IAM roles instead of access keys
- Restrict security group to your IP for SSH access
- Use private subnets for production setups