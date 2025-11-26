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
