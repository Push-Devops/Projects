# Django REST API on AWS ECS Fargate

A production-ready Django REST API application deployed on AWS ECS Fargate with comprehensive infrastructure automation using Terraform.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Technology Stack](#technology-stack)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Infrastructure Components](#infrastructure-components)
- [Setup Instructions](#setup-instructions)
- [Configuration](#configuration)
- [Deployment Guide](#deployment-guide)
- [Local Development](#local-development)
- [CI/CD Integration](#cicd-integration)
- [Monitoring & Logging](#monitoring--logging)
- [Security](#security)
- [Cost Estimation](#cost-estimation)
- [Troubleshooting](#troubleshooting)
- [API Documentation](#api-documentation)
- [Review & Suggestions](#review--suggestions)

---

## Overview

This project demonstrates a complete DevOps deployment pipeline for a Django REST API application on AWS. It includes:

- **Django REST Framework** application with recipe management API
- **AWS ECS Fargate** for container orchestration
- **RDS PostgreSQL** database
- **Application Load Balancer** with SSL/TLS termination
- **EFS** for persistent media/static file storage
- **Route53** DNS management with ACM certificates
- **Terraform** infrastructure as code
- **Docker** containerization
- **CloudWatch** logging and monitoring

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Internet                              │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              Application Load Balancer (ALB)                │
│              - HTTPS (443) → HTTP (8000)                    │
│              - SSL/TLS Termination                          │
│              - Health Checks                                │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    Route53 DNS                               │
│              api.yourdomain.com                              │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    VPC (10.1.0.0/16)                        │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Public Subnets (ALB)                               │   │
│  │  - 10.1.1.0/24 (AZ-a)                               │   │
│  │  - 10.1.2.0/24 (AZ-b)                               │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Private Subnets (ECS Tasks)                         │   │
│  │  - 10.1.10.0/24 (AZ-a)                               │   │
│  │  - 10.1.11.0/24 (AZ-b)                               │   │
│  │                                                       │   │
│  │  ┌─────────────────────────────────────────────┐    │   │
│  │  │  ECS Fargate Service                        │    │   │
│  │  │  ┌──────────────┐  ┌──────────────┐        │    │   │
│  │  │  │   API        │  │   Proxy      │        │    │   │
│  │  │  │  (Django)    │  │  (Nginx)     │        │    │   │
│  │  │  └──────────────┘  └──────────────┘        │    │   │
│  │  └─────────────────────────────────────────────┘    │   │
│  │                                                       │   │
│  │  ┌─────────────────────────────────────────────┐    │   │
│  │  │  RDS PostgreSQL                              │    │   │
│  │  │  - Multi-AZ: No (dev)                        │    │   │
│  │  │  - Engine: PostgreSQL 16.4                  │    │   │
│  │  └─────────────────────────────────────────────┘    │   │
│  │                                                       │   │
│  │  ┌─────────────────────────────────────────────┐    │   │
│  │  │  EFS (Elastic File System)                   │    │   │
│  │  │  - /vol/web/static                           │    │   │
│  │  │  - /vol/web/media                            │    │   │
│  │  └─────────────────────────────────────────────┘    │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  VPC Endpoints                                       │   │
│  │  - ECR (api/dkr)                                     │   │
│  │  - CloudWatch Logs                                   │   │
│  │  - SSM Messages                                     │   │
│  │  - S3 (Gateway)                                      │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## Technology Stack

### Application
- **Python 3.9** - Programming language
- **Django 4.x** - Web framework
- **Django REST Framework** - API framework
- **PostgreSQL** - Database
- **Gunicorn** - WSGI server
- **Nginx** - Reverse proxy

### Infrastructure
- **AWS ECS Fargate** - Container orchestration
- **AWS RDS PostgreSQL** - Managed database
- **AWS EFS** - Shared file storage
- **AWS ALB** - Application load balancer
- **AWS Route53** - DNS management
- **AWS ACM** - SSL/TLS certificates
- **AWS CloudWatch** - Logging and monitoring
- **AWS VPC** - Network isolation
- **AWS ECR** - Container registry

### DevOps Tools
- **Terraform** - Infrastructure as Code
- **Docker** - Containerization
- **Docker Compose** - Local development
- **GitHub Actions / GitLab CI** - CI/CD pipelines

---

## Features

### Application Features
- ✅ RESTful API for recipe management
- ✅ User authentication and authorization
- ✅ Recipe CRUD operations
- ✅ Tag and ingredient management
- ✅ Image upload support
- ✅ Health check endpoint
- ✅ Database migrations
- ✅ Static file serving
- ✅ Media file storage

### Infrastructure Features
- ✅ Multi-AZ deployment for high availability
- ✅ Auto-scaling ready (can be configured)
- ✅ SSL/TLS encryption
- ✅ Private subnet deployment
- ✅ VPC endpoints for AWS services
- ✅ CloudWatch logging
- ✅ Health checks and monitoring
- ✅ Environment-specific deployments (dev/staging/prod)

---

## Prerequisites

### Required Software
- **Terraform** >= 1.0
- **AWS CLI** >= 2.0
- **Docker** and **Docker Compose**
- **Python** 3.9+ (for local development)
- **Git**
- **aws-vault** (recommended for credential management)

### AWS Requirements
- AWS account with appropriate permissions
- Route53 hosted zone for your domain
- S3 bucket for Terraform state (or create one)
- DynamoDB table for Terraform state locking (or create one)

### AWS Permissions
The setup Terraform creates an IAM user with the following permissions:
- ECR (Elastic Container Registry)
- ECS (Elastic Container Service)
- RDS (Relational Database Service)
- EC2 (VPC, Subnets, Security Groups)
- ELB (Elastic Load Balancer)
- EFS (Elastic File System)
- Route53 (DNS)
- ACM (SSL Certificates)
- CloudWatch Logs
- IAM (for roles and policies)
- S3 (for Terraform backend)
- DynamoDB (for state locking)

---

## Project Structure

```
AWS-ECS-PROJECT/
├── app/                          # Django application
│   ├── app/                      # Main Django app
│   │   ├── settings.py           # Django settings
│   │   ├── urls.py               # URL routing
│   │   └── wsgi.py               # WSGI configuration
│   ├── core/                     # Core app
│   │   ├── models.py             # Base models
│   │   ├── views.py              # Health check views
│   │   └── management/           # Custom management commands
│   ├── recipe/                   # Recipe app
│   │   ├── models.py             # Recipe models
│   │   ├── views.py              # Recipe views
│   │   └── serializers.py        # DRF serializers
│   ├── user/                     # User app
│   │   ├── models.py             # User models
│   │   └── serializers.py        # User serializers
│   └── manage.py                 # Django management script
│
├── proxy/                        # Nginx proxy container
│   ├── Dockerfile                # Proxy Dockerfile
│   ├── default.conf.tpl          # Nginx configuration template
│   └── run.sh                    # Startup script
│
├── infra/                        # Terraform infrastructure
│   ├── setup/                    # Initial setup (run first)
│   │   ├── main.tf               # Terraform configuration
│   │   ├── variables.tf          # Setup variables
│   │   ├── ecr.tf                # ECR repositories
│   │   ├── iam.tf                # IAM user and policies
│   │   └── output.tf             # Setup outputs
│   │
│   └── deploy/                   # Main deployment (run second)
│       ├── main.tf               # Terraform configuration
│       ├── variables.tf         # Deployment variables
│       ├── network.tf            # VPC, subnets, endpoints
│       ├── ecs.tf                # ECS cluster, service, task definition
│       ├── database.tf           # RDS PostgreSQL
│       ├── load_balancer.tf      # Application Load Balancer
│       ├── efs.tf                # Elastic File System
│       ├── dns.tf                # Route53 and ACM
│       ├── output.tf             # Deployment outputs
│       └── templates/            # IAM policy templates
│           └── ecs/
│               ├── task-assume-role-policy.json
│               ├── task-execution-role-policy.json
│               └── task-ssm-policy.json
│
├── scripts/                      # Utility scripts
│   └── run.sh                    # Application startup script
│
├── Dockerfile                    # Application Dockerfile
├── docker-compose.yml            # Local development
├── docker-compose-deploy.yml     # Production-like local setup
├── requirements.txt              # Production dependencies
├── requirements.dev.txt          # Development dependencies
├── LICENSE                      # License file
├── README.md                    # This file
└── REVIEW-AND-SUGGESTIONS.md    # Code review and improvements
```

---

## Infrastructure Components

### 1. VPC and Networking
- **VPC**: `10.1.0.0/16` CIDR block
- **Public Subnets**: 
  - `10.1.1.0/24` (Availability Zone A)
  - `10.1.2.0/24` (Availability Zone B)
- **Private Subnets**:
  - `10.1.10.0/24` (Availability Zone A)
  - `10.1.11.0/24` (Availability Zone B)
- **Internet Gateway**: For public subnet internet access
- **VPC Endpoints**: ECR, CloudWatch Logs, SSM, S3

### 2. ECS Fargate
- **Cluster**: ECS Fargate cluster
- **Service**: ECS service with desired count
- **Task Definition**: Multi-container task (API + Proxy)
- **CPU**: 256 CPU units
- **Memory**: 512 MB
- **Platform**: Linux/X86_64

### 3. RDS PostgreSQL
- **Engine**: PostgreSQL 16.4
- **Instance Class**: db.t4g.micro
- **Storage**: 20 GB gp2
- **Multi-AZ**: Disabled (can be enabled for production)
- **Backup**: Currently disabled (should be enabled)

### 4. Application Load Balancer
- **Type**: Application Load Balancer
- **Listeners**: HTTP (80) → HTTPS (443) redirect
- **Target Group**: Health checks on `/api/health-check/`
- **SSL/TLS**: ACM certificate with DNS validation

### 5. EFS (Elastic File System)
- **Purpose**: Persistent storage for static and media files
- **Encryption**: Enabled
- **Mount Targets**: One per private subnet
- **Access Point**: Configured for media directory

### 6. Route53 and DNS
- **DNS Zone**: Managed by Route53
- **Subdomain Mapping**:
  - `prod` → `api.yourdomain.com`
  - `staging` → `api.staging.yourdomain.com`
  - `dev` → `api.dev.yourdomain.com`

### 7. CloudWatch
- **Log Groups**: ECS task logs
- **Log Retention**: Default (never expire)
- **Metrics**: ECS service metrics

---

## Setup Instructions

### Step 1: Prerequisites Setup

1. **Install Required Tools**:
   ```bash
   # Install Terraform
   brew install terraform  # macOS
   # or download from https://www.terraform.io/downloads

   # Install AWS CLI
   aws --version

   # Install Docker
   docker --version
   docker compose version
   ```

2. **Configure AWS Credentials**:
   ```bash
   # Using aws-vault (recommended)
   aws-vault exec PROFILE --duration=8h

   # Or using AWS CLI
   aws configure
   ```

3. **Create Terraform Backend Resources** (if not exists):
   ```bash
   # Create S3 bucket for state
   aws s3 mb s3://devops-app-tf-state-v101 --region eu-west-2

   # Create DynamoDB table for locking
   aws dynamodb create-table \
     --table-name devops-app-api-tf-lock \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST \
     --region eu-west-2
   ```

### Step 2: Initial Setup (ECR and IAM)

1. **Navigate to setup directory**:
   ```bash
   cd AWS-ECS-PROJECT/infra/setup
   ```

2. **Initialize Terraform**:
   ```bash
   terraform init
   ```

3. **Create terraform.tfvars**:
   ```hcl
   # terraform.tfvars
   tf_state_bucket     = "devops-app-tf-state-v101"
   tf_state_lock_table = "devops-app-api-tf-lock"
   project             = "recipe-app-api"
   contact             = "your-email@example.com"
   ```

4. **Plan and Apply**:
   ```bash
   terraform plan
   terraform apply
   ```

5. **Save Outputs**:
   ```bash
   # Save ECR repository URLs
   terraform output ecr_repo_app > /tmp/ecr_app.txt
   terraform output ecr_repo_proxy > /tmp/ecr_proxy.txt

   # Save CD user credentials (for CI/CD)
   terraform output cd_user_access_key_id
   terraform output -raw cd_user_access_key_secret  # Save securely
   ```

### Step 3: Build and Push Docker Images

1. **Authenticate with ECR**:
   ```bash
   aws ecr get-login-password --region eu-west-2 | \
     docker login --username AWS --password-stdin \
     $(aws sts get-caller-identity --query Account --output text).dkr.ecr.eu-west-2.amazonaws.com
   ```

2. **Get ECR Repository URLs**:
   ```bash
   APP_REPO=$(terraform -chdir=infra/setup output -raw ecr_repo_app)
   PROXY_REPO=$(terraform -chdir=infra/setup output -raw ecr_repo_proxy)
   ```

3. **Build and Push App Image**:
   ```bash
   cd AWS-ECS-PROJECT
   docker build -t $APP_REPO:latest .
   docker push $APP_REPO:latest
   ```

4. **Build and Push Proxy Image**:
   ```bash
   docker build -t $PROXY_REPO:latest -f proxy/Dockerfile ./proxy
   docker push $PROXY_REPO:latest
   ```

### Step 4: Deploy Infrastructure

1. **Navigate to deploy directory**:
   ```bash
   cd AWS-ECS-PROJECT/infra/deploy
   ```

2. **Select or Create Workspace**:
   ```bash
   # Create workspace for environment
   terraform workspace new dev
   # or
   terraform workspace select dev
   ```

3. **Create terraform.tfvars**:
   ```hcl
   # terraform.tfvars
   prefix            = "recipe-app"
   project           = "recipe-app-api"
   contact           = "your-email@example.com"
   db_username       = "recipeapp"
   db_password       = "YOUR_SECURE_PASSWORD_HERE"  # Use AWS Secrets Manager in production
   django_secret_key = "YOUR_DJANGO_SECRET_KEY"     # Use AWS Secrets Manager in production
   dns_zone_name     = "yourdomain.com"
   
   # Get from setup outputs
   ecr_app_image     = "123456789012.dkr.ecr.eu-west-2.amazonaws.com/recipe-app-api-app:latest"
   ecr_proxy_image   = "123456789012.dkr.ecr.eu-west-2.amazonaws.com/recipe-app-api-proxy:latest"
   ```

4. **Initialize Terraform**:
   ```bash
   terraform init
   ```

5. **Plan Deployment**:
   ```bash
   terraform plan
   ```

6. **Apply Deployment**:
   ```bash
   terraform apply
   ```

7. **Get API Endpoint**:
   ```bash
   terraform output api_endpoint
   # Output: api.dev.yourdomain.com
   ```

### Step 5: Verify Deployment

1. **Check ECS Service**:
   ```bash
   aws ecs describe-services \
     --cluster recipe-app-dev-cluster \
     --services recipe-app-dev-api \
     --region eu-west-2
   ```

2. **Check Health Endpoint**:
   ```bash
   curl https://api.dev.yourdomain.com/api/health-check/
   ```

3. **View Logs**:
   ```bash
   aws logs tail /aws/ecs/recipe-app-dev-api --follow --region eu-west-2
   ```

---

## Configuration

### Environment Variables

The ECS task definition uses the following environment variables:

| Variable | Description | Source |
|----------|-------------|--------|
| `DJANGO_SECRET_KEY` | Django secret key | Terraform variable |
| `DB_HOST` | RDS endpoint | Terraform (aws_db_instance.main.address) |
| `DB_NAME` | Database name | `recipe` (hardcoded) |
| `DB_USER` | Database username | Terraform variable |
| `DB_PASS` | Database password | Terraform variable |
| `ALLOWED_HOSTS` | Allowed hostnames | Route53 FQDN |

### Terraform Variables

#### Setup Variables (`infra/setup/variables.tf`)
- `tf_state_bucket` - S3 bucket for Terraform state
- `tf_state_lock_table` - DynamoDB table for state locking
- `project` - Project name for tagging
- `contact` - Contact email for tagging

#### Deploy Variables (`infra/deploy/variables.tf`)
- `prefix` - Resource name prefix
- `project` - Project name
- `contact` - Contact email
- `db_username` - RDS username
- `db_password` - RDS password (should use Secrets Manager)
- `django_secret_key` - Django secret key (should use Secrets Manager)
- `ecr_app_image` - ECR image URL for app
- `ecr_proxy_image` - ECR image URL for proxy
- `dns_zone_name` - Route53 zone name
- `subdomain` - Subdomain mapping per environment

### Workspace Configuration

Terraform workspaces are used for environment separation:
- `dev` - Development environment
- `staging` - Staging environment
- `prod` - Production environment

Each workspace uses different subdomains and can have different resource configurations.

---

## Deployment Guide

### Initial Deployment

1. **Complete Setup Steps** (see [Setup Instructions](#setup-instructions))
2. **Build and Push Images**
3. **Deploy Infrastructure**
4. **Run Database Migrations**:
   ```bash
   # Connect to ECS task
   aws ecs execute-command \
     --cluster recipe-app-dev-cluster \
     --task TASK_ID \
     --container api \
     --interactive \
     --command "/bin/sh" \
     --region eu-west-2

   # Inside container
   python manage.py migrate
   python manage.py collectstatic --noinput
   ```

### Updating Application

1. **Build New Image**:
   ```bash
   docker build -t $APP_REPO:new-tag .
   docker push $APP_REPO:new-tag
   ```

2. **Update Task Definition**:
   ```bash
   # Update ecr_app_image in terraform.tfvars
   terraform apply
   ```

3. **Force New Deployment** (if needed):
   ```bash
   aws ecs update-service \
     --cluster recipe-app-dev-cluster \
     --service recipe-app-dev-api \
     --force-new-deployment \
     --region eu-west-2
   ```

### Database Migrations

Run migrations via ECS Exec:
```bash
aws ecs execute-command \
  --cluster recipe-app-dev-cluster \
  --task TASK_ID \
  --container api \
  --interactive \
  --command "python manage.py migrate" \
  --region eu-west-2
```

---

## Local Development

### Using Docker Compose

1. **Start Services**:
   ```bash
   docker compose up
   ```

2. **Run Migrations**:
   ```bash
   docker compose run --rm app sh -c "python manage.py migrate"
   ```

3. **Create Superuser**:
   ```bash
   docker compose run --rm app sh -c "python manage.py createsuperuser"
   ```

4. **Access Application**:
   - API: http://localhost:8000
   - Admin: http://localhost:8000/admin
   - Health Check: http://localhost:8000/api/health-check/

### Development Environment Variables

Create `.env` file (not committed):
```bash
DB_HOST=db
DB_NAME=devdb
DB_USER=devuser
DB_PASS=changeme
DEBUG=1
```

### Running Tests

```bash
docker compose run --rm app sh -c "python manage.py test"
```

---

## CI/CD Integration

### GitHub Actions Variables

Configure these in GitHub Secrets:

**Variables:**
- `AWS_ACCESS_KEY_ID` - CD user access key
- `AWS_ACCOUNT_ID` - AWS account ID
- `DOCKERHUB_USER` - Docker Hub username (optional)
- `ECR_REPO_APP` - ECR app repository URL
- `ECR_REPO_PROXY` - ECR proxy repository URL

**Secrets:**
- `AWS_SECRET_ACCESS_KEY` - CD user secret key
- `DOCKERHUB_TOKEN` - Docker Hub token (optional)
- `TF_VAR_DB_PASSWORD` - Database password
- `TF_VAR_DJANGO_SECRET_KEY` - Django secret key

### GitLab CI/CD Variables

Configure in GitLab CI/CD Variables (mask sensitive ones):

- `AWS_ACCESS_KEY_ID`
- `AWS_ACCOUNT_ID`
- `DOCKERHUB_USER`
- `ECR_REPO_APP`
- `ECR_REPO_PROXY`
- `AWS_SECRET_ACCESS_KEY` (Masked)
- `DOCKERHUB_TOKEN` (Masked)
- `TF_VAR_db_password` (Masked)
- `TF_VAR_django_secret_key` (Masked, Protected)

### Example CI/CD Pipeline

```yaml
# .github/workflows/deploy.yml
name: Deploy to ECS

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: eu-west-2
      
      - name: Login to ECR
        run: |
          aws ecr get-login-password --region eu-west-2 | \
            docker login --username AWS --password-stdin ${{ vars.ECR_REPO_APP }}
      
      - name: Build and push
        run: |
          docker build -t ${{ vars.ECR_REPO_APP }}:latest .
          docker push ${{ vars.ECR_REPO_APP }}:latest
      
      - name: Deploy
        run: |
          cd infra/deploy
          terraform init
          terraform apply -auto-approve
```

---

## Monitoring & Logging

### CloudWatch Logs

View application logs:
```bash
aws logs tail /aws/ecs/recipe-app-dev-api --follow --region eu-west-2
```

### CloudWatch Metrics

Monitor ECS service metrics:
- CPU utilization
- Memory utilization
- Request count
- Target response time

### Health Checks

- **Endpoint**: `/api/health-check/`
- **ALB Health Check**: Configured on target group
- **Interval**: Default (30 seconds)

### Setting Up Alarms

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name recipe-app-high-cpu \
  --alarm-description "Alert when CPU exceeds 80%" \
  --metric-name CPUUtilization \
  --namespace AWS/ECS \
  --statistic Average \
  --period 60 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2 \
  --region eu-west-2
```

---

## Security

### Current Security Features
- ✅ Private subnet deployment
- ✅ Security groups with least privilege
- ✅ VPC endpoints (no internet access needed)
- ✅ SSL/TLS encryption (HTTPS)
- ✅ EFS encryption at rest
- ✅ Non-root container users
- ✅ IAM roles with minimal permissions

### Security Recommendations

1. **Use AWS Secrets Manager** for sensitive data:
   - Database passwords
   - Django secret keys
   - API keys

2. **Enable Database Backups**:
   ```hcl
   backup_retention_period = 7
   skip_final_snapshot    = false
   ```

3. **Enable Multi-AZ for RDS** (production):
   ```hcl
   multi_az = true
   ```

4. **Enable ECR Image Scanning**:
   ```hcl
   image_scanning_configuration {
     scan_on_push = true
   }
   ```

5. **Add WAF** for additional protection

6. **Enable CloudWatch Log Retention**:
   ```hcl
   retention_in_days = 30
   ```

See [REVIEW-AND-SUGGESTIONS.md](REVIEW-AND-SUGGESTIONS.md) for detailed security improvements.

---

## Cost Estimation

### Monthly Cost Estimate (Development)

| Service | Configuration | Estimated Cost |
|---------|--------------|-----------------|
| ECS Fargate | 0.25 vCPU, 0.5 GB RAM, 1 task | ~$15-20 |
| RDS PostgreSQL | db.t4g.micro, 20 GB | ~$15-20 |
| ALB | Standard ALB | ~$20-25 |
| EFS | 1 GB storage, minimal I/O | ~$0.30 |
| Route53 | Hosted zone + queries | ~$0.50 |
| VPC Endpoints | 4 interface endpoints | ~$30-40 |
| CloudWatch Logs | 1 GB/month | ~$0.50 |
| Data Transfer | Minimal | ~$1-5 |
| **Total** | | **~$80-120/month** |

### Production Cost Considerations
- Multi-AZ RDS: +100% cost
- Auto-scaling: Variable based on traffic
- Backup storage: Additional cost
- Reserved capacity: Can reduce costs by 30-50%

---

## Troubleshooting

### Common Issues

#### 1. ECS Tasks Not Starting

**Symptoms**: Tasks stuck in PENDING state

**Solutions**:
```bash
# Check task definition
aws ecs describe-task-definition \
  --task-definition recipe-app-dev-api \
  --region eu-west-2

# Check service events
aws ecs describe-services \
  --cluster recipe-app-dev-cluster \
  --services recipe-app-dev-api \
  --region eu-west-2

# Check CloudWatch logs
aws logs tail /aws/ecs/recipe-app-dev-api --region eu-west-2
```

#### 2. Database Connection Issues

**Symptoms**: Application can't connect to RDS

**Solutions**:
- Verify security group allows port 5432 from ECS security group
- Check RDS endpoint is correct
- Verify database credentials
- Check VPC connectivity

#### 3. Health Check Failures

**Symptoms**: ALB shows targets as unhealthy

**Solutions**:
```bash
# Check health check endpoint
curl https://api.dev.yourdomain.com/api/health-check/

# Check target group health
aws elbv2 describe-target-health \
  --target-group-arn TARGET_GROUP_ARN \
  --region eu-west-2
```

#### 4. SSL Certificate Issues

**Symptoms**: Certificate validation pending

**Solutions**:
- Check Route53 DNS records for validation
- Verify domain ownership
- Wait for ACM validation (can take 30+ minutes)

#### 5. EFS Mount Issues

**Symptoms**: Cannot write to EFS volumes

**Solutions**:
- Verify EFS security group allows NFS (port 2049)
- Check EFS mount targets are in correct subnets
- Verify ECS task has correct permissions

### Debugging Commands

```bash
# Get ECS task ID
aws ecs list-tasks --cluster recipe-app-dev-cluster --region eu-west-2

# Execute command in container
aws ecs execute-command \
  --cluster recipe-app-dev-cluster \
  --task TASK_ID \
  --container api \
  --interactive \
  --command "/bin/sh" \
  --region eu-west-2

# View recent service events
aws ecs describe-services \
  --cluster recipe-app-dev-cluster \
  --services recipe-app-dev-api \
  --query 'services[0].events[:5]' \
  --region eu-west-2
```

---

## API Documentation

### Health Check
```
GET /api/health-check/
```

**Response**:
```json
{
  "status": "healthy",
  "database": "connected"
}
```

### Recipe API Endpoints

- `GET /api/recipe/recipes/` - List recipes
- `POST /api/recipe/recipes/` - Create recipe
- `GET /api/recipe/recipes/{id}/` - Get recipe
- `PUT /api/recipe/recipes/{id}/` - Update recipe
- `DELETE /api/recipe/recipes/{id}/` - Delete recipe

### Authentication

The API uses token-based authentication. Obtain a token via:
```
POST /api/user/token/
```

Include token in requests:
```
Authorization: Token YOUR_TOKEN_HERE
```

---

## Review & Suggestions

For detailed code review, security recommendations, and improvement suggestions, see:
**[REVIEW-AND-SUGGESTIONS.md](REVIEW-AND-SUGGESTIONS.md)**

Key areas covered:
- Security improvements
- Best practices
- Configuration management
- Monitoring enhancements
- Cost optimization
- Documentation improvements

---

## Additional Resources

### Documentation
- [Django Documentation](https://docs.djangoproject.com/)
- [Django REST Framework](https://www.django-rest-framework.org/)
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

### Related Projects
- [Monitoring Stack](../Monitoring-Project/) - Jenkins, Prometheus, Grafana

---

## License

See [LICENSE](LICENSE) file for details.

---

## Support

For issues, questions, or contributions:
1. Check [Troubleshooting](#troubleshooting) section
2. Review [REVIEW-AND-SUGGESTIONS.md](REVIEW-AND-SUGGESTIONS.md)
3. Check CloudWatch logs
4. Review Terraform state and outputs

---

**Last Updated**: 2025-01-26

