#!/bin/bash
# Script to validate Jenkins Prometheus metrics
# Run this on the server after setting up Jenkins metrics

echo "=========================================="
echo "Jenkins Prometheus Metrics Validation"
echo "=========================================="
echo ""

# Check if Jenkins metrics endpoint is accessible
echo "1. Testing Jenkins metrics endpoint..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -L http://localhost:8080/prometheus)

if [ "$HTTP_CODE" = "200" ]; then
    echo "   ✓ Metrics endpoint accessible (HTTP 200)"
else
    echo "   ✗ Metrics endpoint not accessible (HTTP $HTTP_CODE)"
    echo "   Fix: Enable anonymous read access in Jenkins security settings"
    exit 1
fi

echo ""
echo "2. Checking required metrics..."

# Required metrics to check
METRICS=(
    "jenkins_job_last_build_duration_seconds"
    "jenkins_job_last_build_result"
    "jenkins_job_builds_success_total"
    "jenkins_job_builds_failure_total"
)

ALL_FOUND=true
for metric in "${METRICS[@]}"; do
    if curl -s -L http://localhost:8080/prometheus | grep -q "^${metric}"; then
        echo "   ✓ $metric"
    else
        echo "   ✗ $metric (not found)"
        ALL_FOUND=false
    fi
done

echo ""
echo "3. Checking Prometheus targets..."
echo "   Visit: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):9090/targets"
echo "   Jenkins target should show as UP"

echo ""
echo "4. Testing Prometheus queries..."

# Get instance IP for Prometheus URL
INSTANCE_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

echo "   Test these queries in Prometheus UI:"
echo "   URL: http://$INSTANCE_IP:9090"
echo ""
echo "   Queries to test:"
echo "   - jenkins_job_builds_total"
echo "   - jenkins_job_builds_success_total"
echo "   - jenkins_job_builds_failure_total"
echo "   - jenkins_job_last_build_duration_seconds"
echo "   - jenkins_queue_buildable_value"

echo ""
echo "5. Expected Output Queries:"
echo ""
echo "   Total builds:"
echo "   sum(jenkins_job_builds_total)"
echo ""
echo "   Successful builds:"
echo "   sum(jenkins_job_builds_success_total)"
echo ""
echo "   Failed builds:"
echo "   sum(jenkins_job_builds_failure_total)"
echo ""
echo "   Build durations:"
echo "   jenkins_job_last_build_duration_seconds"
echo ""
echo "   Queue length:"
echo "   jenkins_queue_buildable_value"

echo ""
if [ "$ALL_FOUND" = true ]; then
    echo "=========================================="
    echo "✓ All required metrics found!"
    echo "=========================================="
else
    echo "=========================================="
    echo "✗ Some metrics missing - create Jenkins jobs and run them"
    echo "=========================================="
fi

