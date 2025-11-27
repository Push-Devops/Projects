# Production-Level Blue-Green Deployment CI/CD Pipeline

## Scenario

Upgrade an application with new features while ensuring zero downtime by redirecting traffic from the blue to the green deployment. In case of issues, revert changes from Green back to Blue.

## Tools Used

- **EKS Cluster Deployment using Terraform**
- **SonarQube** (Code Quality and Security Analysis)
- **Nexus** (Artifact Repository)
- **Jenkins** (CI/CD Pipeline)

## Implementation Walkthrough

### Select Deployment Environment
- Ensure traffic switch capabilities are configured.
- Define security group port settings.
- Select the environment in which we want to deploy and make sure to check switch traffic.

**Security Group Port:**

### Step 1: Create Master Server (Ubuntu) for EKS Cluster

1. **Update System**
   ```bash
   sudo apt update

### Establish AWS CLI Connection

Configure AWS CLI with your AWS credentials and region.

```bash
aws configure
