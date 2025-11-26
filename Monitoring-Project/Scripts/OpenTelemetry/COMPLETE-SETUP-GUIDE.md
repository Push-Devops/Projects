# Complete OpenTelemetry Setup Guide for Jenkins

This guide provides complete step-by-step instructions to set up OpenTelemetry tracing for Jenkins pipelines with export to Grafana Tempo and Jaeger.

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Step 1: Install OpenTelemetry Collector](#step-1-install-opentelemetry-collector)
5. [Step 2: Configure OpenTelemetry Collector](#step-2-configure-opentelemetry-collector)
6. [Step 3: Install Jenkins OpenTelemetry Plugin](#step-3-install-jenkins-opentelemetry-plugin)
7. [Step 4: Configure Jenkins for OpenTelemetry](#step-4-configure-jenkins-for-opentelemetry)
8. [Step 5: Create Instrumented Pipeline](#step-5-create-instrumented-pipeline)
9. [Step 6: Configure Grafana Tempo](#step-6-configure-grafana-tempo)
10. [Step 7: Configure Jaeger](#step-7-configure-jaeger)
11. [Verification](#verification)
12. [Troubleshooting](#troubleshooting)

---

## Overview

This setup enables complete observability of your Jenkins CI/CD pipelines by:

- **Installing OpenTelemetry Collector** on the VM to receive and process traces
- **Instrumenting Jenkins pipelines** to export spans for each pipeline stage
- **Exporting traces** to both Grafana Tempo (long-term storage) and Jaeger (real-time viewing)
- **Tracking pipeline stages**: Job start, SCM checkout, Build, Test, and Artifact upload

## Architecture

```
┌─────────────────┐
│ Jenkins Pipeline│
│                 │
│  - Job Start    │
│  - SCM Checkout │
│  - Build Step   │
│  - Test Step    │
│  - Artifact Up. │
└────────┬────────┘
         │
         │ Spans (OTLP)
         ↓
┌─────────────────────────────┐
│ OpenTelemetry Collector     │
│                             │
│ Receivers:                  │
│  - gRPC: :4317              │
│  - HTTP: :4318              │
│                             │
│ Exporters:                  │
│  - Grafana Tempo            │
│  - Jaeger                   │
└────────┬───────────┬────────┘
         │           │
         ↓           ↓
┌──────────────┐  ┌──────────┐
│ Grafana Tempo│  │  Jaeger  │
│              │  │          │
│ Long-term    │  │ Real-time│
│ Storage      │  │ Viewing  │
└──────────────┘  └──────────┘
```

## Prerequisites

- **Jenkins** installed and running
- **Root/sudo access** on the VM
- **Network connectivity** to Tempo and Jaeger endpoints (if remote)
- **Ports available**: 4317 (gRPC), 4318 (HTTP) for OTel Collector
- **Grafana Tempo** running (or access to remote instance)
- **Jaeger** running (or access to remote instance)

---

## Step 1: Install OpenTelemetry Collector

The OpenTelemetry Collector will receive traces from Jenkins and export them to Tempo and Jaeger.

### Installation

```bash
# From the Monitoring-Project directory
cd Monitoring-Project

# Install OTel Collector
sudo bash Scripts/OpenTelemetry/install-otel-collector.sh
```

### What This Does

- Downloads OpenTelemetry Collector binary
- Creates `otelcol` system user
- Installs collector to `/opt/otelcol/`
- Creates systemd service
- Configures default endpoints (4317 gRPC, 4318 HTTP)
- Starts the collector service

### Verification

```bash
# Check service status
sudo systemctl status otelcol

# Verify ports are listening
sudo ss -tlnp | grep -E ':(4317|4318)'

# Check logs
sudo journalctl -u otelcol -f
```

**Expected Output:**
- Service status: `active (running)`
- Ports 4317 and 4318 should be LISTENING
- No errors in logs

---

## Step 2: Configure OpenTelemetry Collector

Configure the collector to export traces to Grafana Tempo and Jaeger.

### For Local Instances

```bash
# From Monitoring-Project directory
cd Monitoring-Project

sudo bash Scripts/OpenTelemetry/configure-otel-collector.sh \
  --tempo-endpoint localhost:4317 \
  --jaeger-endpoint localhost:14250 \
  --jaeger-ui http://localhost:16686
```

### For Remote Instances

```bash
# From Monitoring-Project directory
cd Monitoring-Project

sudo bash Scripts/OpenTelemetry/configure-otel-collector.sh \
  --tempo-endpoint tempo.example.com:4317 \
  --jaeger-endpoint jaeger.example.com:14250 \
  --jaeger-ui http://jaeger.example.com:16686
```

### What This Does

- Updates `/etc/otelcol/config.yaml`
- Configures receivers for OTLP (gRPC and HTTP)
- Sets up exporters for Tempo and Jaeger
- Configures batch processing and memory limits
- Adds resource attributes
- Restarts the collector service

### Configuration File Location

The configuration is stored at: `/etc/otelcol/config.yaml`

### Verification

```bash
# Validate configuration
sudo /opt/otelcol/otelcol --config=/etc/otelcol/config.yaml --dry-run

# Check service restarted successfully
sudo systemctl status otelcol

# View configuration
sudo cat /etc/otelcol/config.yaml
```

---

## Step 3: Install Jenkins OpenTelemetry Plugin

Install the OpenTelemetry plugin in Jenkins to enable trace export.

### Automated Installation

```bash
# From Monitoring-Project directory
cd Monitoring-Project

sudo bash Scripts/OpenTelemetry/install-opentelemetry-plugin.sh
```

### Manual Installation via UI

1. **Access Jenkins:**
   ```
   http://your-jenkins-ip:8080
   ```

2. **Navigate to Plugin Manager:**
   - Go to: `Manage Jenkins` → `Manage Plugins`

3. **Install Plugin:**
   - Click: `Available` tab
   - Search: `OpenTelemetry`
   - Select: `OpenTelemetry` plugin
   - Click: `Install without restart`

4. **Restart Jenkins:**
   - After installation, restart Jenkins if prompted

### What This Does

- Downloads Jenkins CLI
- Installs OpenTelemetry plugin via CLI
- Waits for Jenkins restart
- Verifies plugin installation

### Verification

```bash
# Check plugin is installed
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080 \
  -auth admin:YOUR_PASSWORD \
  list-plugins | grep -i opentelemetry
```

**Expected Output:**
```
opentelemetry:2.x.x
```

---

## Step 4: Configure Jenkins for OpenTelemetry

Configure Jenkins to send traces to the OpenTelemetry Collector.

### Automated Configuration

```bash
# From Monitoring-Project directory
cd Monitoring-Project

sudo bash Scripts/OpenTelemetry/configure-opentelemetry.sh \
  --endpoint http://localhost:4318 \
  --service-name jenkins-pipelines
```

### Manual Configuration via UI

1. **Access Configuration:**
   - Go to: `Manage Jenkins` → `Configure System`

2. **Find OpenTelemetry Section:**
   - Scroll to: `OpenTelemetry` section

3. **Configure Settings:**
   - **Endpoint**: `http://localhost:4318/v1/traces`
   - **Service Name**: `jenkins-pipelines`
   - **Enable**: ✓ Check this box

4. **Save:**
   - Click: `Save` button

### Configuration Options

- **Endpoint**: OTel Collector HTTP endpoint (default: `http://localhost:4318/v1/traces`)
- **Service Name**: Name for your Jenkins service (default: `jenkins-pipelines`)
- **Sampling Rate**: Percentage of traces to export (0.0 to 1.0)

### What This Does

- Updates Jenkins OpenTelemetry plugin configuration
- Sets the collector endpoint
- Configures service name
- Enables trace export

### Verification

1. **Via UI:**
   - Go to: `Manage Jenkins` → `Configure System`
   - Verify OpenTelemetry section shows your configuration

2. **Via Script:**
   ```bash
   sudo bash test-opentelemetry.sh
   ```

---

## Step 5: Create Instrumented Pipeline

Create a Jenkins pipeline that exports spans for each stage.

### Option 1: Simple Pipeline

Use the provided example pipeline:

1. **Create New Pipeline Job:**
   - Go to: Jenkins → `New Item`
   - Name: `otel-test-pipeline`
   - Type: `Pipeline`
   - Click: `OK`

2. **Add Pipeline Script:**
   - Open: `Scripts/OpenTelemetry/jenkins-pipeline-example.groovy`
   - Copy entire contents
   - Paste into: Pipeline Script section
   - Click: `Save`

3. **Run Pipeline:**
   - Click: `Build Now`
   - Wait for completion

### Option 2: Advanced Pipeline

For detailed tracing with metadata:

1. Create pipeline job as above
2. Use `Scripts/OpenTelemetry/jenkins-pipeline-advanced.groovy` instead
3. This includes:
   - Detailed span attributes
   - Performance metrics
   - Custom metadata
   - Parallel execution tracking

### Pipeline Spans Created

Each pipeline automatically creates spans for:

1. **Job Start Span**
   - Duration: Entire pipeline execution
   - Attributes: Job name, build number, parameters

2. **SCM Checkout Span**
   - Duration: Checkout operation time
   - Attributes: Git commit, branch, author, message

3. **Build Span**
   - Duration: Build process time
   - Attributes: Build type, environment, version

4. **Test Span**
   - Duration: Test execution time
   - Attributes: Test count, pass/fail counts

5. **Artifact Upload Span**
   - Duration: Upload time
   - Attributes: Artifact names, sizes

### Custom Pipeline Example

You can create your own pipeline using this template:

```groovy
pipeline {
    agent any
    
    environment {
        OTEL_SERVICE_NAME = 'my-jenkins-pipeline'
    }
    
    stages {
        stage('My Stage') {
            steps {
                script {
                    echo "This creates a span automatically"
                }
            }
        }
    }
}
```

---

## Step 6: Configure Grafana Tempo

Set up Grafana Tempo to receive traces from OTel Collector.

### Option 1: Local Tempo Instance

If running Tempo locally:

1. **Deploy Tempo:**
   ```bash
   docker run -d \
     --name tempo \
     -p 4317:4317 \
     -p 4318:4318 \
     grafana/tempo:latest
   ```

2. **Verify Configuration:**
   - Collector should already be configured if using localhost
   - Check: `configure-otel-collector.sh` used `localhost:4317`

### Option 2: Remote Tempo Instance

1. **Get Tempo Endpoint:**
   - Contact your Tempo administrator
   - Get endpoint: `tempo.example.com:4317`

2. **Update Collector Config:**
   ```bash
   sudo bash configure-otel-collector.sh \
     --tempo-endpoint tempo.example.com:4317
   ```

### Option 3: Grafana Cloud Tempo

1. **Get Cloud Endpoint:**
   - Log in to Grafana Cloud
   - Navigate to: Tempo → Settings
   - Copy endpoint URL

2. **Configure with Authentication:**
   - Update `/etc/otelcol/config.yaml`
   - Add API key in headers section

### Verification

Traces should appear in Tempo after running a Jenkins pipeline.

---

## Step 7: Configure Jaeger

Set up Jaeger to receive traces from OTel Collector.

### Option 1: Local Jaeger Instance

Deploy Jaeger All-in-One:

```bash
docker run -d \
  --name jaeger \
  -p 16686:16686 \
  -p 14250:14250 \
  -p 4317:4317 \
  jaegertracing/all-in-one:latest
```

Access Jaeger UI: `http://localhost:16686`

### Option 2: Remote Jaeger Instance

1. **Get Jaeger Endpoint:**
   - Contact your Jaeger administrator
   - Get endpoint: `jaeger.example.com:14250`

2. **Update Collector Config:**
   ```bash
   sudo bash configure-otel-collector.sh \
     --jaeger-endpoint jaeger.example.com:14250 \
     --jaeger-ui http://jaeger.example.com:16686
   ```

### Verification

1. **Access Jaeger UI:**
   ```
   http://your-jaeger-host:16686
   ```

2. **Search for Traces:**
   - Service: `jenkins-pipelines`
   - Click: `Find Traces`
   - Traces should appear after running a pipeline

---

## Verification

### Quick Verification

Run the comprehensive test script:

```bash
# From Monitoring-Project directory
cd Monitoring-Project

# Test complete setup
sudo bash Scripts/OpenTelemetry/test-complete-setup.sh
```

### Manual Verification Steps

1. **Verify OTel Collector:**
   ```bash
   sudo systemctl status otelcol
   sudo ss -tlnp | grep -E ':(4317|4318)'
   ```

2. **Verify Jenkins Plugin:**
   ```bash
   java -jar /tmp/jenkins-cli.jar -s http://localhost:8080 \
     -auth admin:YOUR_PASSWORD \
     list-plugins | grep opentelemetry
   ```

3. **Run Test Pipeline:**
   - Create and run a test pipeline
   - Check traces appear in Jaeger/Tempo

4. **View Traces:**
   - Jaeger: `http://localhost:16686`
   - Grafana: Query Tempo data source

---

## Troubleshooting

### OTel Collector Not Starting

**Problem:** Service fails to start

**Solution:**
```bash
# Check logs
sudo journalctl -u otelcol -n 50

# Validate config
sudo /opt/otelcol/otelcol --config=/etc/otelcol/config.yaml --dry-run

# Check permissions
ls -la /opt/otelcol/otelcol
sudo chown otelcol:otelcol /opt/otelcol/otelcol
```

### Jenkins Not Sending Traces

**Problem:** Traces not appearing in collector

**Solution:**
1. Verify plugin is installed: `list-plugins | grep opentelemetry`
2. Check configuration: `Configure System → OpenTelemetry`
3. Verify endpoint is accessible: `curl http://localhost:4318/v1/traces`
4. Check Jenkins logs: `/var/log/jenkins/jenkins.log`

### Traces Not in Jaeger/Tempo

**Problem:** Traces received but not exported

**Solution:**
1. Check collector logs: `sudo journalctl -u otelcol -f`
2. Verify exporter endpoints are correct
3. Test connectivity: `telnet tempo-host 4317`
4. Check collector config: `sudo cat /etc/otelcol/config.yaml`

### High Memory Usage

**Problem:** Collector using too much memory

**Solution:**
1. Adjust memory limits in config:
   ```yaml
   processors:
     memory_limiter:
       limit_mib: 1024
   ```
2. Enable sampling to reduce volume
3. Increase batch sizes

### Pipeline Not Creating Spans

**Problem:** Pipeline runs but no spans

**Solution:**
1. Verify OpenTelemetry plugin is enabled
2. Check pipeline script has proper structure
3. Ensure service name is set in environment
4. Check Jenkins logs for errors

---

## Configuration Reference

### OTel Collector Config Location

`/etc/otelcol/config.yaml`

### Jenkins Configuration

Location: `Manage Jenkins` → `Configure System` → `OpenTelemetry`

### Environment Variables

You can set these in Jenkins pipeline:

```groovy
environment {
    OTEL_SERVICE_NAME = 'jenkins-pipeline'
    OTEL_RESOURCE_ATTRIBUTES = 'service.name=jenkins,team=devops'
}
```

---

## Next Steps

After completing the setup:

1. **Create Dashboards:** Build Grafana dashboards for pipeline metrics
2. **Set Up Alerts:** Alert on failed builds, long durations
3. **Optimize Sampling:** Adjust sampling rates based on volume
4. **Add More Attributes:** Enhance spans with custom metadata
5. **Monitor Performance:** Track collector and export performance

---

## Additional Resources

- [OpenTelemetry Documentation](https://opentelemetry.io/docs/)
- [Jenkins OpenTelemetry Plugin](https://plugins.jenkins.io/opentelemetry/)
- [Grafana Tempo Documentation](https://grafana.com/docs/tempo/latest/)
- [Jaeger Documentation](https://www.jaegertracing.io/docs/)

---

## Quick Command Reference

```bash
# From Monitoring-Project directory
cd Monitoring-Project

# Install Collector
sudo bash Scripts/OpenTelemetry/install-otel-collector.sh

# Configure Collector
sudo bash Scripts/OpenTelemetry/configure-otel-collector.sh --tempo-endpoint tempo:4317 --jaeger-endpoint jaeger:14250

# Install Plugin
sudo bash Scripts/OpenTelemetry/install-opentelemetry-plugin.sh

# Configure Jenkins
sudo bash Scripts/OpenTelemetry/configure-opentelemetry.sh --endpoint http://localhost:4318

# Test Setup
sudo bash Scripts/OpenTelemetry/test-complete-setup.sh
```

---

**Last Updated:** 2025-01-26

