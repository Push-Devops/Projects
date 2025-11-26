#!/bin/bash
# Install OpenTelemetry Plugin in Jenkins
# Run this script on the Jenkins server: sudo bash install-opentelemetry-plugin.sh

set -e

echo "=========================================="
echo "Installing OpenTelemetry Plugin in Jenkins"
echo "=========================================="

# Check if Jenkins is running
if ! systemctl is-active --quiet jenkins; then
    echo "Error: Jenkins is not running. Please start Jenkins first."
    exit 1
fi

# Wait for Jenkins to be fully ready
echo "Waiting for Jenkins to be ready..."
for i in {1..60}; do
    if curl -s http://localhost:8080 >/dev/null 2>&1; then
        echo "Jenkins is ready!"
        break
    fi
    echo "Waiting... ($i/60)"
    sleep 5
done

# Get Jenkins admin password
JENKINS_PASSWORD=$(cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo "")

if [ -z "$JENKINS_PASSWORD" ]; then
    echo "Warning: Could not get Jenkins initial admin password."
    echo "You may need to provide credentials manually."
    echo ""
    echo "Please provide Jenkins admin password:"
    read -s JENKINS_PASSWORD
fi

if [ -z "$JENKINS_PASSWORD" ]; then
    echo "Error: Jenkins password is required. Exiting."
    exit 1
fi

# Download Jenkins CLI
echo ""
echo "=========================================="
echo "Downloading Jenkins CLI..."
echo "=========================================="
wget -q http://localhost:8080/jnlpJars/jenkins-cli.jar -O /tmp/jenkins-cli.jar || {
    echo "Error: Failed to download Jenkins CLI"
    exit 1
}
echo "Jenkins CLI downloaded successfully"

# Check if plugin is already installed
echo ""
echo "Checking if OpenTelemetry plugin is already installed..."
INSTALLED=$(java -jar /tmp/jenkins-cli.jar -s http://localhost:8080 -auth admin:$JENKINS_PASSWORD list-plugins 2>/dev/null | grep -i opentelemetry || echo "")

if [ -n "$INSTALLED" ]; then
    echo "OpenTelemetry plugin is already installed:"
    echo "$INSTALLED"
    echo ""
    read -p "Do you want to reinstall? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled. Plugin already exists."
        exit 0
    fi
fi

# Install OpenTelemetry plugin
echo ""
echo "=========================================="
echo "Installing OpenTelemetry plugin..."
echo "=========================================="
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080 -auth admin:$JENKINS_PASSWORD install-plugin opentelemetry -restart 2>&1 || {
    echo "Error: Failed to install OpenTelemetry plugin"
    exit 1
}

echo "Plugin installation initiated. Jenkins will restart..."

# Wait for Jenkins to restart
echo ""
echo "=========================================="
echo "Waiting for Jenkins to restart..."
echo "=========================================="
sleep 10  # Initial wait

for i in {1..120}; do
    if curl -s http://localhost:8080 >/dev/null 2>&1; then
        echo "Jenkins has restarted and is ready!"
        break
    fi
    if [ $i -eq 120 ]; then
        echo "Warning: Jenkins did not restart within expected time. Please check manually."
        exit 1
    fi
    echo "Waiting for Jenkins to restart... ($i/120)"
    sleep 5
done

# Get password again (in case it changed)
JENKINS_PASSWORD=$(cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo "$JENKINS_PASSWORD")

# Verify plugin installation
echo ""
echo "=========================================="
echo "Verifying plugin installation..."
echo "=========================================="
sleep 10  # Extra wait for plugin to be fully loaded

VERIFY=$(java -jar /tmp/jenkins-cli.jar -s http://localhost:8080 -auth admin:$JENKINS_PASSWORD list-plugins 2>/dev/null | grep -i opentelemetry || echo "")

if [ -n "$VERIFY" ]; then
    echo "✓ OpenTelemetry plugin installed successfully!"
    echo "$VERIFY"
else
    echo "✗ Warning: Could not verify plugin installation"
    echo "Please check manually: Manage Jenkins → Manage Plugins → Installed"
fi

echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Configure OpenTelemetry endpoint in Jenkins:"
echo "   Manage Jenkins → Configure System → OpenTelemetry"
echo ""
echo "2. Or use the configuration script:"
echo "   sudo bash Scripts/OpenTelemetry/configure-opentelemetry.sh"
echo ""
echo "3. Test the installation:"
echo "   sudo bash Scripts/OpenTelemetry/test-opentelemetry.sh"
echo ""
echo "For detailed configuration, see:"
echo "Scripts/OpenTelemetry/INSTALL-OPENTELEMETRY-PLUGIN.md"
echo "=========================================="

