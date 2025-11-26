# Complete Jenkins OpenTelemetry Setup Guide

This guide provides complete instructions for setting up OpenTelemetry tracing in Jenkins pipelines with export to Grafana Tempo and Jaeger.

## Overview

This setup enables end-to-end observability of Jenkins pipelines by:
1. Installing OpenTelemetry Collector on the VM
2. Configuring Jenkins to export traces
3. Setting up pipeline instrumentation for detailed spans
4. Exporting traces to both Grafana Tempo and Jaeger

## Architecture

```
Jenkins Pipeline
    ↓ (spans)
OpenTelemetry Collector (localhost:4318)
    ↓ (exports)
    ├──→ Grafana Tempo (for long-term storage)
    └──→ Jaeger (for real-time viewing)
```

## Prerequisites

- Jenkins installed and running
- Root/sudo access on the VM
- Network access to Tempo and Jaeger (if remote)
- OpenTelemetry Plugin installed in Jenkins

## Installation Steps

### Step 1: Install OpenTelemetry Collector

```bash
sudo bash Scripts/OpenTelemetry/install-otel-collector.sh
```

This will:
- Download and install OTel Collector
- Create systemd service
- Configure default endpoints
- Start the collector service

**Verify installation:**
```bash
sudo systemctl status otelcol
sudo ss -tlnp | grep -E ':(4317|4318)'
```

### Step 2: Configure OTel Collector for Tempo and Jaeger

Configure the collector to export to your Tempo and Jaeger instances:

```bash
# Local Tempo and Jaeger
sudo bash Scripts/OpenTelemetry/configure-otel-collector.sh \
  --tempo-endpoint localhost:4317 \
  --jaeger-endpoint localhost:14250 \
  --jaeger-ui http://localhost:16686

# Remote endpoints
sudo bash Scripts/OpenTelemetry/configure-otel-collector.sh \
  --tempo-endpoint tempo.example.com:4317 \
  --jaeger-endpoint jaeger.example.com:14250 \
  --jaeger-ui http://jaeger.example.com:16686
```

### Step 3: Configure Jenkins OpenTelemetry Plugin

Point Jenkins to the OTel Collector:

```bash
sudo bash Scripts/OpenTelemetry/configure-opentelemetry.sh \
  --endpoint http://localhost:4318 \
  --service-name jenkins-pipelines
```

Or configure via Jenkins UI:
1. Go to: `Manage Jenkins` → `Configure System`
2. Find: `OpenTelemetry` section
3. Set:
   - **Endpoint**: `http://localhost:4318/v1/traces`
   - **Service Name**: `jenkins-pipelines`
   - **Enable**: ✓

### Step 4: Create Instrumented Pipeline

Use the provided pipeline examples:

1. **Simple Pipeline** (`jenkins-pipeline-example.groovy`):
   - Basic spans for each stage
   - Minimal configuration

2. **Advanced Pipeline** (`jenkins-pipeline-advanced.groovy`):
   - Detailed spans with metadata
   - Custom attributes
   - Performance metrics

Copy the pipeline script to your Jenkins job.

## Pipeline Spans Explained

### Job Start Span
- **When**: Pipeline begins execution
- **Attributes**: Job name, build number, parameters
- **Duration**: Entire pipeline execution

### SCM Checkout Span
- **When**: Source code checkout
- **Attributes**: Git commit, branch, author, message
- **Duration**: Checkout operation time

### Build Span
- **When**: Build stage execution
- **Attributes**: Build type, environment, version
- **Duration**: Build process time

### Test Span
- **When**: Test execution
- **Attributes**: Test count, pass/fail, coverage
- **Duration**: Test execution time

### Artifact Upload Span
- **When**: Artifact archiving/uploading
- **Attributes**: Artifact names, sizes, locations
- **Duration**: Upload time

## Viewing Traces

### Jaeger UI

1. **Access Jaeger UI:**
   ```
   http://your-jaeger-host:16686
   ```

2. **Search for traces:**
   - Service: `jenkins-pipelines`
   - Operation: Select pipeline stages
   - Time range: Select desired period

3. **View trace details:**
   - Click on a trace to see timeline
   - Expand spans for details
   - View tags and logs

### Grafana Tempo

1. **Access Grafana:**
   ```
   http://your-grafana-host:3000
   ```

2. **Query traces:**
   - Use Tempo data source
   - Query: `{service.name="jenkins-pipelines"}`
   - Select time range

3. **Create dashboards:**
   - Use Tempo queries in Grafana
   - Create visualization panels
   - Add trace links to metrics

## Testing the Setup

### Test OTel Collector

