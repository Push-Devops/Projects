# Three-Layer Terraform Architecture for AWS Infrastructure

A production-ready, modular Terraform architecture following a three-layer composition pattern for managing AWS infrastructure. This project demonstrates best practices for organizing Terraform code with separation of concerns, reusability, and maintainability.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Three-Layer Pattern](#three-layer-pattern)
- [Components](#components)
- [Prerequisites](#prerequisites)
- [Setup Instructions](#setup-instructions)
- [Usage](#usage)
- [Configuration](#configuration)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

---

## Overview

This project implements a **three-layer Terraform architecture** for AWS infrastructure management:

1. **Resource Modules Layer** - Reusable, atomic resource modules
2. **Infrastructure Modules Layer** - Composed infrastructure components (VPC, Remote Backend)
3. **Composition Layer** - Environment-specific deployments (dev, staging, prod)

### Key Features

- ✅ **Modular Architecture** - Reusable modules at multiple levels
- ✅ **Remote Backend** - S3 + DynamoDB for state management
- ✅ **KMS Encryption** - Customer-managed keys for S3 backend encryption
- ✅ **Multi-Environment Support** - Separate compositions per environment
- ✅ **VPC Infrastructure** - Complete VPC with public, private, and database subnets
- ✅ **Security Groups** - Configurable security groups with least privilege
- ✅ **EKS Ready** - VPC configured for EKS cluster deployment
- ✅ **Best Practices** - Follows Terraform and AWS best practices

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Composition Layer                        │
│  (Environment-specific: eu-west-1/prod, eu-west-1/dev)       │
│  - main.tf, variables.tf, providers.tf, outputs.tf          │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              Infrastructure Modules Layer                    │
│  - remote_backend/  (S3 + DynamoDB + KMS)                  │
│  - vpc/             (VPC + Subnets + Security Groups)        │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                  Resource Modules Layer                     │
│  - database/dynamodb/  (DynamoDB table)                     │
│  - identity/kms_key/   (KMS key)                            │
└─────────────────────────────────────────────────────────────┘
```

---

## Project Structure

```
Three-Layer-Terr-AWS-Code/
├── remote_backend/                    # Remote Backend Infrastructure
│   ├── composition/                   # Composition layer
│   │   └── eu-west-1/
│   │       └── prod/                  # Production environment
│   │           ├── main.tf
│   │           ├── variables.tf
│   │           ├── providers.tf
│   │           ├── outputs.tf
│   │           └── data.tf
│   │
│   ├── infra_modules/                  # Infrastructure modules
│   │   └── remote_backend/            # S3 + DynamoDB + KMS module
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       ├── outputs.tf
│   │       ├── data.tf
│   │       └── README.md
│   │
│   └── resource_modules/               # Resource modules
│       ├── database/
│       │   └── dynamodb/              # DynamoDB table module
│       └── identity/
│           └── kms_key/               # KMS key module
│
├── VPC-Infra/                         # VPC Infrastructure
│   ├── composition/                   # Composition layer
│   │   └── eu-west-1/
│   │       └── prod/                  # Production environment
│   │           ├── main.tf
│   │           ├── variables.tf
│   │           ├── providers.tf
│   │           ├── outputs.tf
│   │           ├── data.tf
│   │           └── backend.config     # Remote backend config
│   │
│   ├── infra_modules/                  # Infrastructure modules
│   │   ├── remote_backend/            # Remote backend module
│   │   └── vpc/                       # VPC module
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       ├── outputs.tf
│   │       └── data.tf
│   │
│   ├── resource_modules/               # Resource modules
│   │   ├── database/
│   │   │   └── dynamodb/              # DynamoDB table module
│   │   └── identity/
│   │       └── kms_key/               # KMS key module
│   │
│   └── VPC-README.md                  # VPC-specific documentation
│
└── README.md                          # This file
```

---

## Three-Layer Pattern

### Layer 1: Resource Modules
**Purpose**: Atomic, reusable resource modules

- **Location**: `resource_modules/`
- **Examples**: 
  - `database/dynamodb/` - DynamoDB table creation
  - `identity/kms_key/` - KMS key creation
- **Characteristics**:
  - Single responsibility
  - Highly reusable
  - Minimal dependencies
  - Well-defined inputs/outputs

### Layer 2: Infrastructure Modules
**Purpose**: Composed infrastructure components

- **Location**: `infra_modules/`
- **Examples**:
  - `remote_backend/` - Complete remote backend (S3 + DynamoDB + KMS)
  - `vpc/` - Complete VPC infrastructure
- **Characteristics**:
  - Composes multiple resource modules
  - Business logic and relationships
  - Environment-agnostic
  - Reusable across environments

### Layer 3: Composition Layer
**Purpose**: Environment-specific deployments

- **Location**: `composition/{region}/{env}/`
- **Examples**:
  - `eu-west-1/prod/` - Production in EU West 1
  - `eu-west-1/dev/` - Development in EU West 1
- **Characteristics**:
  - Environment-specific values
  - Calls infrastructure modules
  - Defines provider configuration
  - Manages remote backend

---

## Components

### 1. Remote Backend

**Purpose**: Terraform state management with S3, DynamoDB, and KMS

**Components**:
- **S3 Bucket**: Stores Terraform state files
  - Versioning enabled
  - KMS encryption
  - Public access blocked
  - Bucket policy for access control
- **DynamoDB Table**: State locking
  - Prevents concurrent modifications
  - Hash key: `LockID`
- **KMS Key**: Customer-managed key for encryption
  - Key rotation enabled
  - IAM policy for access control

**Naming Convention**:
- S3: `s3-{region_tag}-{env}-backend-{account_id}`
- DynamoDB: `dynamo-{region_tag}-{app_name}-{env}-terraform-state-lock`
- KMS Alias: `alias/cmk-{region_tag}-{env}-s3-terraform-backend`

### 2. VPC Infrastructure

**Purpose**: Complete VPC setup for application deployment

**Components**:
- **VPC**: Custom CIDR block
- **Subnets**:
  - Public subnets (for load balancers, NAT gateways)
  - Private subnets (for application servers, EKS)
  - Database subnets (for RDS, databases)
- **Internet Gateway**: For public subnet internet access
- **NAT Gateway**: For private subnet internet access
  - Single NAT gateway (cost optimization)
  - Can be configured for multi-AZ
- **Security Groups**:
  - Public security group
  - Private security group
  - Database security group (EKS-ready)

**Features**:
- DNS hostnames and support enabled
- EKS-ready configuration
- Configurable ingress rules
- Tagged with environment and application metadata

---

## Prerequisites

### Required Software
- **Terraform** >= 1.0
- **AWS CLI** >= 2.0
- **Git**

### AWS Requirements
- AWS account with appropriate permissions
- IAM role for Terraform execution
- AWS profile configured

### AWS Permissions

The IAM role/user needs permissions for:
- **S3**: Create bucket, manage bucket policies, versioning
- **DynamoDB**: Create table, manage items
- **KMS**: Create keys, manage key policies, encryption/decryption
- **VPC**: Create VPC, subnets, gateways, security groups
- **EC2**: Describe instances, security groups
- **IAM**: Assume roles, read roles

---

## Setup Instructions

### Step 1: Configure AWS Credentials

1. **Configure AWS Profile**:
   ```bash
   aws configure --profile YOUR_AWS_PROFILE_NAME
   ```

2. **Set Up IAM Role** (if using assume role):
   - Create IAM role: `YOUR_IAM_ROLE_NAME`
   - Grant necessary permissions
   - Update `providers.tf` with role ARN:
     ```hcl
     assume_role {
       role_arn = "arn:aws:iam::YOUR_AWS_ACCOUNT_ID:role/YOUR_IAM_ROLE_NAME"
     }
     ```

### Step 2: Deploy Remote Backend (First Time Only)

1. **Navigate to remote backend composition**:
   ```bash
   cd Three-Layer-Terr-AWS-Code/remote_backend/composition/eu-west-1/prod
   ```

2. **Create terraform.tfvars**:
   ```hcl
   env      = "prod"
   region   = "eu-west-1"
   app_name = "your-app-name"
   
   # Remote Backend Configuration
   force_destroy         = false
   versioning_enabled    = true
   block_public_policy   = true
   block_public_acls     = true
   ignore_public_acls    = true
   restrict_public_buckets = true
   
   # DynamoDB Configuration
   read_capacity  = 5
   write_capacity = 5
   hash_key       = "LockID"
   attribute_name = "LockID"
   attribute_type = "S"
   sse_enabled    = true
   ```

3. **Initialize and Deploy**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Save Backend Outputs**:
   ```bash
   terraform output > backend-outputs.txt
   ```

### Step 3: Configure VPC Backend

1. **Navigate to VPC composition**:
   ```bash
   cd Three-Layer-Terr-AWS-Code/VPC-Infra/composition/eu-west-1/prod
   ```

2. **Update backend.config**:
   ```hcl
   bucket         = "s3-ew1-prod-backend-YOUR_AWS_ACCOUNT_ID"
   key            = "vpc-infra/terraform.tfstate"
   region         = "eu-west-1"
   encrypt        = true
   dynamodb_table = "dynamo-ew1-your-app-name-prod-terraform-state-lock"
   kms_key_id     = "arn:aws:kms:eu-west-1:YOUR_AWS_ACCOUNT_ID:key/YOUR_KMS_KEY_ID"
   ```

3. **Initialize with Backend**:
   ```bash
   terraform init -backend-config=backend.config
   ```

### Step 4: Deploy VPC Infrastructure

1. **Create terraform.tfvars**:
   ```hcl
   env      = "prod"
   region   = "eu-west-1"
   app_name = "your-app-name"
   profile_name = "YOUR_AWS_PROFILE_NAME"
   role_name    = "YOUR_IAM_ROLE_NAME"
   
   # VPC Configuration
   cidr = "10.0.0.0/16"
   azs  = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
   
   public_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
   private_subnets = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
   database_subnets = ["10.0.20.0/24", "10.0.21.0/24", "10.0.22.0/24"]
   
   enable_dns_hostnames = true
   enable_dns_support   = true
   enable_nat_gateway   = true
   single_nat_gateway   = true
   
   # Security Groups
   public_ingress_with_cidr_blocks = [
     {
       rule        = "http-80-tcp"
       cidr_blocks = "0.0.0.0/0"
       description = "HTTP from anywhere"
     },
     {
       rule        = "https-443-tcp"
       cidr_blocks = "0.0.0.0/0"
       description = "HTTPS from anywhere"
     }
   ]
   
   create_eks = false  # Set to true when deploying EKS
   ```

2. **Deploy**:
   ```bash
   terraform plan
   terraform apply
   ```

---

## Usage

### Creating New Environments

1. **Copy composition directory**:
   ```bash
   cp -r remote_backend/composition/eu-west-1/prod \
       remote_backend/composition/eu-west-1/dev
   ```

2. **Update variables** for the new environment

3. **Deploy**:
   ```bash
   cd remote_backend/composition/eu-west-1/dev
   terraform init
   terraform apply
   ```

### Adding New Infrastructure Modules

1. **Create module in `infra_modules/`**
2. **Define inputs/outputs**
3. **Use in composition layer**

### Adding New Resource Modules

1. **Create module in `resource_modules/`**
2. **Keep it atomic and reusable**
3. **Use in infrastructure modules**

---

## Configuration

### Variable Reference

#### Common Variables
- `env` - Environment name (dev, staging, prod)
- `region` - AWS region
- `app_name` - Application name
- `profile_name` - AWS profile name
- `role_name` - IAM role name for assume role

#### Remote Backend Variables
- `force_destroy` - Allow bucket deletion with contents
- `versioning_enabled` - Enable S3 versioning
- `block_public_policy` - Block public bucket policies
- `block_public_acls` - Block public ACLs
- `ignore_public_acls` - Ignore public ACLs
- `restrict_public_buckets` - Restrict public bucket policies
- `read_capacity` - DynamoDB read capacity
- `write_capacity` - DynamoDB write capacity
- `hash_key` - DynamoDB hash key name
- `attribute_name` - DynamoDB attribute name
- `attribute_type` - DynamoDB attribute type
- `sse_enabled` - Enable server-side encryption

#### VPC Variables
- `cidr` - VPC CIDR block
- `azs` - Availability zones
- `public_subnets` - Public subnet CIDRs
- `private_subnets` - Private subnet CIDRs
- `database_subnets` - Database subnet CIDRs
- `enable_dns_hostnames` - Enable DNS hostnames
- `enable_dns_support` - Enable DNS support
- `enable_nat_gateway` - Enable NAT gateway
- `single_nat_gateway` - Use single NAT gateway
- `public_ingress_with_cidr_blocks` - Public security group rules
- `create_eks` - Whether EKS will be deployed

---

## Best Practices

### 1. State Management
- ✅ Always use remote backend (S3 + DynamoDB)
- ✅ Enable state encryption with KMS
- ✅ Use separate state files per environment
- ✅ Enable S3 versioning for state files

### 2. Module Design
- ✅ Single responsibility per module
- ✅ Clear input/output documentation
- ✅ Use locals for computed values
- ✅ Tag all resources consistently

### 3. Security
- ✅ Block public access to S3 buckets
- ✅ Use least privilege IAM policies
- ✅ Enable KMS encryption
- ✅ Use security groups with specific rules

### 4. Cost Optimization
- ✅ Use single NAT gateway for non-production
- ✅ Right-size DynamoDB capacity
- ✅ Use appropriate instance types
- ✅ Clean up unused resources

### 5. Naming Conventions
- ✅ Use consistent naming patterns
- ✅ Include environment in names
- ✅ Use region tags for multi-region
- ✅ Include resource type in names

---

## Troubleshooting

### Common Issues

#### 1. Backend Initialization Fails

**Error**: `Error loading backend config: AccessDenied`

**Solution**:
- Verify AWS credentials
- Check IAM permissions
- Verify bucket exists
- Check bucket policy

#### 2. State Lock Error

**Error**: `Error acquiring the state lock`

**Solution**:
```bash
# Check lock in DynamoDB
aws dynamodb get-item \
  --table-name dynamo-ew1-prod-terraform-state-lock \
  --key '{"LockID": {"S": "..."}}'

# Force unlock (use with caution)
terraform force-unlock LOCK_ID
```

#### 3. Module Not Found

**Error**: `Module not found`

**Solution**:
- Run `terraform init` to download modules
- Verify module paths are correct
- Check relative paths in module sources

#### 4. Provider Authentication

**Error**: `No valid credential sources found`

**Solution**:
- Verify AWS profile is configured
- Check `~/.aws/credentials`
- Verify IAM role ARN is correct
- Check assume role permissions

---

## Additional Resources

### Documentation
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Remote Backend](https://www.terraform.io/docs/language/settings/backends/s3.html)
- [AWS VPC Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-best-practices.html)

### Related Projects
- [Monitoring Stack](../Monitoring-Project/) - Jenkins, Prometheus, Grafana
- [AWS ECS Project](../AWS-ECS-PROJECT/) - Django API on ECS Fargate
- [Blue-Green Deployment](../Blue-green-Deployment/) - EKS Blue-Green CI/CD

---

## Notes

- Replace all placeholder values (`YOUR_*`) with actual values
- Use separate AWS accounts/profiles for different environments
- Review and adjust security group rules for your use case
- Enable multi-AZ NAT gateways for production
- Consider using Terraform Cloud for team collaboration

---

**Last Updated**: 2025-01-26

