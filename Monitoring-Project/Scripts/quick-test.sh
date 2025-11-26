#!/bin/bash
# Quick testing script for all components
# Run this on the server after deployment

echo "=========================================="
echo "Quick Component Test"
echo "=========================================="
echo ""

# Get instance IP
INSTANCE_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || hostname -I | awk '{print $1}')

echo "Instance IP: $INSTANCE_IP"
echo ""

# Test 1: Service Status
echo "1. Service Status:"
echo "-------------------"
systemctl is-active jenkins && echo "✓ Jenkins: Running" || echo "✗ Jenkins: Not Running"
systemctl is-active prometheus && echo "✓ Prometheus: Running" || echo "✗ Prometheus: Not Running"
systemctl is-active grafana-server && echo "✓ Grafana: Running" || echo "✗ Grafana: Not Running"
echo ""

# Test 2: Ports Listening
echo "2. Ports Listening:"
echo "-------------------"
if ss -tlnp | grep -q ':8080'; then
    echo "✓ Port 8080 (Jenkins): Listening"
else
    echo "✗ Port 8080 (Jenkins): Not Listening"
fi

if ss -tlnp | grep -q ':9090'; then
    echo "✓ Port 9090 (Prometheus): Listening"
else
    echo "✗ Port 9090 (Prometheus): Not Listening"
fi

if ss -tlnp | grep -q ':3000'; then
    echo "✓ Port 3000 (Grafana): Listening"
else
    echo "✗ Port 3000 (Grafana): Not Listening"
fi
echo ""

# Test 3: Jenkins Metrics Endpoint
echo "3. Jenkins Metrics Endpoint:"
echo "----------------------------"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -L http://localhost:8080/prometheus)
if [ "$HTTP_CODE" = "200" ]; then
    echo "✓ Endpoint accessible (HTTP 200)"
    METRIC_COUNT=$(curl -s -L http://localhost:8080/prometheus | grep -c "^jenkins_job" || echo "0")
    echo "  Found $METRIC_COUNT jenkins_job metrics"
    if [ "$METRIC_COUNT" -gt 0 ]; then
        echo "  Sample metrics:"
        curl -s -L http://localhost:8080/prometheus | grep "^jenkins_job" | head -5 | sed 's/^/    /'
    fi
else
    echo "✗ Endpoint not accessible (HTTP $HTTP_CODE)"
    echo "  Fix: Enable anonymous read access in Jenkins"
fi
echo ""

# Test 4: Prometheus Targets
echo "4. Prometheus Targets:"
echo "---------------------"
if curl -s http://localhost:9090/api/v1/targets | grep -q '"health":"up"'; then
    echo "✓ At least one target is UP"
    echo "  Check details at: http://$INSTANCE_IP:9090/targets"
else
    echo "✗ No targets are UP"
    echo "  Check: http://$INSTANCE_IP:9090/targets"
fi
echo ""

# Test 5: Prometheus Queries
echo "5. Prometheus Metrics:"
echo "----------------------"
QUERIES=(
    "jenkins_job_builds_total"
    "jenkins_job_builds_success_total"
    "jenkins_job_builds_failure_total"
    "jenkins_job_last_build_duration_seconds"
    "jenkins_queue_buildable_value"
)

for query in "${QUERIES[@]}"; do
    RESULT=$(curl -s "http://localhost:9090/api/v1/query?query=$query" | grep -o '"result":\[' | wc -l)
    if [ "$RESULT" -gt 0 ]; then
        echo "✓ $query: Available"
    else
        echo "✗ $query: No data (create Jenkins jobs to generate metrics)"
    fi
done
echo ""

# Test 6: Grafana Data Source
echo "6. Grafana Data Source:"
echo "----------------------"
if curl -s http://admin:admin@localhost:3000/api/datasources 2>/dev/null | grep -q "Prometheus"; then
    echo "✓ Prometheus data source configured"
    # Test connection
    DS_TEST=$(curl -s http://admin:admin@localhost:3000/api/datasources/proxy/1/api/v1/query?query=up 2>/dev/null | grep -o '"status":"success"' || echo "")
    if [ -n "$DS_TEST" ]; then
        echo "✓ Data source connection working"
    else
        echo "✗ Data source connection failed"
    fi
else
    echo "✗ Prometheus data source not found"
fi
echo ""

# Test 7: Grafana Dashboard
echo "7. Grafana Dashboard:"
echo "--------------------"
DASHBOARD_COUNT=$(curl -s http://admin:admin@localhost:3000/api/search?query=Jenkins 2>/dev/null | grep -o '"title":"Jenkins CI/CD Overview"' | wc -l)
if [ "$DASHBOARD_COUNT" -gt 0 ]; then
    echo "✓ Jenkins CI/CD Overview dashboard exists"
    echo "  Access at: http://$INSTANCE_IP:3000/dashboards"
else
    echo "✗ Dashboard not found"
    echo "  May need to create manually"
fi
echo ""

# Summary
echo "=========================================="
echo "Service URLs:"
echo "=========================================="
echo "Jenkins:    http://$INSTANCE_IP:8080"
echo "Prometheus: http://$INSTANCE_IP:9090"
echo "Grafana:    http://$INSTANCE_IP:3000"
echo ""
echo "Jenkins initial password:"
echo "  sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
echo ""
echo "Grafana default login: admin / admin"
echo "=========================================="

