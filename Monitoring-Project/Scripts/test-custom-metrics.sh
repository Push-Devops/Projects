#!/bin/bash
# Test script to verify custom Jenkins metrics are working

echo "=========================================="
echo "Testing Custom Jenkins Metrics"
echo "=========================================="
echo ""

JENKINS_URL="${JENKINS_URL:-http://localhost:8080}"
METRICS_ENDPOINT="${JENKINS_URL}/prometheus"

echo "1. Checking if metrics endpoint is accessible..."
if curl -s -o /dev/null -w "%{http_code}" "${METRICS_ENDPOINT}" | grep -q "200"; then
    echo "✓ Metrics endpoint is accessible"
else
    echo "✗ Metrics endpoint not accessible (HTTP 200 expected)"
    echo "  Try: curl ${METRICS_ENDPOINT}"
    exit 1
fi

echo ""
echo "2. Checking for custom metrics..."
CUSTOM_METRICS=$(curl -s "${METRICS_ENDPOINT}" | grep "^jenkins_custom_")

if [ -z "$CUSTOM_METRICS" ]; then
    echo "✗ No custom metrics found!"
    echo "  Run the Groovy script in Jenkins Script Console first:"
    echo "  http://localhost:8080/script"
    exit 1
else
    echo "✓ Found custom metrics:"
    echo "$CUSTOM_METRICS" | head -10 | while read line; do
        METRIC_NAME=$(echo "$line" | awk '{print $1}')
        echo "  - $METRIC_NAME"
    done
fi

echo ""
echo "3. Sample metric values:"
echo "-----------------------"
curl -s "${METRICS_ENDPOINT}" | grep "^jenkins_custom_active_jobs" | head -1
curl -s "${METRICS_ENDPOINT}" | grep "^jenkins_custom_queued_items" | head -1
curl -s "${METRICS_ENDPOINT}" | grep "^jenkins_custom_total_build_duration_seconds" | head -1

echo ""
echo "4. List all custom metrics:"
echo "----------------------------"
curl -s "${METRICS_ENDPOINT}" | grep "^jenkins_custom_" | awk '{print $1}' | sort -u

echo ""
echo "=========================================="
echo "To query in Prometheus, use:"
echo "  jenkins_custom_active_jobs"
echo "  jenkins_custom_job_success_rate{job_name=\"your-job\"}"
echo "  jenkins_custom_deployments_total"
echo "=========================================="

