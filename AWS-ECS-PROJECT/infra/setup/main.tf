terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.23.0"
    }
  }

  backend "s3" {
    bucket         = "devops-app-tf-state-v101"
    key            = "tf-state-setup"
    region         = "eu-west-2"
    encrypt        = true
    dynamodb_table = "devops-app-api-tf-lock"
  }
}

provider "aws" {
  region = "eu-west-2"

  default_tags {
    tags = {
      Environment = terraform.workspace
      Project     = var.project
      Contact     = var.contact
      ManageBy    = "Terraform/setup"
    }
  }
}
