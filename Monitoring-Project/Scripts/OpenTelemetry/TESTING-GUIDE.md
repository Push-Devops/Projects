# Step-by-Step Testing Guide for OpenTelemetry Setup

This guide provides comprehensive step-by-step testing procedures for each component of the OpenTelemetry setup.

## Table of Contents

1. [Pre-Testing Checklist](#pre-testing-checklist)
2. [Test 1: OpenTelemetry Collector Installation](#test-1-opentelemetry-collector-installation)
3. [Test 2: OpenTelemetry Collector Configuration](#test-2-opentelemetry-collector-configuration)
4. [Test 3: OpenTelemetry Collector Connectivity](#test-3-opentelemetry-collector-connectivity)
5. [Test 4: Jenkins OpenTelemetry Plugin Installation](#test-4-jenkins-opentelemetry-plugin-installation)
6. [Test 5: Jenkins OpenTelemetry Configuration](#test-5-jenkins-opentelemetry-configuration)
7. [Test 6: Pipeline Span Creation](#test-6-pipeline-span-creation)
8. [Test 7: Trace Export to Collector](#test-7-trace-export-to-collector)
9. [Test 8: Trace Export to Grafana Tempo](#test-8-trace-export-to-grafana-tempo)
10. [Test 9: Trace Export to Jaeger](#test-9-trace-export-to-jaeger)
11. [Test 10: End-to-End Verification](#test-10-end-to-end-verification)
12. [Troubleshooting Common Test Failures](#troubleshooting-common-test-failures)

---

## Pre-Testing Checklist

Before starting tests, verify:

- [ ] Jenkins is installed and running
- [ ] You have sudo/root access
- [ ] Network connectivity is available
- [ ] Required ports are available (4317, 4318)
- [ ] Grafana Tempo is accessible (if using)
- [ ] Jaeger is accessible (if using)

---

## Test 1: OpenTelemetry Collector Installation

**Objective:** Verify OTel Collector is properly installed.

### Automated Test

```bash
sudo bash test-otel-collector.sh
```

### Manual Test Steps

#### Step 1.1: Check Binary Exists

```bash
ls -la /opt/otelcol/otelcol
```

**Expected:** File exists and is executable

**If Failed:**
- Run installation script: `sudo bash install-otel-collector.sh`
- Check for errors during installation

#### Step 1.2: Check Collector Version

```bash
/opt/otelcol/otelcol --version
```

**Expected:** Version number displayed (e.g., `otelcol version v0.100.0`)

#### Step 1.3: Check System User

```bash
id otelcol
```

**Expected:** User `otelcol` exists

**If Failed:**
```bash
sudo useradd -r -s /bin/false -d /opt/otelcol -m otelcol
```

#### Step 1.4: Check Service Status

```bash
sudo systemctl status otelcol
```

**Expected:** Service status shows `active (running)`

**If Failed:**
```bash
sudo systemctl start otelcol
sudo systemctl enable otelcol
```

#### Step 1.5: Check Configuration File

```bash
sudo ls -la /etc/otelcol/config.yaml
```

**Expected:** Configuration file exists

**Result:** ✓ All checks passed → Collector is installed correctly

---

## Test 2: OpenTelemetry Collector Configuration

**Objective:** Verify OTel Collector configuration is valid and correct.

### Automated Test

```bash
sudo /opt/otelcol/otelcol --config=/etc/otelcol/config.yaml --dry-run
```

**Expected:** `Configuration is valid` or similar success message

### Manual Test Steps

#### Step 2.1: Validate Configuration Syntax

```bash
sudo /opt/otelcol/otelcol --config=/etc/otelcol/config.yaml --dry-run 2>&1
```

**Expected:** No errors, configuration validated

**If Failed:**
- Check YAML syntax: `sudo cat /etc/otelcol/config.yaml | grep -v "^#" | grep -v "^$"`
- Validate indentation
- Check for typos in exporter names

#### Step 2.2: Check Receivers Configuration

```bash
sudo grep -A 10 "receivers:" /etc/otelcol/config.yaml
```

**Expected:** OTLP receiver configured with gRPC and HTTP protocols

**Example:**
```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318
```

#### Step 2.3: Check Exporters Configuration

```bash
sudo grep -A 15 "exporters:" /etc/otelcol/config.yaml
```

**Expected:** Exporters for Tempo and Jaeger are configured

**Example:**
```yaml
exporters:
  otlp/tempo:
    endpoint: localhost:4317
  otlp/jaeger:
    endpoint: localhost:14250
```

#### Step 2.4: Check Service Pipeline

```bash
sudo grep -A 10 "service:" /etc/otelcol/config.yaml
```

**Expected:** Traces pipeline includes receivers, processors, and exporters

**Result:** ✓ Configuration is valid and properly set up

---

## Test 3: OpenTelemetry Collector Connectivity

**Objective:** Verify OTel Collector ports are accessible and responding.

### Automated Test

```bash
sudo bash test-otel-collector.sh
```

### Manual Test Steps

#### Step 3.1: Check gRPC Port (4317)

```bash
sudo ss -tlnp | grep 4317
```

**Expected:** Port 4317 is LISTENING

**If Failed:**
```bash
sudo systemctl restart otelcol
sleep 3
sudo ss -tlnp | grep 4317
```

#### Step 3.2: Check HTTP Port (4318)

```bash
sudo ss -tlnp | grep 4318
```

**Expected:** Port 4318 is LISTENING

#### Step 3.3: Test HTTP Endpoint

```bash
curl -v http://localhost:4318/v1/traces -X POST \
  -H "Content-Type: application/json" \
  -d '{}'
```

**Expected:** HTTP response (405 Method Not Allowed or 400 Bad Request is OK - means endpoint is responding)

**If Failed:**
- Check if collector is running: `sudo systemctl status otelcol`
- Check logs: `sudo journalctl -u otelcol -n 20`

#### Step 3.4: Test gRPC Endpoint Connectivity

```bash
timeout 2 bash -c "echo > /dev/tcp/localhost/4317" && echo "Port is open" || echo "Port is closed"
```

**Expected:** `Port is open`

**If Failed:**
- Check firewall: `sudo ufw status`
- Check service: `sudo systemctl status otelcol`

#### Step 3.5: Check Collector Logs

```bash
sudo journalctl -u otelcol -n 20 --no-pager
```

**Expected:** No error messages

**Result:** ✓ All connectivity tests passed

---

## Test 4: Jenkins OpenTelemetry Plugin Installation

**Objective:** Verify OpenTelemetry plugin is installed in Jenkins.

### Automated Test

```bash
sudo bash test-opentelemetry.sh
```

### Manual Test Steps

#### Step 4.1: Check Jenkins is Running

```bash
sudo systemctl status jenkins
curl -I http://localhost:8080
```

**Expected:** Service is active, HTTP returns 200 or 403

#### Step 4.2: Download Jenkins CLI

```bash
wget http://localhost:8080/jnlpJars/jenkins-cli.jar -O /tmp/jenkins-cli.jar
```

**Expected:** File downloaded successfully

#### Step 4.3: Get Jenkins Password

```bash
JENKINS_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo "")
echo "Password retrieved: ${JENKINS_PASSWORD:0:10}..."
```

**Expected:** Password is retrieved

**If Failed:**
- Jenkins may be fully configured - use your admin credentials

#### Step 4.4: List Installed Plugins

```bash
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080 \
  -auth admin:$JENKINS_PASSWORD \
  list-plugins | grep -i opentelemetry
```

**Expected:** Plugin listed (e.g., `opentelemetry:2.x.x`)

**If Failed:**
- Install plugin: `sudo bash install-opentelemetry-plugin.sh`

#### Step 4.5: Verify Plugin in UI

1. Open: `http://your-jenkins-ip:8080`
2. Navigate: `Manage Jenkins` → `Manage Plugins` → `Installed`
3. Search: `opentelemetry`

**Expected:** Plugin appears in installed list

**Result:** ✓ Plugin is installed correctly

---

## Test 5: Jenkins OpenTelemetry Configuration

**Objective:** Verify Jenkins is configured to send traces to OTel Collector.

### Automated Test

```bash
sudo bash test-opentelemetry.sh
```

### Manual Test Steps

#### Step 5.1: Check Configuration via CLI

Create test script:

```bash
cat > /tmp/check-otel-config.groovy <<'EOF'
import jenkins.model.Jenkins
import io.jenkins.plugins.opentelemetry.JenkinsOpenTelemetryPluginConfiguration

try {
    def config = JenkinsOpenTelemetryPluginConfiguration.get()
    println "Enabled: " + config.isEnabled()
    println "Service Name: " + config.getServiceName()
    
    def backend = config.getBackend()
    if (backend != null) {
        println "Backend configured: " + backend.getClass().getSimpleName()
    } else {
        println "Backend: Not configured"
    }
} catch (Exception e) {
    println "Error: " + e.message
}
EOF

java -jar /tmp/jenkins-cli.jar -s http://localhost:8080 \
  -auth admin:$JENKINS_PASSWORD \
  groovy = </tmp/check-otel-config.groovy
```

**Expected:**
- Enabled: `true`
- Service Name: `jenkins-pipelines` (or your configured name)
- Backend configured: `OtlpHttpBackend` or similar

#### Step 5.2: Check Configuration in UI

1. Open: `Manage Jenkins` → `Configure System`
2. Scroll to: `OpenTelemetry` section
3. Verify:
   - ✓ Enabled checkbox is checked
   - Endpoint is set: `http://localhost:4318/v1/traces`
   - Service name is set

**Result:** ✓ Configuration is correct

---

## Test 6: Pipeline Span Creation

**Objective:** Verify Jenkins pipeline creates spans for each stage.

### Test Steps

#### Step 6.1: Create Test Pipeline

1. **Create Pipeline Job:**
   - Jenkins → `New Item`
   - Name: `otel-test-pipeline`
   - Type: `Pipeline`
   - Click: `OK`

#### Step 6.2: Add Minimal Pipeline Script

```groovy
pipeline {
    agent any
    
    environment {
        OTEL_SERVICE_NAME = 'test-pipeline'
    }
    
    stages {
        stage('Test Stage') {
            steps {
                script {
                    echo "This is a test stage"
                }
            }
        }
    }
}
```

#### Step 6.3: Run Pipeline

- Click: `Build Now`
- Wait for completion

#### Step 6.4: Verify Stages Executed

1. Check build history
2. Click on build number
3. Verify all stages completed

**Expected:** All stages show as completed

#### Step 6.5: Check Jenkins Logs

```bash
sudo tail -f /var/log/jenkins/jenkins.log | grep -i opentelemetry
```

**Expected:** Log entries related to OpenTelemetry (if verbose logging enabled)

**Result:** ✓ Pipeline executed successfully

---

## Test 7: Trace Export to Collector

**Objective:** Verify traces are being sent from Jenkins to OTel Collector.

### Test Steps

#### Step 7.1: Monitor Collector Logs

```bash
sudo journalctl -u otelcol -f
```

Keep this running in one terminal.

#### Step 7.2: Run Test Pipeline

Run the test pipeline created in Test 6.

#### Step 7.3: Check Collector Logs

Look for log entries showing:
- Traces received
- Spans processed
- No errors

**Expected Output:**
```
{"level":"info","msg":"Traces received","spans":5}
```

#### Step 7.4: Check Collector Metrics (if available)

```bash
curl http://localhost:8888/metrics 2>/dev/null | grep otelcol
```

**Expected:** Metrics showing received spans

**Result:** ✓ Traces are being exported to collector

---

## Test 8: Trace Export to Grafana Tempo

**Objective:** Verify traces are exported to Grafana Tempo.

### Prerequisites

- Grafana Tempo is running and accessible

### Test Steps

#### Step 8.1: Verify Tempo Connectivity

```bash
# Test Tempo endpoint
telnet tempo-host 4317
# Or
curl -v http://tempo-host:4317
```

**Expected:** Connection successful

#### Step 8.2: Run Test Pipeline

Run a test pipeline in Jenkins.

#### Step 8.3: Query Traces in Tempo

**Option A: Via Grafana**

1. Open Grafana: `http://your-grafana-host:3000`
2. Go to: `Explore`
3. Select: `Tempo` data source
4. Query: `{service.name="jenkins-pipelines"}`
5. Select time range: Last 15 minutes

**Expected:** Traces appear in results

**Option B: Via Tempo API**

```bash
curl "http://tempo-host:3200/api/search?tags=service.name=jenkins-pipelines"
```

**Expected:** JSON response with trace IDs

#### Step 8.4: View Trace Details

1. Click on a trace in Grafana
2. Verify trace contains:
   - Job start span
   - Stage spans
   - Timing information

**Result:** ✓ Traces are in Tempo

---

## Test 9: Trace Export to Jaeger

**Objective:** Verify traces are exported to Jaeger and viewable in UI.

### Prerequisites

- Jaeger is running and accessible

### Test Steps

#### Step 9.1: Verify Jaeger Connectivity

```bash
# Test Jaeger gRPC endpoint
telnet jaeger-host 14250

# Test Jaeger UI
curl -I http://jaeger-host:16686
```

**Expected:** Connections successful

#### Step 9.2: Run Test Pipeline

Run a test pipeline in Jenkins.

#### Step 9.3: Access Jaeger UI

1. Open browser: `http://jaeger-host:16686`
2. Service dropdown: Select `jenkins-pipelines`
3. Click: `Find Traces`

**Expected:** Traces appear in list

#### Step 9.4: Inspect Trace

1. Click on a trace
2. Verify trace timeline shows:
   - Job start
   - SCM checkout
   - Build step
   - Test step
   - Artifact upload

#### Step 9.5: Check Trace Details

1. Expand each span
2. Verify attributes contain:
   - Job name
   - Build number
   - Stage names
   - Timestamps

**Expected:** Complete trace with all stages

**Result:** ✓ Traces are in Jaeger

---

## Test 10: End-to-End Verification

**Objective:** Complete end-to-end test of the entire setup.

### Comprehensive Test

#### Step 10.1: Run Complete Test Script

```bash
sudo bash test-complete-setup.sh
```

This script tests all components automatically.

#### Step 10.2: Manual End-to-End Test

1. **Start Collector Logs:**
   ```bash
   sudo journalctl -u otelcol -f
   ```

2. **Run Complex Pipeline:**
   - Use `jenkins-pipeline-advanced.groovy`
   - Create pipeline job
   - Run it

3. **Verify in Collector:**
   - Check logs show traces received
   - No errors

4. **Verify in Jaeger:**
   - Open Jaeger UI
   - Find trace for your pipeline
   - Verify all spans present

5. **Verify in Tempo (if configured):**
   - Query Tempo in Grafana
   - Find your trace
   - Verify completeness

### Expected Results

- ✅ Collector receives traces
- ✅ Traces exported to Jaeger
- ✅ Traces exported to Tempo (if configured)
- ✅ All pipeline stages have spans
- ✅ Spans have correct timing
- ✅ Attributes are populated

**Result:** ✓ End-to-end test passed

---

## Troubleshooting Common Test Failures

### Collector Service Won't Start

**Symptoms:** `systemctl status otelcol` shows failed

**Solutions:**
1. Check config validity: `sudo /opt/otelcol/otelcol --config=/etc/otelcol/config.yaml --dry-run`
2. Check logs: `sudo journalctl -u otelcol -n 50`
3. Check permissions: `sudo chown otelcol:otelcol /opt/otelcol/otelcol`
4. Check file exists: `ls -la /opt/otelcol/otelcol`

### Ports Not Listening

**Symptoms:** `ss -tlnp | grep 4317` shows nothing

**Solutions:**
1. Restart service: `sudo systemctl restart otelcol`
2. Check config has correct endpoints
3. Check firewall: `sudo ufw status`
4. Check for port conflicts: `sudo lsof -i :4317`

### Jenkins Plugin Not Installing

**Symptoms:** Plugin doesn't appear in list

**Solutions:**
1. Check Jenkins logs: `/var/log/jenkins/jenkins.log`
2. Try manual installation via UI
3. Check internet connectivity
4. Verify Jenkins has plugin permissions

### No Traces in Collector

**Symptoms:** Collector running but no traces received

**Solutions:**
1. Verify Jenkins configuration endpoint is correct
2. Test connectivity: `curl http://localhost:4318/v1/traces`
3. Check Jenkins logs for errors
4. Verify plugin is enabled

### Traces Not in Jaeger/Tempo

**Symptoms:** Traces received but not exported

**Solutions:**
1. Check collector logs for export errors
2. Verify exporter endpoints are correct
3. Test connectivity to Jaeger/Tempo
4. Check exporter configuration in `config.yaml`

### Pipeline Spans Missing

**Symptoms:** Pipeline runs but no spans created

**Solutions:**
1. Verify OpenTelemetry plugin is enabled
2. Check pipeline has proper structure
3. Verify service name is set
4. Check Jenkins logs for plugin errors

---

## Test Summary Checklist

After completing all tests, verify:

- [ ] Test 1: Collector installed ✓
- [ ] Test 2: Collector configured ✓
- [ ] Test 3: Collector connectivity ✓
- [ ] Test 4: Plugin installed ✓
- [ ] Test 5: Jenkins configured ✓
- [ ] Test 6: Pipeline creates spans ✓
- [ ] Test 7: Traces exported to collector ✓
- [ ] Test 8: Traces in Tempo ✓
- [ ] Test 9: Traces in Jaeger ✓
- [ ] Test 10: End-to-end working ✓

**All tests passed?** Your OpenTelemetry setup is complete and working! 🎉

---

## Quick Test Commands

```bash
# Test Collector
sudo bash test-otel-collector.sh

# Test Jenkins Plugin
sudo bash test-opentelemetry.sh

# Test Complete Setup (if available)
sudo bash test-complete-setup.sh
```

---

**Last Updated:** 2025-01-26

