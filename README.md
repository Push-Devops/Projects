# Infrastructure & Monitoring Projects

A collection of infrastructure and monitoring projects using Terraform, AWS, and modern DevOps tools. Each project is self-contained in its own folder with comprehensive documentation and automation scripts.

## Projects Overview

### 🚀 [Monitoring Stack](Monitoring-Project/)
**Jenkins CI/CD Monitoring with Prometheus & Grafana**

A comprehensive monitoring solution for Jenkins CI/CD pipelines deployed on AWS. Includes Jenkins with Prometheus metrics, Prometheus time-series database, and Grafana dashboards for CI/CD visibility.

**Key Features:**
- Custom VPC with EC2 instance
- Automated Jenkins, Prometheus, and Grafana installation
- Jenkins Prometheus Metrics Plugin integration
- Custom metrics support
- Pre-configured CI/CD dashboards

**Quick Links:**
- [Setup Guide](Monitoring-Project/JENKINS-PROMETHEUS-SETUP.md)
- [Testing Guide](Monitoring-Project/TESTING-GUIDE.md)
- [Custom Metrics Guide](Monitoring-Project/Scripts/custom-metrics/CUSTOM-JENKINS-METRICS-GUIDE.md)
- [Installation Script](Monitoring-Project/Scripts/initial-setup-scripts/install-stack.sh)
- [Quick Test Script](Monitoring-Project/Scripts/initial-setup-scripts/quick-test.sh)

---

### 🐳 [AWS ECS Project](AWS-ECS-PROJECT/)
**Django REST API on AWS ECS Fargate**

A production-ready Django REST API application deployed on AWS ECS Fargate with RDS PostgreSQL, Application Load Balancer, and EFS for persistent storage.

**Key Features:**
- ECS Fargate cluster with multi-container tasks
- RDS PostgreSQL database
- Application Load Balancer with Route53 DNS
- EFS for persistent media/static storage
- VPC with public/private subnets
- VPC endpoints for ECR, CloudWatch, SSM
- CloudWatch logging and monitoring
- Terraform infrastructure as code

**Quick Links:**
- [Project README](AWS-ECS-PROJECT/README.md)
- [Review & Suggestions](AWS-ECS-PROJECT/REVIEW-AND-SUGGESTIONS.md)

---

### 🔵🟢 [Blue-Green Deployment](Blue-green-Deployment/)
**Production-Level Blue-Green Deployment CI/CD Pipeline**

A complete blue-green deployment solution for zero-downtime application upgrades on AWS EKS. Includes automated CI/CD pipeline with Jenkins, SonarQube code quality analysis, Trivy security scanning, and Nexus artifact repository.

**Key Features:**
- AWS EKS cluster deployment using Terraform
- Blue-Green deployment strategy for zero downtime
- Jenkins CI/CD pipeline with automated testing
- SonarQube code quality and security analysis
- Trivy vulnerability scanning (filesystem and container images)
- Nexus artifact repository integration
- Spring Boot banking application example
- MySQL database deployment
- Traffic switching between blue and green environments
- Kubernetes RBAC configuration
- Prometheus monitoring setup

**Quick Links:**
- [Project README](Blue-green-Deployment/README.md)
- [RBAC Setup Guide](Blue-green-Deployment/Setup-RBAC.md)
- [EKS Cluster Terraform](Blue-green-Deployment/Cluster/)

---

### 🏗️ [Three-Layer Terraform Architecture](Three-Layer-Terr-AWS-Code/)
**Production-Ready Modular Terraform Infrastructure**

A comprehensive three-layer Terraform architecture following best practices for AWS infrastructure management. Demonstrates modular design with resource modules, infrastructure modules, and composition layers for scalable, maintainable infrastructure as code.

**Key Features:**
- Three-layer architecture pattern (Resource → Infrastructure → Composition)
- Remote backend with S3, DynamoDB, and KMS encryption
- VPC infrastructure with public, private, and database subnets
- Security groups with configurable ingress rules
- EKS-ready VPC configuration
- Multi-environment support (dev, staging, prod)
- Modular and reusable components
- Best practices for Terraform organization
- Customer-managed KMS keys for encryption
- State locking with DynamoDB

**Quick Links:**
- [Project README](Three-Layer-Terr-AWS-Code/README.md)
- [Remote Backend Module](Three-Layer-Terr-AWS-Code/remote_backend/)
- [VPC Infrastructure](Three-Layer-Terr-AWS-Code/VPC-Infra/)

---

### ⚙️ [AWS EKS Project](EKS-Project/) - *Coming Soon*
**Kubernetes Cluster on AWS EKS**

Deploy and manage Kubernetes clusters on AWS Elastic Kubernetes Service (EKS) with Terraform.

**Planned Features:**
- EKS cluster provisioning
- Node groups configuration
- Networking setup (VPC, subnets, security groups)
- Cluster monitoring and logging
- Application deployment examples

---

## Repository Structure