```bash
sudo bash Scripts/OpenTelemetry/test-otel-collector.sh
```

### Test Jenkins Configuration

```bash
sudo bash Scripts/OpenTelemetry/test-opentelemetry.sh
```

### Run Test Pipeline

1. Create a new Pipeline job in Jenkins
2. Copy `jenkins-pipeline-example.groovy` content
3. Run the job
4. Check traces in Jaeger/Tempo

## Advanced Configuration

### Custom Span Attributes

Add custom attributes in your pipeline:

```groovy
environment {
    OTEL_RESOURCE_ATTRIBUTES = 'service.name=jenkins,team=devops,environment=production'
}
```

### Span Filtering

Configure sampling in OTel Collector:

```yaml
processors:
  probabilistic_sampler:
    sampling_percentage: 10.0  # Sample 10% of traces
```

### Multiple Exporters

Add more exporters in `config.yaml`:

```yaml
exporters:
  otlp/tempo:
    endpoint: tempo:4317
  otlp/jaeger:
    endpoint: jaeger:14250
  otlp/cloud:
    endpoint: https://api.datadog.com/v1/traces
    headers:
      DD-API-KEY: your-api-key
```

## Troubleshooting

### Traces Not Appearing in Jaeger

1. **Check OTel Collector logs:**
   ```bash
   sudo journalctl -u otelcol -f
   ```

2. **Verify endpoints:**
   ```bash
   curl -v http://localhost:4318/v1/traces
   telnet jaeger-host 14250
   ```

3. **Check Jenkins configuration:**
   - Verify endpoint URL
   - Check plugin is enabled
   - Review Jenkins logs

### Collector Not Receiving Traces

1. **Check collector is running:**
   ```bash
   sudo systemctl status otelcol
   ```

2. **Verify ports are listening:**
   ```bash
   sudo ss -tlnp | grep -E ':(4317|4318)'
   ```

3. **Test connectivity from Jenkins:**
   ```bash
   curl http://localhost:4318/v1/traces
   ```

### High Memory Usage

Adjust memory limits in collector config:

```yaml
processors:
  memory_limiter:
    limit_mib: 1024  # Increase limit
    spike_limit_mib: 512
```

## Best Practices

1. **Sampling**: Use sampling for high-volume pipelines
   - Production: 10-20% sampling
   - Development: 100% sampling

2. **Resource Attributes**: Add meaningful metadata
   - Team, environment, version
   - Service ownership

3. **Span Naming**: Use consistent naming
   - `job.{job-name}.{stage-name}`
   - `pipeline.{pipeline-name}.{step}`

4. **Error Handling**: Capture errors in spans
   - Set error status on failure
   - Add error messages as attributes

5. **Performance**: Monitor collector performance
   - Watch memory usage
   - Adjust batch sizes
   - Scale horizontally if needed

## Example Queries

### Jaeger Queries

- All Jenkins traces: `service=jenkins-pipelines`
- Failed builds: `service=jenkins-pipelines status_code=ERROR`
- Specific job: `service=jenkins-pipelines job.name=my-job`
- Long builds: `service=jenkins-pipelines duration>300s`

### Tempo Queries (Grafana)

- TraceQL: `{service.name="jenkins-pipelines"}`
- With duration: `{service.name="jenkins-pipelines"} | duration > 5m`
- With status: `{service.name="jenkins-pipelines", status="error"}`
- With tags: `{service.name="jenkins-pipelines", build.result="FAILURE"}`

## Monitoring and Alerts

### Key Metrics to Monitor

1. **Trace Export Rate**
   - Traces exported per second
   - Export failures

2. **Span Count**
   - Spans per trace
   - Average span duration

3. **Error Rate**
   - Failed pipeline traces
   - Collector errors

4. **Performance**
   - Collector CPU/memory
   - Export latency

### Sample Prometheus Queries

```promql
# Traces exported per second
rate(otelcol_exporter_sent_spans[5m])

# Failed exports
rate(otelcol_exporter_send_failed_spans[5m])

# Collector memory usage
otelcol_process_memory_rss_bytes
```

## Next Steps

1. **Create Dashboards**: Build Grafana dashboards for pipeline metrics
2. **Set Up Alerts**: Alert on failed builds, long durations
3. **Integrate**: Connect traces with metrics and logs
4. **Optimize**: Tune sampling and filtering based on usage

## References

- [OpenTelemetry Documentation](https://opentelemetry.io/docs/)
- [Jenkins OpenTelemetry Plugin](https://plugins.jenkins.io/opentelemetry/)
- [Grafana Tempo](https://grafana.com/docs/tempo/latest/)
- [Jaeger Documentation](https://www.jaegertracing.io/docs/)

