# GitHub Actions Deployment Guide

This guide explains how to deploy your AWS infrastructure using GitHub Actions.

## Prerequisites

1. **GitHub Repository**: Copy this code to your GitHub repository
2. **AWS Account**: With appropriate permissions
3. **AWS Credentials**: Access Key ID and Secret Access Key

## Setup Instructions

### 1. Configure GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions

Add the following **Repository Secrets**:

```
AWS_ACCESS_KEY_ID=your-aws-access-key-id
AWS_SECRET_ACCESS_KEY=your-aws-secret-access-key
AWS_REGION=us-west-2
PROJECT_NAME=your-project-name
```

### 2. Configure GitHub Environments

Create two environments in your repository:
- **development** (for dev branch)
- **production** (for main branch)

Go to Settings → Environments → New environment

For **production** environment, add protection rules:
- Required reviewers (recommended)
- Restrict to main branch

### 3. Repository Structure

Your repository should have these branches:
- `main` - Production environment
- `develop` - Development environment

## Deployment Workflows

### 1. Bootstrap Workflow (One-time setup)

**Purpose**: Creates S3 bucket and DynamoDB table for Terraform state management

**How to run**:
1. Go to Actions tab → "Bootstrap Terraform Backend"
2. Click "Run workflow"
3. Select environment (dev/prod)
4. Click "Run workflow"

This creates:
- S3 bucket for Terraform state
- DynamoDB table for state locking
- Backend configuration file

### 2. Main Terraform Workflow

**Automatic triggers**:
- **Push to main**: Deploys to production
- **Push to develop**: Plans for development
- **Pull Request**: Shows plan in PR comments

**Manual triggers**:
- Go to Actions → "Terraform Infrastructure"
- Select action: plan/apply/destroy

### 3. Validation Workflow

**Purpose**: Validates Terraform code on pull requests

**Automatic triggers**:
- Pull requests to main/develop branches
- Checks formatting, validation, and linting

## Deployment Process

### Initial Deployment

1. **Fork/Copy this repository**
2. **Set up secrets** (AWS credentials, project name)
3. **Create environments** (development, production)
4. **Run bootstrap workflow** for your environment
5. **Push to develop branch** to test
6. **Create PR to main** for production deployment

### Regular Deployments

1. **Make changes** in feature branch
2. **Create PR** to develop → See plan in comments
3. **Merge to develop** → Automatically plans
4. **Create PR** to main → See production plan
5. **Merge to main** → Automatically deploys to production

## Workflow Features

### Security
- AWS credentials stored as GitHub secrets
- Environment protection rules for production
- State stored in S3 with DynamoDB locking

### Automation
- Automatic formatting checks
- Terraform validation and linting
- Plan output in PR comments
- Infrastructure outputs in job summaries

### Flexibility
- Manual workflow dispatch for emergency changes
- Support for destroy operations
- Environment-specific configurations

## Configuration Files

### Environment Variables
The workflows automatically set:
- `TF_VAR_environment`: dev/prod based on branch
- `TF_VAR_project_name`: From GitHub secrets
- `TF_VAR_aws_region`: From GitHub secrets

### Backend Configuration
Automatically generated based on:
- Project name from secrets
- Environment from branch
- Region from secrets

## Monitoring Deployments

### GitHub Actions UI
- View workflow runs in Actions tab
- See detailed logs for each step
- Download artifacts (backend configs)

### AWS Console
- Monitor resource creation in AWS Console
- Check CloudWatch logs for issues
- Verify S3 state bucket contents

## Troubleshooting

### Common Issues

1. **Backend already exists error**:
   - Run bootstrap workflow with force_recreate: true
   - Or manually delete existing backend resources

2. **Permission denied**:
   - Check AWS credentials in secrets
   - Verify IAM permissions for your AWS user

3. **State lock error**:
   - Check DynamoDB table exists
   - Manually release lock if needed

4. **Plan shows unexpected changes**:
   - Check if someone made manual changes in AWS
   - Review terraform.tfvars configuration

### Getting Help

1. Check workflow logs in GitHub Actions
2. Review Terraform plan output
3. Check AWS CloudTrail for API calls
4. Verify resource states in AWS Console

## Best Practices

1. **Always review plans** before applying
2. **Use pull requests** for all changes
3. **Test in development** before production
4. **Monitor costs** in AWS Billing Console
5. **Keep secrets secure** and rotate regularly
6. **Use environment protection** for production

## Cleanup

To destroy infrastructure:
1. Go to Actions → "Terraform Infrastructure"
2. Run workflow with "destroy" action
3. Confirm in AWS Console that resources are deleted
4. Manually delete S3 state bucket if needed