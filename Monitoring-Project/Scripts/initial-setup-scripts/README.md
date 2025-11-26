# Initial Setup Scripts

This folder contains scripts for the initial installation and setup of Jenkins, Prometheus, and Grafana.

## Scripts

### Installation
- **`install-stack.sh`** - Complete installation script for Jenkins, Prometheus, and Grafana
  - Installs all services
  - Configures Jenkins Prometheus plugin
  - Sets up Prometheus scraping
  - Configures Grafana data source and dashboards

### Testing & Validation
- **`quick-test.sh`** - Quick validation script for all components
  - Checks service status
  - Verifies ports
  - Tests metrics endpoints
  - Validates Prometheus targets

- **`validate-jenkins-metrics.sh`** - Validates Jenkins metrics are working
  - Checks metrics endpoint
  - Verifies required metrics exist
  - Tests Prometheus queries

- **`diagnose-installation.sh`** - Diagnostic script for troubleshooting
  - Checks cloud-init status
  - Shows service status
  - Displays recent logs
  - Identifies installation issues

### Documentation
- **`MANUAL-JENKINS-EXPORTER-INSTALL.md`** - Manual installation guide for Jenkins Exporter

## Usage

### From Monitoring-Project Directory:

```bash
# Install complete stack
sudo bash Scripts/initial-setup-scripts/install-stack.sh

# Quick test
sudo bash Scripts/initial-setup-scripts/quick-test.sh

# Validate metrics
sudo bash Scripts/initial-setup-scripts/validate-jenkins-metrics.sh

# Diagnose issues
sudo bash Scripts/initial-setup-scripts/diagnose-installation.sh
```

### From Scripts Directory:

```bash
cd Scripts/initial-setup-scripts

# Install stack
sudo bash install-stack.sh

# Quick test
sudo bash quick-test.sh

# Validate metrics
sudo bash validate-jenkins-metrics.sh

# Diagnose
sudo bash diagnose-installation.sh
```

## Dependencies

These scripts are standalone and don't depend on other scripts in this folder. They may reference:
- System packages (apt, systemctl, etc.)
- Jenkins CLI (downloaded automatically)
- Standard Linux utilities

## Related Scripts

- **Custom Metrics:** See `../custom-metrics/` folder
- **OpenTelemetry:** See `../OpenTelemetry/` folder

