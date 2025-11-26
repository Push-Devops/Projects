#!/bin/bash
# Configure OpenTelemetry Collector to export to Grafana Tempo and Jaeger
# Usage: sudo bash configure-otel-collector.sh [OPTIONS]
#
# Options:
#   --tempo-endpoint URL    Grafana Tempo endpoint (default: localhost:4317)
#   --jaeger-endpoint URL   Jaeger endpoint (default: localhost:14250)
#   --jaeger-ui URL         Jaeger UI URL (default: http://localhost:16686)

set -e

# Default endpoints
TEMPO_ENDPOINT="${TEMPO_ENDPOINT:-localhost:4317}"
JAEGER_ENDPOINT="${JAEGER_ENDPOINT:-localhost:14250}"
JAEGER_UI="${JAEGER_UI:-http://localhost:16686}"

OTEL_CONFIG="/etc/otelcol/config.yaml"
OTEL_USER="otelcol"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --tempo-endpoint)
            TEMPO_ENDPOINT="$2"
            shift 2
            ;;
        --jaeger-endpoint)
            JAEGER_ENDPOINT="$2"
            shift 2
            ;;
        --jaeger-ui)
            JAEGER_UI="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --tempo-endpoint URL    Tempo endpoint (default: localhost:4317)"
            echo "  --jaeger-endpoint URL   Jaeger endpoint (default: localhost:14250)"
            echo "  --jaeger-ui URL         Jaeger UI URL (default: http://localhost:16686)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "=========================================="
echo "Configuring OpenTelemetry Collector"
echo "=========================================="
echo ""
echo "Configuration:"
echo "  Tempo endpoint: $TEMPO_ENDPOINT"
echo "  Jaeger endpoint: $JAEGER_ENDPOINT"
echo "  Jaeger UI: $JAEGER_UI"
echo ""

# Backup existing config
if [ -f "$OTEL_CONFIG" ]; then
    cp "$OTEL_CONFIG" "${OTEL_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
    echo "✓ Backed up existing configuration"
fi

# Create new configuration
echo "Creating new configuration..."
cat >"$OTEL_CONFIG" <<EOFYAML
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:
    timeout: 1s
    send_batch_size: 1024
    send_batch_max_size: 2048
  memory_limiter:
    limit_mib: 512
    spike_limit_mib: 256
    check_interval: 1s
  resource:
    attributes:
      - key: service.name
        value: jenkins-pipelines
        action: upsert
      - key: deployment.environment
        value: production
        action: upsert

exporters:
  logging:
    loglevel: info
    sampling_initial: 5
    sampling_thereafter: 200
  
  # Export to Grafana Tempo
  otlp/tempo:
    endpoint: ${TEMPO_ENDPOINT}
    tls:
      insecure: true
    headers:
      "X-Scope-OrgID": "tempo"
  
  # Export to Jaeger
  otlp/jaeger:
    endpoint: ${JAEGER_ENDPOINT}
    tls:
      insecure: true
  
  # Alternative: Direct Jaeger exporter (if using gRPC)
  jaeger:
    endpoint: ${JAEGER_ENDPOINT}
    tls:
      insecure: true

service:
  telemetry:
    logs:
      level: info
    metrics:
      level: detailed
      address: 0.0.0.0:8888
  
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, resource, batch]
      exporters: [logging, otlp/tempo, otlp/jaeger]
EOFYAML

chown "$OTEL_USER:$OTEL_USER" "$OTEL_CONFIG"
echo "✓ Configuration file created"

# Validate configuration
echo ""
echo "Validating configuration..."
if /opt/otelcol/otelcol --config="$OTEL_CONFIG" --dry-run 2>&1 | grep -q "Configuration is valid"; then
    echo "✓ Configuration is valid"
else
    echo "⚠ Warning: Configuration validation returned unexpected result"
    echo "Testing configuration manually..."
fi

# Reload service
echo ""
echo "Reloading OpenTelemetry Collector..."
systemctl restart otelcol

# Wait for restart
sleep 3

if systemctl is-active --quiet otelcol; then
    echo "✓ OpenTelemetry Collector restarted successfully"
else
    echo "✗ Failed to restart OpenTelemetry Collector"
    echo "Check logs: sudo journalctl -u otelcol -n 50"
    exit 1
fi

echo ""
echo "=========================================="
echo "Configuration Complete!"
echo "=========================================="
echo ""
echo "OpenTelemetry Collector is configured to export to:"
echo "  ✓ Grafana Tempo: $TEMPO_ENDPOINT"
echo "  ✓ Jaeger: $JAEGER_ENDPOINT"
echo ""
echo "Jenkins should send traces to:"
echo "  - HTTP: http://localhost:4318/v1/traces"
echo "  - gRPC: localhost:4317"
echo ""
echo "View traces:"
echo "  - Jaeger UI: $JAEGER_UI"
echo "  - Grafana Tempo: Check your Grafana instance"
echo ""
echo "Test connectivity:"
echo "  sudo bash Scripts/OpenTelemetry/test-otel-collector.sh"
echo "=========================================="

