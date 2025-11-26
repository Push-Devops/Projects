# OpenTelemetry Setup for Jenkins

This folder contains all scripts, guides, and examples for setting up OpenTelemetry tracing in Jenkins pipelines.

## Quick Start

1. **Read the Complete Setup Guide:**
   - [COMPLETE-SETUP-GUIDE.md](COMPLETE-SETUP-GUIDE.md) - Step-by-step setup instructions

2. **Follow the Testing Guide:**
   - [TESTING-GUIDE.md](TESTING-GUIDE.md) - Test each component step-by-step

## File Structure

```
OpenTelemetry/
├── COMPLETE-SETUP-GUIDE.md          # Complete setup instructions
├── TESTING-GUIDE.md                  # Step-by-step testing procedures
├── INSTALL-OPENTELEMETRY-PLUGIN.md  # Plugin installation guide
├── JENKINS-OTEL-SETUP.md            # Quick reference guide
├── README.md                         # This file
│
├── install-otel-collector.sh        # Install OTel Collector
├── configure-otel-collector.sh      # Configure collector for Tempo/Jaeger
├── install-opentelemetry-plugin.sh  # Install Jenkins plugin
├── configure-opentelemetry.sh       # Configure Jenkins
│
├── test-otel-collector.sh           # Test collector installation
├── test-opentelemetry.sh            # Test plugin installation
├── test-complete-setup.sh           # End-to-end test
│
├── jenkins-pipeline-example.groovy  # Simple pipeline example
└── jenkins-pipeline-advanced.groovy # Advanced pipeline example
```

## Installation Order

1. **Install OTel Collector:**
   ```bash
   cd Monitoring-Project
   sudo bash Scripts/OpenTelemetry/install-otel-collector.sh
   ```

2. **Configure Collector:**
   ```bash
   sudo bash Scripts/OpenTelemetry/configure-otel-collector.sh \
     --tempo-endpoint localhost:4317 \
     --jaeger-endpoint localhost:14250
   ```

3. **Install Jenkins Plugin:**
   ```bash
   sudo bash Scripts/OpenTelemetry/install-opentelemetry-plugin.sh
   ```

4. **Configure Jenkins:**
   ```bash
   sudo bash Scripts/OpenTelemetry/configure-opentelemetry.sh \
     --endpoint http://localhost:4318
   ```

5. **Test Everything:**
   ```bash
   sudo bash Scripts/OpenTelemetry/test-complete-setup.sh
   ```

## Pipeline Examples

- **Simple Pipeline:** Copy content from `jenkins-pipeline-example.groovy`
- **Advanced Pipeline:** Copy content from `jenkins-pipeline-advanced.groovy`

Both pipelines export spans for:
- Job start
- SCM checkout
- Build step
- Test step
- Artifact upload

## Viewing Traces

- **Jaeger UI:** `http://localhost:16686` (or your Jaeger host)
- **Grafana Tempo:** Query via Grafana using Tempo data source

## Documentation

- **[COMPLETE-SETUP-GUIDE.md](COMPLETE-SETUP-GUIDE.md)** - Complete setup with all steps
- **[TESTING-GUIDE.md](TESTING-GUIDE.md)** - Detailed testing procedures
- **[INSTALL-OPENTELEMETRY-PLUGIN.md](INSTALL-OPENTELEMETRY-PLUGIN.md)** - Plugin-specific guide

## Troubleshooting

See the troubleshooting sections in:
- COMPLETE-SETUP-GUIDE.md (general troubleshooting)
- TESTING-GUIDE.md (test-specific issues)

## Support

For issues or questions, refer to:
1. The guides in this folder
2. Jenkins logs: `/var/log/jenkins/jenkins.log`
3. Collector logs: `sudo journalctl -u otelcol -f`

