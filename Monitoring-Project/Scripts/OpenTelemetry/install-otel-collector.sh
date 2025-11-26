#!/bin/bash
# Install OpenTelemetry Collector on the VM
# This script installs and configures OTel Collector to receive from Jenkins and export to Tempo and Jaeger
# Run: sudo bash Scripts/OpenTelemetry/install-otel-collector.sh

set -e

echo "=========================================="
echo "Installing OpenTelemetry Collector"
echo "=========================================="

# Configuration variables
OTEL_COLLECTOR_VERSION="${OTEL_COLLECTOR_VERSION:-0.100.0}"
OTEL_USER="otelcol"
OTEL_HOME="/opt/otelcol"
OTEL_CONFIG="/etc/otelcol/config.yaml"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: Please run as root (use sudo)"
    exit 1
fi

# Create otelcol user
echo ""
echo "Creating otelcol user..."
if ! id "$OTEL_USER" &>/dev/null; then
    useradd -r -s /bin/false -d "$OTEL_HOME" -m "$OTEL_USER"
    echo "✓ User $OTEL_USER created"
else
    echo "✓ User $OTEL_USER already exists"
fi

# Create directories
echo ""
echo "Creating directories..."
mkdir -p "$OTEL_HOME"
mkdir -p /etc/otelcol
mkdir -p /var/log/otelcol
mkdir -p /var/lib/otelcol

chown -R "$OTEL_USER:$OTEL_USER" "$OTEL_HOME" /var/log/otelcol /var/lib/otelcol
echo "✓ Directories created"

# Download OpenTelemetry Collector
echo ""
echo "Downloading OpenTelemetry Collector v${OTEL_COLLECTOR_VERSION}..."
cd /tmp
ARCH="amd64"
OS="linux"
COLLECTOR_TAR="otelcol_${OTEL_COLLECTOR_VERSION}_linux_${ARCH}.tar.gz"
COLLECTOR_URL="https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${OTEL_COLLECTOR_VERSION}/${COLLECTOR_TAR}"

if [ ! -f "$COLLECTOR_TAR" ]; then
    wget -q "$COLLECTOR_URL" || {
        echo "Error: Failed to download OpenTelemetry Collector"
        exit 1
    }
fi

echo "✓ Download complete"

# Extract and install
echo ""
echo "Installing OpenTelemetry Collector..."
tar -xzf "$COLLECTOR_TAR"
cp otelcol "$OTEL_HOME/otelcol"
chmod +x "$OTEL_HOME/otelcol"
chown "$OTEL_USER:$OTEL_USER" "$OTEL_HOME/otelcol"
echo "✓ Collector installed to $OTEL_HOME/otelcol"

# Create systemd service
echo ""
echo "Creating systemd service..."
cat >/etc/systemd/system/otelcol.service <<EOF
[Unit]
Description=OpenTelemetry Collector
After=network.target

[Service]
Type=simple
User=$OTEL_USER
Group=$OTEL_USER
ExecStart=$OTEL_HOME/otelcol --config=$OTEL_CONFIG
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
echo "✓ Systemd service created"

# Create default configuration (will be updated by configure script)
echo ""
echo "Creating default configuration..."
cat >"$OTEL_CONFIG" <<'EOFYAML'
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
  memory_limiter:
    limit_mib: 512

exporters:
  logging:
    loglevel: info
  otlp/tempo:
    endpoint: localhost:4317
    tls:
      insecure: true
  otlp/jaeger:
    endpoint: localhost:14250
    tls:
      insecure: true

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, batch]
      exporters: [logging, otlp/tempo, otlp/jaeger]
EOFYAML

chown "$OTEL_USER:$OTEL_USER" "$OTEL_CONFIG"
echo "✓ Default configuration created"

# Enable and start service
echo ""
echo "Starting OpenTelemetry Collector..."
systemctl enable otelcol
systemctl start otelcol

# Wait for service to start
sleep 3

if systemctl is-active --quiet otelcol; then
    echo "✓ OpenTelemetry Collector is running"
else
    echo "✗ Failed to start OpenTelemetry Collector"
    echo "Check logs: sudo journalctl -u otelcol -n 50"
    exit 1
fi

echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "OpenTelemetry Collector is running on:"
echo "  - gRPC: 0.0.0.0:4317"
echo "  - HTTP: 0.0.0.0:4318"
echo ""
echo "Next steps:"
echo "1. Configure collectors (Tempo/Jaeger endpoints):"
echo "   sudo bash Scripts/OpenTelemetry/configure-otel-collector.sh"
echo ""
echo "2. Configure Jenkins to use this collector:"
echo "   sudo bash Scripts/OpenTelemetry/configure-opentelemetry.sh --endpoint http://localhost:4318"
echo ""
echo "3. Check status:"
echo "   sudo systemctl status otelcol"
echo ""
echo "4. View logs:"
echo "   sudo journalctl -u otelcol -f"
echo "=========================================="

