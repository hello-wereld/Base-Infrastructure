# S3 Backend Configuration
# Note: Run this after creating the S3 bucket and DynamoDB table manually first
# or use the bootstrap script provided

terraform {
  backend "s3" {
    bucket         = "terraform-state-${var.project_name}-${var.environment}"
    key            = "terraform.tfstate"
    region         = var.aws_region
    dynamodb_table = "terraform-state-lock-${var.project_name}"
    encrypt        = true
  }
}