```
.
├── Monitoring-Project/           # Jenkins monitoring stack
│   ├── main.tf                   # Terraform infrastructure
│   ├── variables.tf              # Input variables
│   ├── outputs.tf                # Output values
│   ├── terraform.tfvars          # Variable values
│   ├── JENKINS-PROMETHEUS-SETUP.md
│   ├── TESTING-GUIDE.md
│   └── Scripts/                  # Installation & testing scripts
│       ├── initial-setup-scripts/    # Main installation scripts
│       ├── custom-metrics/           # Custom Jenkins metrics
│       └── OpenTelemetry/            # OpenTelemetry setup
│
├── AWS-ECS-PROJECT/              # Django API on ECS Fargate
│   ├── app/                      # Django application
│   ├── infra/                    # Terraform infrastructure
│   │   ├── setup/                # Initial setup (ECR, IAM)
│   │   └── deploy/               # Main deployment (ECS, RDS, ALB)
│   ├── proxy/                    # Nginx proxy container
│   └── README.md
│
├── Blue-green-Deployment/       # Blue-Green Deployment on EKS
│   ├── Cluster/                  # EKS Terraform infrastructure
│   │   ├── main.tf               # EKS cluster, VPC, networking
│   │   ├── variables.tf          # Terraform variables
│   │   ├── output.tf             # Cluster outputs
│   │   └── monitor/              # Prometheus configuration
│   ├── src/                      # Spring Boot application
│   ├── Jenkinsfile               # CI/CD pipeline definition
│   ├── Dockerfile                # Application container
│   ├── app-deployment-blue.yml   # Blue environment deployment
│   ├── app-deployment-green.yml  # Green environment deployment
│   ├── mysql-ds.yml              # MySQL database deployment
│   ├── bankapp-service.yml      # Kubernetes service
│   ├── Setup-RBAC.md             # RBAC configuration guide
│   └── README.md
│
├── Three-Layer-Terr-AWS-Code/   # Three-Layer Terraform Architecture
│   ├── remote_backend/          # Remote Backend Infrastructure
│   │   ├── composition/         # Environment compositions
│   │   ├── infra_modules/        # Infrastructure modules
│   │   └── resource_modules/     # Resource modules
│   ├── VPC-Infra/                # VPC Infrastructure
│   │   ├── composition/          # Environment compositions
│   │   ├── infra_modules/         # Infrastructure modules
│   │   └── resource_modules/     # Resource modules
│   └── README.md
│
├── EKS-Project/                  # AWS EKS cluster (future)
│   └── ...
│
└── README.md                     # This file
```

## Getting Started

Each project is independent and can be deployed separately. Navigate to the specific project folder for detailed instructions:

1. **Choose a project** from the list above
2. **Navigate** to the project folder: `cd <Project-Name>`
3. **Follow** the project-specific README or setup guide
4. **Deploy** using Terraform and provided scripts

## Prerequisites

### Common Requirements (All Projects)
- AWS account with appropriate credentials
- Terraform >= 1.0
- AWS CLI configured
- SSH key pair (for EC2-based projects)

### Project-Specific Requirements
- See individual project documentation for specific prerequisites
- Some projects may require additional tools (kubectl, Docker, etc.)

## Project Quick Access

| Project | Description | Status | Documentation |
|---------|-------------|--------|---------------|
| [Monitoring Stack](Monitoring-Project/) | Jenkins + Prometheus + Grafana | ✅ Active | [Setup Guide](Monitoring-Project/JENKINS-PROMETHEUS-SETUP.md) |
| [AWS ECS Project](AWS-ECS-PROJECT/) | Django API on ECS Fargate | ✅ Active | [Project README](AWS-ECS-PROJECT/README.md) |
| [Blue-Green Deployment](Blue-green-Deployment/) | Blue-Green CI/CD on EKS | ✅ Active | [Project README](Blue-green-Deployment/README.md) |
| [Three-Layer Terraform](Three-Layer-Terr-AWS-Code/) | Modular Terraform Architecture | ✅ Active | [Project README](Three-Layer-Terr-AWS-Code/README.md) |
| [EKS Project](EKS-Project/) | AWS EKS Kubernetes Cluster | 🔜 Coming Soon | TBD |

## General Workflow

1. **Review Project Documentation** - Check the project's README or setup guide
2. **Configure Variables** - Update `terraform.tfvars` with your values
3. **Initialize Terraform** - `terraform init`
4. **Plan Changes** - `terraform plan`
5. **Deploy Infrastructure** - `terraform apply`
6. **Run Installation Scripts** - Execute project-specific setup scripts
7. **Validate Deployment** - Use provided testing/validation scripts
8. **Access Services** - Use output URLs/IPs from Terraform

## Clean Up

To destroy a specific project's infrastructure:

```bash
cd <Project-Name>
terraform destroy
```

⚠️ **Warning**: This will destroy all resources created by that project.

## Project Status

- ✅ **Active** - Fully functional and tested
- 🔧 **In Progress** - Under active development
- 🔜 **Coming Soon** - Planned for future development

## Contributing

Each project folder contains:
- Infrastructure code (Terraform)
- Installation scripts
- Documentation
- Testing/validation tools

For project-specific contributions, refer to the individual project's documentation.

## Support & Documentation

Each project includes comprehensive documentation:

- **Setup Guides** - Step-by-step installation instructions
- **Testing Guides** - Validation and testing procedures
- **Troubleshooting** - Common issues and solutions
- **Scripts** - Automated installation and testing tools

Navigate to the project folder and check the documentation files for detailed information.

## Notes

- All projects use Terraform for infrastructure as code
- Each project is designed to be standalone and independent
- Projects may share similar patterns but are not interdependent
- Security best practices are applied across all projects
- Cost considerations are documented in project-specific guides

---

**Last Updated**: 2025-01-26
