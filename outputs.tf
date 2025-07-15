output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.app_repo.repository_url
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "cloudwatch_log_group_ecs" {
  description = "CloudWatch log group for ECS"
  value       = aws_cloudwatch_log_group.ecs.name
}

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

# Load Balancer Outputs
output "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "load_balancer_zone_id" {
  description = "Zone ID of the load balancer"
  value       = aws_lb.main.zone_id
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.app.arn
}

# Route53 Outputs
output "route53_zone_id" {
  description = "Route53 hosted zone ID"
  value       = var.domain_name != "" ? aws_route53_zone.main[0].zone_id : null
}

output "domain_name" {
  description = "Domain name for the application"
  value       = var.domain_name != "" ? (var.subdomain != "" ? "${var.subdomain}.${var.domain_name}" : var.domain_name) : aws_lb.main.dns_name
}

# API Gateway Outputs
output "api_gateway_url" {
  description = "URL of the API Gateway"
  value       = aws_api_gateway_deployment.main.invoke_url
}

output "api_gateway_id" {
  description = "ID of the API Gateway"
  value       = aws_api_gateway_rest_api.main.id
}

output "api_gateway_domain_name" {
  description = "Custom domain name for API Gateway"
  value       = var.api_domain_name != "" ? aws_api_gateway_domain_name.main[0].domain_name : null
}

# CloudFront Outputs
output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.main.id
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "s3_static_assets_bucket" {
  description = "Name of the S3 bucket for static assets"
  value       = aws_s3_bucket.static_assets.bucket
}

output "s3_static_assets_bucket_domain" {
  description = "Domain name of the S3 bucket for static assets"
  value       = aws_s3_bucket.static_assets.bucket_domain_name
}

# Terraform State Management Outputs
output "terraform_state_bucket" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "terraform_state_lock_table" {
  description = "Name of the DynamoDB table for Terraform state locking"
  value       = aws_dynamodb_table.terraform_state_lock.name
}