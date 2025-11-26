#!/bin/bash
# Test OpenTelemetry Plugin Installation and Configuration
# Run this script on the Jenkins server: sudo bash test-opentelemetry.sh

echo "=========================================="
echo "Testing OpenTelemetry Plugin"
echo "=========================================="
echo ""

# Check if Jenkins is running
if ! systemctl is-active --quiet jenkins; then
    echo "✗ Jenkins is not running"
    exit 1
else
    echo "✓ Jenkins is running"
fi

# Wait for Jenkins to be accessible
for i in {1..30}; do
    if curl -s http://localhost:8080 >/dev/null 2>&1; then
        break
    fi
    sleep 2
done

# Get Jenkins password
JENKINS_PASSWORD=$(cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo "")

if [ -z "$JENKINS_PASSWORD" ]; then
    echo "Warning: Could not get Jenkins password automatically"
    JENKINS_PASSWORD=""
fi

# Download Jenkins CLI if needed
if [ ! -f /tmp/jenkins-cli.jar ]; then
    echo "Downloading Jenkins CLI..."
    wget -q http://localhost:8080/jnlpJars/jenkins-cli.jar -O /tmp/jenkins-cli.jar 2>/dev/null || {
        echo "✗ Failed to download Jenkins CLI"
        exit 1
    }
fi

echo ""
echo "1. Checking plugin installation..."
echo "-----------------------------------"
PLUGIN_INFO=$(java -jar /tmp/jenkins-cli.jar -s http://localhost:8080 -auth admin:$JENKINS_PASSWORD list-plugins 2>/dev/null | grep -i opentelemetry || echo "")

if [ -n "$PLUGIN_INFO" ]; then
    echo "✓ OpenTelemetry plugin is installed:"
    echo "  $PLUGIN_INFO"
else
    echo "✗ OpenTelemetry plugin is NOT installed"
    echo "  Install it: sudo bash Scripts/OpenTelemetry/install-opentelemetry-plugin.sh"
    exit 1
fi

echo ""
echo "2. Checking plugin configuration..."
echo "-----------------------------------"
# Try to get configuration via Groovy
cat >/tmp/check-otel-config.groovy <<'GROOVY'
import jenkins.model.Jenkins
import io.jenkins.plugins.opentelemetry.JenkinsOpenTelemetryPluginConfiguration

try {
    def config = JenkinsOpenTelemetryPluginConfiguration.get()
    
    println "Enabled: " + config.isEnabled()
    
    def backend = config.getBackend()
    if (backend != null) {
        println "Backend Type: " + backend.getClass().getSimpleName()
        
        // Try to get endpoint
        try {
            def endpoint = backend.getEndpoint()
            println "Endpoint: " + endpoint
        } catch (Exception e) {
            println "Endpoint: Not available via API"
        }
    } else {
        println "Backend: Not configured"
    }
    
    println "Service Name: " + config.getServiceName()
    
} catch (Exception e) {
    println "Error checking configuration: " + e.message
    println "Plugin may not be fully initialized"
}
GROOVY

CONFIG_OUTPUT=$(java -jar /tmp/jenkins-cli.jar -s http://localhost:8080 -auth admin:$JENKINS_PASSWORD groovy = </tmp/check-otel-config.groovy 2>&1 || echo "Error checking configuration")

if echo "$CONFIG_OUTPUT" | grep -q "Error"; then
    echo "⚠ Configuration check failed (this may be normal if plugin was just installed)"
    echo "  $CONFIG_OUTPUT"
else
    echo "$CONFIG_OUTPUT" | while read line; do
        echo "  $line"
    done
fi

echo ""
echo "3. Checking Jenkins logs for OpenTelemetry..."
echo "----------------------------------------------"
RECENT_LOGS=$(sudo grep -i opentelemetry /var/log/jenkins/jenkins.log 2>/dev/null | tail -5 || echo "")

if [ -n "$RECENT_LOGS" ]; then
    echo "Recent OpenTelemetry log entries:"
    echo "$RECENT_LOGS" | while read line; do
        echo "  $line"
    done
else
    echo "  No recent OpenTelemetry entries in logs"
fi

echo ""
echo "4. Testing endpoint connectivity (if configured)..."
echo "---------------------------------------------------"
ENDPOINT=$(echo "$CONFIG_OUTPUT" | grep "Endpoint:" | cut -d: -f2- | xargs)

if [ -n "$ENDPOINT" ] && [ "$ENDPOINT" != "Not available via API" ]; then
    # Extract host:port from endpoint
    HOST_PORT=$(echo "$ENDPOINT" | sed 's|http://||' | sed 's|https://||' | sed 's|/.*||' | cut -d: -f1-2)
    
    if [ -n "$HOST_PORT" ]; then
        HOST=$(echo "$HOST_PORT" | cut -d: -f1)
        PORT=$(echo "$HOST_PORT" | cut -d: -f2)
        
        echo "Testing connection to $HOST:$PORT..."
        if timeout 5 bash -c "echo > /dev/tcp/$HOST/$PORT" 2>/dev/null; then
            echo "✓ Endpoint is reachable"
        else
            echo "✗ Endpoint is NOT reachable"
            echo "  Check if OpenTelemetry collector is running"
        fi
    fi
else
    echo "  Endpoint not configured or not available"
    echo "  Configure it: sudo bash Scripts/OpenTelemetry/configure-opentelemetry.sh"
fi

echo ""
echo "5. Summary and recommendations..."
echo "---------------------------------"
echo ""

# Final status
PLUGIN_INSTALLED=$(java -jar /tmp/jenkins-cli.jar -s http://localhost:8080 -auth admin:$JENKINS_PASSWORD list-plugins 2>/dev/null | grep -i opentelemetry || echo "")

if [ -n "$PLUGIN_INSTALLED" ]; then
    echo "✓ Plugin Status: INSTALLED"
    echo ""
    echo "Next steps:"
    echo "1. Configure OpenTelemetry endpoint:"
    echo "   sudo bash Scripts/OpenTelemetry/configure-opentelemetry.sh --endpoint http://your-collector:4318"
    echo ""
    echo "2. Or configure via Jenkins UI:"
    echo "   Manage Jenkins → Configure System → OpenTelemetry"
    echo ""
    echo "3. Test with a Jenkins job to verify traces are exported"
else
    echo "✗ Plugin Status: NOT INSTALLED"
    echo ""
    echo "Install the plugin:"
    echo "  sudo bash Scripts/OpenTelemetry/install-opentelemetry-plugin.sh"
fi

echo ""
echo "=========================================="
echo "Test Complete"
echo "=========================================="

