# Dependency Check - All Script References

This document lists all script files and their locations to ensure dependencies are intact after file reorganization.

## Script Locations

### Initial Setup Scripts
Location: `Scripts/initial-setup-scripts/`

- ✅ `install-stack.sh` - Main installation script for Jenkins, Prometheus, Grafana
- ✅ `quick-test.sh` - Quick validation script
- ✅ `diagnose-installation.sh` - Troubleshooting/diagnostic script
- ✅ `validate-jenkins-metrics.sh` - Jenkins metrics validation
- ✅ `MANUAL-JENKINS-EXPORTER-INSTALL.md` - Manual exporter installation guide

### Custom Metrics Scripts
Location: `Scripts/custom-metrics/`

- ✅ `add-custom-jenkins-metrics.groovy` - Groovy script for custom metrics
- ✅ `CUSTOM-JENKINS-METRICS-GUIDE.md` - Complete guide
- ✅ `test-custom-metrics.sh` - Test script

### OpenTelemetry Scripts
Location: `Scripts/OpenTelemetry/`

- ✅ `install-otel-collector.sh` - Install OTel Collector
- ✅ `configure-otel-collector.sh` - Configure collector
- ✅ `install-opentelemetry-plugin.sh` - Install Jenkins plugin
- ✅ `configure-opentelemetry.sh` - Configure Jenkins
- ✅ `test-otel-collector.sh` - Test collector
- ✅ `test-opentelemetry.sh` - Test plugin
- ✅ `test-complete-setup.sh` - End-to-end test
- ✅ `jenkins-pipeline-example.groovy` - Simple pipeline
- ✅ `jenkins-pipeline-advanced.groovy` - Advanced pipeline
- ✅ `COMPLETE-SETUP-GUIDE.md` - Setup guide
- ✅ `TESTING-GUIDE.md` - Testing guide
- ✅ `INSTALL-OPENTELEMETRY-PLUGIN.md` - Plugin guide
- ✅ `JENKINS-OTEL-SETUP.md` - Quick reference
- ✅ `README.md` - Folder overview

## Path References

All scripts should be referenced with full paths from `Monitoring-Project/` directory:

### Initial Setup Scripts
```bash
Scripts/initial-setup-scripts/install-stack.sh
Scripts/initial-setup-scripts/quick-test.sh
Scripts/initial-setup-scripts/diagnose-installation.sh
Scripts/initial-setup-scripts/validate-jenkins-metrics.sh
```

### Custom Metrics
```bash
Scripts/custom-metrics/add-custom-jenkins-metrics.groovy
Scripts/custom-metrics/test-custom-metrics.sh
```

### OpenTelemetry
```bash
Scripts/OpenTelemetry/install-otel-collector.sh
Scripts/OpenTelemetry/configure-otel-collector.sh
Scripts/OpenTelemetry/install-opentelemetry-plugin.sh
Scripts/OpenTelemetry/configure-opentelemetry.sh
Scripts/OpenTelemetry/test-otel-collector.sh
Scripts/OpenTelemetry/test-opentelemetry.sh
Scripts/OpenTelemetry/test-complete-setup.sh
```

## Cross-References

Scripts that reference other scripts:

### install-stack.sh references:
- None (standalone)

### quick-test.sh references:
- None (standalone)

### OpenTelemetry scripts reference:
- Other OpenTelemetry scripts (all paths use `Scripts/OpenTelemetry/`)

## Documentation References

### README.md
- References: `Monitoring-Project/Scripts/custom-metrics/`
- References: `Monitoring-Project/JENKINS-PROMETHEUS-SETUP.md`
- References: `Monitoring-Project/TESTING-GUIDE.md`

### TESTING-GUIDE.md
- Should reference: `Scripts/initial-setup-scripts/` scripts if needed

### JENKINS-PROMETHEUS-SETUP.md
- Should reference: `Scripts/initial-setup-scripts/install-stack.sh` if needed

## Verification Checklist

- [ ] All script paths use consistent format: `Scripts/<folder>/<script>`
- [ ] No broken references to moved files
- [ ] All guides reference correct script locations
- [ ] Scripts in folders can reference each other correctly

