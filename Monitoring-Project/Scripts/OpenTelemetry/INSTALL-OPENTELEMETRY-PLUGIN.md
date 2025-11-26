# Installing OpenTelemetry Plugin in Jenkins

This guide provides step-by-step instructions to install and configure the OpenTelemetry Plugin in Jenkins.

## Overview

The OpenTelemetry Plugin enables Jenkins to export observability data (traces, metrics, logs) to OpenTelemetry-compatible backends, providing better visibility into your CI/CD pipeline performance.

## Prerequisites

- Jenkins is installed and running
- You have admin access to Jenkins
- Jenkins CLI is available (or access to Jenkins UI)

## Installation Methods

### Method 1: Automated Installation Script (Recommended)

Use the provided installation script:

```bash
sudo bash Scripts/OpenTelemetry/install-opentelemetry-plugin.sh
```

This script will:
1. Download Jenkins CLI
2. Install the OpenTelemetry plugin
3. Wait for Jenkins restart
4. Configure basic OpenTelemetry settings

### Method 2: Manual Installation via Jenkins UI

1. **Access Jenkins:**
   - Go to: `http://YOUR_JENKINS_IP:8080`
   - Login as admin

2. **Navigate to Plugin Manager:**
   - Click: `Manage Jenkins` → `Manage Plugins`

3. **Install Plugin:**
   - Go to: `Available` tab
   - Search for: `OpenTelemetry`
   - Select: `OpenTelemetry` plugin
   - Click: `Install without restart` or `Download now and install after restart`

4. **Restart Jenkins:**
   - After installation, restart Jenkins if prompted
   - Go to: `Manage Jenkins` → `Restart Jenkins when no jobs are running`

### Method 3: Manual Installation via Jenkins CLI

1. **Get Jenkins Admin Password:**
   ```bash
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```

2. **Download Jenkins CLI:**
   ```bash
   wget http://localhost:8080/jnlpJars/jenkins-cli.jar -O /tmp/jenkins-cli.jar
   ```

3. **Install Plugin:**
   ```bash
   java -jar /tmp/jenkins-cli.jar -s http://localhost:8080 \
     -auth admin:YOUR_PASSWORD \
     install-plugin opentelemetry -restart
   ```

4. **Wait for Jenkins Restart:**
   ```bash
   # Wait until Jenkins is back online
   while ! curl -s http://localhost:8080 >/dev/null; do
     sleep 5
     echo "Waiting for Jenkins to restart..."
   done
   echo "Jenkins is ready!"
   ```

## Configuration

### Basic Configuration

After installation, configure the OpenTelemetry plugin:

1. **Access Configuration:**
   - Go to: `Manage Jenkins` → `Configure System`
   - Scroll to: `OpenTelemetry` section

2. **Configure Endpoint:**
   - **Endpoint**: `http://your-otel-collector:4318/v1/traces`
     - Or `http://your-otel-collector:4317` (gRPC)
   - **Authentication**: Add if required
   - **Service Name**: `jenkins` (or your preferred name)

3. **Enable Observability:**
   - Check: `Enable OpenTelemetry`
   - Select: `Exporters` (OTLP HTTP or gRPC)
   - Configure: `Sampling rate` (1.0 = 100%)

4. **Save Configuration:**
   - Click: `Save`

### Advanced Configuration

#### Using Configuration as Code (JCasC)

If using Jenkins Configuration as Code plugin:

```yaml
jenkins:
  globalNodeProperties:
    - envVars:
        env:
          - key: "OTEL_SERVICE_NAME"
            value: "jenkins"
          - key: "OTEL_EXPORTER_OTLP_ENDPOINT"
            value: "http://otel-collector:4318"
          - key: "OTEL_RESOURCE_ATTRIBUTES"
            value: "service.name=jenkins,service.version=2.528.2"

unclassified:
  openTelemetry:
    endpoint: "http://otel-collector:4318/v1/traces"
    authentication: ""
    enabled: true
    exporterType: "OTLP"
    grpcEndpoint: "http://otel-collector:4317"
```

#### Configure via Groovy Script

Use the provided configuration script:

```bash
sudo bash Scripts/OpenTelemetry/configure-opentelemetry.groovy
```

Or run via Jenkins CLI:

```bash
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080 \
  -auth admin:YOUR_PASSWORD \
  groovy = < Scripts/OpenTelemetry/configure-opentelemetry.groovy
```

## Verification

### Check Plugin Installation

1. **Via Jenkins UI:**
   - Go to: `Manage Jenkins` → `Manage Plugins` → `Installed` tab
   - Search for: `OpenTelemetry`
   - Status should show: `Enabled`

2. **Via CLI:**
   ```bash
   java -jar /tmp/jenkins-cli.jar -s http://localhost:8080 \
     -auth admin:YOUR_PASSWORD \
     list-plugins | grep -i opentelemetry
   ```

