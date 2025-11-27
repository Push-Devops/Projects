########################################
# Provider to connect to AWS
########################################

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  # backend "s3" {} # use backend.config for remote backend
}

provider "aws" {
  region = var.region
  profile = var.profile_name
  assume_role {
    role_arn = "arn:aws:iam::YOUR_AWS_ACCOUNT_ID:role/YOUR_IAM_ROLE_NAME"
  }
}