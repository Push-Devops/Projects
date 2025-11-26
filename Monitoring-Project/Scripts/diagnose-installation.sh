#!/bin/bash
# Diagnostic script to check installation status

echo "=========================================="
echo "Installation Diagnostic"
echo "=========================================="
echo ""

# Check cloud-init status
echo "1. Cloud-init Status:"
echo "-------------------"
cloud-init status 2>/dev/null || echo "Cloud-init not available"
echo ""

# Check if installation is still running
echo "2. Installation Progress:"
echo "-------------------"
if [ -f /root/stack-install.log ]; then
    echo "✓ Installation log found:"
    cat /root/stack-install.log
else
    echo "✗ Installation log not found (installation may still be running)"
fi
echo ""

# Check cloud-init output
echo "3. Cloud-init Output (last 50 lines):"
echo "-------------------"
if [ -f /var/log/cloud-init-output.log ]; then
    tail -50 /var/log/cloud-init-output.log
else
    echo "Cloud-init log not found"
fi
echo ""

# Check service status with details
echo "4. Service Status Details:"
echo "-------------------"
for service in jenkins prometheus grafana-server; do
    echo "--- $service ---"
    systemctl status $service --no-pager -l | head -15
    echo ""
done

# Check if processes are running
echo "5. Running Processes:"
echo "-------------------"
ps aux | grep -E "(jenkins|prometheus|grafana)" | grep -v grep || echo "No processes found"
echo ""

# Check installation timestamps
echo "6. Installation Timestamps:"
echo "-------------------"
echo "Current time: $(date)"
if [ -f /var/lib/jenkins/config.xml ]; then
    echo "Jenkins config created: $(stat -c %y /var/lib/jenkins/config.xml 2>/dev/null || echo 'N/A')"
fi
if [ -f /etc/prometheus/prometheus.yml ]; then
    echo "Prometheus config created: $(stat -c %y /etc/prometheus/prometheus.yml 2>/dev/null || echo 'N/A')"
fi
if [ -f /etc/grafana/grafana.ini ]; then
    echo "Grafana config created: $(stat -c %y /etc/grafana/grafana.ini 2>/dev/null || echo 'N/A')"
fi
echo ""

# Check for errors in logs
echo "7. Recent Errors:"
echo "-------------------"
journalctl -p err -n 20 --no-pager 2>/dev/null | grep -E "(jenkins|prometheus|grafana|cloud-init)" || echo "No recent errors found"
echo ""

# Check disk space
echo "8. Disk Space:"
echo "-------------------"
df -h / | tail -1
echo ""

echo "=========================================="
echo "Next Steps:"
echo "=========================================="
echo "If installation is still running, wait 10-15 minutes"
echo "If services failed, check:"
echo "  - sudo journalctl -u jenkins -n 50"
echo "  - sudo journalctl -u prometheus -n 50"
echo "  - sudo journalctl -u grafana-server -n 50"
echo "  - sudo tail -100 /var/log/cloud-init-output.log"
echo "=========================================="