### Test OpenTelemetry Export

1. **Run a Test Job:**
   - Create a simple Jenkins job
   - Run the job
   - Check if traces are exported to your OpenTelemetry backend

2. **Verify in Backend:**
   - Check your OpenTelemetry collector/logs
   - Verify traces are being received
   - Check metrics endpoint if configured

### Use Test Script

```bash
sudo bash Scripts/OpenTelemetry/test-opentelemetry.sh
```

This script will:
- Verify plugin is installed
- Check plugin configuration
- Test connectivity to OpenTelemetry endpoint
- Validate traces export

## Configuration Options

### Common Settings

- **Endpoint**: OpenTelemetry Collector endpoint URL
  - HTTP: `http://collector:4318/v1/traces`
  - gRPC: `http://collector:4317`

- **Service Name**: Name of your Jenkins service (default: `jenkins`)

- **Sampling Rate**: Percentage of traces to export (0.0 to 1.0)

- **Authentication**: Optional authentication token/credentials

- **Resource Attributes**: Additional metadata for traces

### Environment Variables

You can also configure via environment variables:

```bash
export OTEL_SERVICE_NAME=jenkins
export OTEL_EXPORTER_OTLP_ENDPOINT=http://collector:4318
export OTEL_RESOURCE_ATTRIBUTES="service.name=jenkins,deployment.environment=production"
```

## Integration Examples

### With Jaeger

1. **Deploy Jaeger:**
   ```bash
   docker run -d -p 16686:16686 -p 4317:4317 jaegertracing/all-in-one:latest
   ```

2. **Configure Jenkins:**
   - Endpoint: `http://jaeger:4317` (gRPC)
   - Service Name: `jenkins`

3. **View Traces:**
   - Open: `http://localhost:16686`
   - Search for `jenkins` service

### With Prometheus

OpenTelemetry can export metrics to Prometheus:

1. Configure OpenTelemetry Collector to export to Prometheus
2. Set up Prometheus to scrape the collector
3. View metrics in Prometheus/Grafana

### With Grafana Cloud

1. Get Grafana Cloud OpenTelemetry endpoint
2. Configure Jenkins with the endpoint
3. View traces in Grafana Cloud dashboard

## Troubleshooting

### Plugin Not Installing

1. **Check Jenkins Logs:**
   ```bash
   sudo tail -f /var/log/jenkins/jenkins.log
   ```

2. **Verify Internet Connectivity:**
   - Jenkins needs internet to download plugins
   - Check proxy settings if behind firewall

3. **Check Plugin Compatibility:**
   - Ensure plugin version is compatible with your Jenkins version
   - Check: https://plugins.jenkins.io/opentelemetry/

### Traces Not Exporting

1. **Verify Configuration:**
   - Check endpoint URL is correct
   - Verify authentication if required
   - Ensure plugin is enabled

2. **Check Network Connectivity:**
   ```bash
   curl -v http://otel-collector:4318/v1/traces
   telnet otel-collector 4317
   ```

3. **Check Jenkins Logs:**
   ```bash
   sudo grep -i opentelemetry /var/log/jenkins/jenkins.log
   ```

4. **Verify Collector is Running:**
   - Check collector logs
   - Verify collector is receiving data

### Performance Issues

1. **Adjust Sampling Rate:**
   - Lower sampling rate (e.g., 0.1 for 10%)
   - Reduces overhead

2. **Optimize Resource Attributes:**
   - Remove unnecessary attributes
   - Keep attributes minimal

3. **Monitor Resource Usage:**
   - Check Jenkins CPU/memory usage
   - Monitor network bandwidth

## Best Practices

1. **Use Sampling:**
   - Don't export 100% of traces in production
   - Use sampling rate appropriate for your needs

2. **Secure Endpoints:**
   - Use HTTPS/TLS for endpoints
   - Implement proper authentication

3. **Resource Attributes:**
   - Add meaningful metadata
   - Include environment, version, team info

4. **Monitor Plugin:**
   - Watch for errors in Jenkins logs
   - Monitor OpenTelemetry collector health

5. **Document Configuration:**
   - Keep endpoint URLs documented
   - Document authentication methods

## References

- [OpenTelemetry Plugin](https://plugins.jenkins.io/opentelemetry/)
- [Jenkins OpenTelemetry Documentation](https://github.com/jenkinsci/opentelemetry-plugin)
- [OpenTelemetry Collector](https://opentelemetry.io/docs/collector/)
- [OpenTelemetry Specification](https://opentelemetry.io/docs/specs/otel/)

## Next Steps

After installation:
1. Configure your OpenTelemetry backend (Jaeger, Tempo, etc.)
2. Set up dashboards in Grafana
3. Create alerts based on trace data
4. Integrate with your monitoring stack

