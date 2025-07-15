# AWS Infrastructure with Terraform

This project sets up a complete AWS infrastructure including VPC, ECS, ECR, CloudWatch, Lambda, Application Load Balancer, Route53, API Gateway, and CloudFront.

## Prerequisites

- AWS CLI configured
- Terraform installed
- Docker (for building container images)
- Domain name (optional, for Route53 setup)

## Architecture

- **VPC**: Multi-AZ setup with public and private subnets
- **ECS**: Container orchestration with Fargate support
- **ECR**: Container registry for Docker images
- **ALB**: Application Load Balancer with SSL/TLS support
- **Route53**: DNS management with SSL certificates
- **Lambda**: Serverless functions with API Gateway integration
- **API Gateway**: RESTful API management with Lambda backend
- **CloudFront**: Global CDN with multiple origins (S3, ALB, API Gateway)
- **S3**: Static asset storage with CloudFront integration
- **CloudWatch**: Centralized logging and monitoring

## Setup

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your values:
   - Update AWS region and availability zones
   - Set your project name
   - Configure domain name (optional)

3. Create Lambda deployment package:
   ```bash
   zip lambda.zip lambda.js
   ```

4. Initialize and apply Terraform:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Resources Created

### Networking
- VPC with public and private subnets across multiple AZs
- Internet Gateway and NAT Gateways
- Route tables and security groups

### Compute & Storage
- ECS cluster for container orchestration
- ECR repository for container images
- Lambda function for serverless compute

### Load Balancing & DNS
- Application Load Balancer with HTTP/HTTPS listeners
- Route53 hosted zone and DNS records (if domain configured)
- ACM SSL certificate with automatic validation

### API & CDN
- API Gateway with Lambda integration and custom domain support
- CloudFront distribution with multiple origins:
  - S3 for static assets
  - ALB for dynamic web content
  - API Gateway for API endpoints
- S3 bucket for static asset storage with proper security

### Monitoring
- CloudWatch log groups for ECS and Lambda
- Proper IAM roles and policies

## Configuration Options

### Basic Setup (No Domain)
Leave `domain_name` empty in terraform.tfvars. The ALB will be accessible via its DNS name.

### Custom Domain Setup
1. Set `domain_name` in terraform.tfvars
2. Optionally configure:
   - `subdomain` for the main application
   - `api_domain_name` for API Gateway (e.g., "api.example.com")
   - `cloudfront_domain_name` for CDN (e.g., "cdn.example.com")
   - `cloudfront_aliases` for additional domain aliases
3. After deployment, update your domain's nameservers to use Route53

## Next Steps

1. **Deploy Container Application**:
   ```bash
   # Build and push to ECR
   aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin <ecr-url>
   docker build -t my-app .
   docker tag my-app:latest <ecr-url>:latest
   docker push <ecr-url>:latest
   ```

2. **Create ECS Service**: Add task definitions and services to run your containers

3. **Configure Lambda Triggers**: Set up event sources for your Lambda functions

4. **Upload Static Assets**:
   ```bash
   # Upload files to S3 for CloudFront distribution
   aws s3 sync ./static-files s3://<static-assets-bucket>/
   ```

5. **Test API Gateway**:
   ```bash
   # Test Lambda function via API Gateway
   curl https://<api-gateway-url>/dev/
   ```

6. **Monitor**: Use CloudWatch dashboards and alarms for monitoring

## Access Points

After deployment, your application will be accessible through multiple endpoints:

- **CloudFront**: Global CDN for static assets and cached content
- **ALB**: Direct access to containerized applications
- **API Gateway**: RESTful API endpoints backed by Lambda
- **Custom Domains**: If configured, your custom domains will route to appropriate services

## CloudFront Behavior

The CloudFront distribution is configured with intelligent routing:
- `/api/*` → API Gateway (no caching for dynamic API responses)
- `/app/*` → Application Load Balancer (no caching for dynamic web content)
- `/*` → S3 static assets (cached for performance)

## Cost Optimization

- CloudFront price class is configurable (PriceClass_100 for cost optimization)
- NAT Gateways are deployed per AZ (consider single NAT for dev environments)
- S3 bucket has lifecycle policies ready for implementation