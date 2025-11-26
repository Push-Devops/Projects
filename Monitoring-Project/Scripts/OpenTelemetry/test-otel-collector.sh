#!/bin/bash
# Test OpenTelemetry Collector installation and configuration
# Run: sudo bash Scripts/OpenTelemetry/test-otel-collector.sh

echo "=========================================="
echo "Testing OpenTelemetry Collector"
echo "=========================================="
echo ""

# Check if collector is installed
echo "1. Checking installation..."
if [ -f /opt/otelcol/otelcol ]; then
    echo "✓ OTel Collector binary found"
    /opt/otelcol/otelcol --version 2>&1 | head -1
else
    echo "✗ OTel Collector not found"
    echo "  Install it: sudo bash Scripts/OpenTelemetry/install-otel-collector.sh"
    exit 1
fi

# Check service status
echo ""
echo "2. Checking service status..."
if systemctl is-active --quiet otelcol; then
    echo "✓ OTel Collector service is running"
    systemctl status otelcol --no-pager -l | head -5
else
    echo "✗ OTel Collector service is not running"
    echo "  Start it: sudo systemctl start otelcol"
    exit 1
fi

# Check ports
echo ""
echo "3. Checking ports..."
if ss -tlnp | grep -q ':4317'; then
    echo "✓ gRPC port 4317 is listening"
else
    echo "✗ gRPC port 4317 is NOT listening"
fi

if ss -tlnp | grep -q ':4318'; then
    echo "✓ HTTP port 4318 is listening"
else
    echo "✗ HTTP port 4318 is NOT listening"
fi

# Check configuration
echo ""
echo "4. Checking configuration..."
if [ -f /etc/otelcol/config.yaml ]; then
    echo "✓ Configuration file exists"
    
    # Validate config
    if /opt/otelcol/otelcol --config=/etc/otelcol/config.yaml --dry-run 2>&1 | grep -qi "error"; then
        echo "⚠ Configuration may have errors"
        /opt/otelcol/otelcol --config=/etc/otelcol/config.yaml --dry-run 2>&1 | head -10
    else
        echo "✓ Configuration appears valid"
    fi
    
    # Show endpoints
    echo ""
    echo "Configured exporters:"
    grep -A 5 "exporters:" /etc/otelcol/config.yaml | grep -E "(tempo|jaeger|otlp)" | sed 's/^/  /'
else
    echo "✗ Configuration file not found"
fi

# Check logs
echo ""
echo "5. Recent log entries..."
RECENT_LOGS=$(sudo journalctl -u otelcol -n 10 --no-pager 2>/dev/null || echo "")
if [ -n "$RECENT_LOGS" ]; then
    echo "Recent logs:"
    echo "$RECENT_LOGS" | sed 's/^/  /'
    
    # Check for errors
    ERROR_COUNT=$(echo "$RECENT_LOGS" | grep -i error | wc -l)
    if [ "$ERROR_COUNT" -gt 0 ]; then
        echo ""
        echo "⚠ Found $ERROR_COUNT error(s) in logs"
        echo "$RECENT_LOGS" | grep -i error | head -3 | sed 's/^/    /'
    fi
else
    echo "  No recent logs found"
fi

# Test HTTP endpoint
echo ""
echo "6. Testing HTTP endpoint..."
HTTP_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:4318/v1/traces -X POST -H "Content-Type: application/json" -d '{}' 2>/dev/null || echo "000")
if [ "$HTTP_RESPONSE" = "405" ] || [ "$HTTP_RESPONSE" = "400" ]; then
    echo "✓ HTTP endpoint is responding (code: $HTTP_RESPONSE)"
elif [ "$HTTP_RESPONSE" = "000" ]; then
    echo "✗ HTTP endpoint is not responding"
else
    echo "⚠ HTTP endpoint returned: $HTTP_RESPONSE"
fi

# Test gRPC endpoint (basic connectivity)
echo ""
echo "7. Testing gRPC endpoint..."
if timeout 2 bash -c "echo > /dev/tcp/localhost/4317" 2>/dev/null; then
    echo "✓ gRPC endpoint is reachable"
else
    echo "✗ gRPC endpoint is not reachable"
fi

# Summary
echo ""
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo ""

if systemctl is-active --quiet otelcol && [ -f /opt/otelcol/otelcol ]; then
    echo "✓ OpenTelemetry Collector is installed and running"
    echo ""
    echo "Endpoints available:"
    echo "  - HTTP: http://localhost:4318/v1/traces"
    echo "  - gRPC: localhost:4317"
    echo ""
    echo "Configure Jenkins:"
    echo "  sudo bash Scripts/OpenTelemetry/configure-opentelemetry.sh --endpoint http://localhost:4318"
else
    echo "✗ OpenTelemetry Collector has issues"
    echo "  Check logs: sudo journalctl -u otelcol -f"
fi

echo "=========================================="

