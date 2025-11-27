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

  # backend "s3" {} # use local backend to first create S3 bucket to store .tfstate later
}

#C:\Users\Owner\Desktop\KUBERNETES MASTER\AWS EKS\EKS-INFRA-TERRAFORM\remote_backend\composition\eu-west-1\prod