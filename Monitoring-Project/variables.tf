variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Prefix for naming AWS resources"
  type        = string
  default     = "monitoring-stack"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to SSH into the instance"
  type        = string
  default     = "0.0.0.0/0"
}

variable "allowed_http_cidr" {
  description = "CIDR allowed to access web UIs (Jenkins, Prometheus, Grafana)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "key_pair_name" {
  description = "Existing AWS EC2 key pair name for SSH access"
  type        = string
}

variable "ami_id" {
  description = "Ubuntu 22.04 AMI ID in the chosen region"
  type        = string
  default     = "ami-0dee22c13ea7a9a67"
}

variable "instance_type" {
  description = "Instance type for the monitoring server"
  type        = string
  default     = "t3.large"
}


