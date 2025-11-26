#!/bin/bash
# Configure OpenTelemetry Plugin in Jenkins
# Run this script on the Jenkins server: sudo bash configure-opentelemetry.sh
#
# Usage:
#   sudo bash configure-opentelemetry.sh
#   sudo bash configure-opentelemetry.sh --endpoint http://otel-collector:4318
#   sudo bash configure-opentelemetry.sh --endpoint http://otel-collector:4318 --service-name my-jenkins

set -e

# Default values
OTEL_ENDPOINT="${OTEL_ENDPOINT:-http://localhost:4318/v1/traces}"
OTEL_SERVICE_NAME="${OTEL_SERVICE_NAME:-jenkins}"
OTEL_ENABLED="${OTEL_ENABLED:-true}"
OTEL_SAMPLING="${OTEL_SAMPLING:-1.0}"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --endpoint)
            OTEL_ENDPOINT="$2"
            shift 2
            ;;
        --service-name)
            OTEL_SERVICE_NAME="$2"
            shift 2
            ;;
        --sampling)
            OTEL_SAMPLING="$2"
            shift 2
            ;;
        --disable)
            OTEL_ENABLED="false"
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --endpoint URL      OpenTelemetry endpoint (default: http://localhost:4318/v1/traces)"
            echo "  --service-name NAME Service name (default: jenkins)"
            echo "  --sampling RATE     Sampling rate 0.0-1.0 (default: 1.0)"
            echo "  --disable           Disable OpenTelemetry"
            echo "  --help              Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo "=========================================="
echo "Configuring OpenTelemetry Plugin"
echo "=========================================="

# Check if Jenkins is running
if ! systemctl is-active --quiet jenkins; then
    echo "Error: Jenkins is not running. Please start Jenkins first."
    exit 1
fi

# Wait for Jenkins to be ready
echo "Waiting for Jenkins to be ready..."
for i in {1..30}; do
    if curl -s http://localhost:8080 >/dev/null 2>&1; then
        break
    fi
    sleep 2
done

# Get Jenkins admin password
JENKINS_PASSWORD=$(cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo "")

if [ -z "$JENKINS_PASSWORD" ]; then
    echo "Warning: Could not get Jenkins password automatically."
    echo "Please provide Jenkins admin password:"
    read -s JENKINS_PASSWORD
fi

if [ -z "$JENKINS_PASSWORD" ]; then
    echo "Error: Jenkins password is required."
    exit 1
fi

# Download Jenkins CLI if not exists
if [ ! -f /tmp/jenkins-cli.jar ]; then
    echo "Downloading Jenkins CLI..."
    wget -q http://localhost:8080/jnlpJars/jenkins-cli.jar -O /tmp/jenkins-cli.jar
fi

# Check if OpenTelemetry plugin is installed
echo ""
echo "Checking if OpenTelemetry plugin is installed..."
PLUGIN_CHECK=$(java -jar /tmp/jenkins-cli.jar -s http://localhost:8080 -auth admin:$JENKINS_PASSWORD list-plugins 2>/dev/null | grep -i opentelemetry || echo "")

if [ -z "$PLUGIN_CHECK" ]; then
    echo "Error: OpenTelemetry plugin is not installed."
    echo "Please install it first:"
    echo "  sudo bash Scripts/OpenTelemetry/install-opentelemetry-plugin.sh"
    exit 1
fi

echo "✓ OpenTelemetry plugin is installed"

# Create Groovy configuration script
echo ""
echo "Creating configuration script..."
cat >/tmp/configure-opentelemetry.groovy <<GROOVY
import jenkins.model.Jenkins
import io.jenkins.plugins.opentelemetry.JenkinsOpenTelemetryPluginConfiguration
import io.jenkins.plugins.opentelemetry.backend.OtlpBackend
import io.jenkins.plugins.opentelemetry.backend.OtlpHttpBackend
import io.jenkins.plugins.opentelemetry.backend.OtlpGrpcBackend

try {
    def instance = Jenkins.getInstance()
    def config = JenkinsOpenTelemetryPluginConfiguration.get()
    
    // Determine if endpoint is HTTP or gRPC
    def endpoint = "${OTEL_ENDPOINT}"
    def isGrpc = endpoint.contains(":4317") || endpoint.matches(".*:\\d+\\/?\\s*\$")
    
    if (isGrpc || !endpoint.contains("/v1/traces")) {
        // gRPC endpoint
        def grpcEndpoint = endpoint.replaceAll("/v1/traces?\$", "").replaceAll("http://", "").replaceAll("https://", "")
        def backend = new OtlpGrpcBackend(grpcEndpoint, "", null)
        config.setBackend(backend)
        println "Configured gRPC endpoint: " + grpcEndpoint
    } else {
        // HTTP endpoint
        def httpEndpoint = endpoint.replaceAll("/v1/traces?\$", "")
        def backend = new OtlpHttpBackend(httpEndpoint, "", null)
        config.setBackend(backend)
        println "Configured HTTP endpoint: " + httpEndpoint
    }
    
    // Set service name
    config.setServiceName("${OTEL_SERVICE_NAME}")
    println "Service name set to: ${OTEL_SERVICE_NAME}"
    
    // Enable/disable
    config.setEnabled(${OTEL_ENABLED})
    println "OpenTelemetry enabled: ${OTEL_ENABLED}"
    
    // Save configuration
    config.save()
    instance.save()
    
    println "=========================================="
    println "OpenTelemetry configuration saved successfully!"
    println "=========================================="
    
} catch (Exception e) {
    println "Error configuring OpenTelemetry: \${e.message}"
    e.printStackTrace()
    System.exit(1)
}
GROOVY

# Execute configuration
echo ""
echo "=========================================="
echo "Applying configuration..."
echo "=========================================="
echo "Endpoint: $OTEL_ENDPOINT"
echo "Service Name: $OTEL_SERVICE_NAME"
echo "Enabled: $OTEL_ENABLED"
echo ""

java -jar /tmp/jenkins-cli.jar -s http://localhost:8080 -auth admin:$JENKINS_PASSWORD groovy = </tmp/configure-opentelemetry.groovy 2>&1 || {
    echo "Error: Failed to configure OpenTelemetry"
    echo "You may need to configure it manually via Jenkins UI:"
    echo "  Manage Jenkins → Configure System → OpenTelemetry"
    exit 1
}

echo ""
echo "=========================================="
echo "Configuration Complete!"
echo "=========================================="
echo ""
echo "Configuration summary:"
echo "  Endpoint: $OTEL_ENDPOINT"
echo "  Service Name: $OTEL_SERVICE_NAME"
echo "  Enabled: $OTEL_ENABLED"
echo ""
echo "Test the configuration:"
echo "  sudo bash Scripts/OpenTelemetry/test-opentelemetry.sh"
echo "=========================================="

