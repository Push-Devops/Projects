#!/bin/bash
# Complete end-to-end test for OpenTelemetry setup
# This script tests all components: Collector, Jenkins Plugin, and Trace Export
# Run: sudo bash Scripts/OpenTelemetry/test-complete-setup.sh

set -e

echo "=========================================="
echo "OpenTelemetry Complete Setup Test"
echo "=========================================="
echo ""
echo "This script will test all components of the OpenTelemetry setup:"
echo "  1. OpenTelemetry Collector"
echo "  2. Jenkins OpenTelemetry Plugin"
echo "  3. Trace Export Flow"
echo ""

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo "----------------------------------------"
    echo "Test: $test_name"
    echo "----------------------------------------"
    
    if eval "$test_command" >/dev/null 2>&1; then
        echo "✓ PASSED: $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo "✗ FAILED: $test_name"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Test 1: OTel Collector Installation
echo ""
echo "=========================================="
echo "TEST GROUP 1: OpenTelemetry Collector"
echo "=========================================="

run_test "Collector binary exists" "[ -f /opt/otelcol/otelcol ]"
run_test "Collector service is running" "systemctl is-active --quiet otelcol"
run_test "gRPC port 4317 is listening" "ss -tlnp | grep -q ':4317'"
run_test "HTTP port 4318 is listening" "ss -tlnp | grep -q ':4318'"
run_test "Configuration file exists" "[ -f /etc/otelcol/config.yaml ]"

# Test Collector version
echo ""
echo "Collector Version:"
/opt/otelcol/otelcol --version 2>&1 | head -1 || echo "Could not get version"

# Test 2: Jenkins Service
echo ""
echo "=========================================="
echo "TEST GROUP 2: Jenkins Service"
echo "=========================================="

run_test "Jenkins service is running" "systemctl is-active --quiet jenkins"
run_test "Jenkins HTTP port 8080 is listening" "ss -tlnp | grep -q ':8080'"
run_test "Jenkins is accessible" "curl -s -o /dev/null -w '%{http_code}' http://localhost:8080 | grep -q '20\|40\|30'"

# Test 3: Jenkins OpenTelemetry Plugin
echo ""
echo "=========================================="
echo "TEST GROUP 3: Jenkins OpenTelemetry Plugin"
echo "=========================================="

# Check if Jenkins CLI is available
if [ ! -f /tmp/jenkins-cli.jar ]; then
    echo "Downloading Jenkins CLI..."
    wget -q http://localhost:8080/jnlpJars/jenkins-cli.jar -O /tmp/jenkins-cli.jar 2>/dev/null || true
fi

if [ -f /tmp/jenkins-cli.jar ]; then
    JENKINS_PASSWORD=$(cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo "")
    
    if [ -n "$JENKINS_PASSWORD" ]; then
        PLUGIN_CHECK=$(java -jar /tmp/jenkins-cli.jar -s http://localhost:8080 -auth admin:$JENKINS_PASSWORD list-plugins 2>/dev/null | grep -i opentelemetry || echo "")
        
        if [ -n "$PLUGIN_CHECK" ]; then
            echo "✓ PASSED: OpenTelemetry plugin is installed"
            echo "  $PLUGIN_CHECK"
            ((TESTS_PASSED++))
        else
            echo "✗ FAILED: OpenTelemetry plugin is NOT installed"
            echo "  Install it: sudo bash Scripts/OpenTelemetry/install-opentelemetry-plugin.sh"
            ((TESTS_FAILED++))
        fi
    else
        echo "⚠ SKIPPED: Could not get Jenkins password (plugin check skipped)"
    fi
else
    echo "⚠ SKIPPED: Jenkins CLI not available (plugin check skipped)"
fi

# Test 4: Connectivity Tests
echo ""
echo "=========================================="
echo "TEST GROUP 4: Connectivity"
echo "=========================================="

run_test "Can connect to Collector HTTP endpoint" "timeout 2 bash -c 'curl -s http://localhost:4318/v1/traces -X POST -H \"Content-Type: application/json\" -d \"{}\" >/dev/null'"
run_test "Can connect to Collector gRPC port" "timeout 2 bash -c 'echo > /dev/tcp/localhost/4317'"

# Test 5: Configuration Tests
echo ""
echo "=========================================="
echo "TEST GROUP 5: Configuration"
echo "=========================================="

if [ -f /etc/otelcol/config.yaml ]; then
    # Check if config has exporters
    if grep -q "exporters:" /etc/otelcol/config.yaml; then
        echo "✓ PASSED: Collector config has exporters section"
        ((TESTS_PASSED++))
        
        # Check for Tempo exporter
        if grep -q "tempo\|otlp/tempo" /etc/otelcol/config.yaml; then
            echo "✓ PASSED: Tempo exporter configured"
            ((TESTS_PASSED++))
        else
            echo "⚠ WARNING: Tempo exporter not found in config"
        fi
        
        # Check for Jaeger exporter
        if grep -q "jaeger\|otlp/jaeger" /etc/otelcol/config.yaml; then
            echo "✓ PASSED: Jaeger exporter configured"
            ((TESTS_PASSED++))
        else
            echo "⚠ WARNING: Jaeger exporter not found in config"
        fi
    else
        echo "✗ FAILED: Collector config missing exporters"
        ((TESTS_FAILED++))
    fi
    
    # Validate config syntax
    if /opt/otelcol/otelcol --config=/etc/otelcol/config.yaml --dry-run 2>&1 | grep -qi "error"; then
        echo "✗ FAILED: Collector config has errors"
        ((TESTS_FAILED++))
    else
        echo "✓ PASSED: Collector config is valid"
        ((TESTS_PASSED++))
    fi
else
    echo "✗ FAILED: Collector config file not found"
    ((TESTS_FAILED++))
fi

# Test 6: Collector Logs
echo ""
echo "=========================================="
echo "TEST GROUP 6: Collector Health"
echo "=========================================="

# Check for errors in recent logs
RECENT_ERRORS=$(sudo journalctl -u otelcol -n 50 --no-pager 2>/dev/null | grep -i error | wc -l || echo "0")

if [ "$RECENT_ERRORS" -eq "0" ]; then
    echo "✓ PASSED: No recent errors in collector logs"
    ((TESTS_PASSED++))
else
    echo "⚠ WARNING: Found $RECENT_ERRORS error(s) in collector logs"
    echo "  Check logs: sudo journalctl -u otelcol -n 50"
fi

# Summary
echo ""
echo "=========================================="
echo "TEST SUMMARY"
echo "=========================================="
echo "Tests Passed: $TESTS_PASSED"
echo "Tests Failed: $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo "✓ ALL TESTS PASSED!"
    echo ""
    echo "Next steps:"
    echo "1. Run a test Jenkins pipeline"
    echo "2. Check traces in Jaeger: http://localhost:16686"
    echo "3. Check traces in Grafana Tempo (if configured)"
    exit 0
else
    echo "✗ SOME TESTS FAILED"
    echo ""
    echo "Please fix the failed tests before proceeding."
    echo "Refer to TESTING-GUIDE.md for detailed troubleshooting."
    exit 1
fi

