# Jenkins Prometheus Metrics Setup Guide

## Overview
This guide will help you set up Jenkins metrics collection with Prometheus.

## Prerequisites
- Jenkins, Prometheus, and Grafana are installed and running
- You can access Jenkins UI

## Step 1: Deploy Jenkins Prometheus Metrics Plugin

### Via Jenkins UI:

1. **Access Jenkins:**
   - URL: `http://<instance-ip>:8080`
   - Get admin password:
     ```bash
     ssh -i Monitoringweek4.pem ubuntu@<instance-ip> 'sudo cat /var/lib/jenkins/secrets/initialAdminPassword'
     ```

2. **Install Plugin:**
   - Go to: **Manage Jenkins** → **Manage Plugins** → **Available**
   - Search for: `Prometheus metrics`
   - Check the box and click **Install without restart**
   - Wait for installation to complete
   - Restart Jenkins if prompted

## Step 2: Expose /prometheus Endpoint

1. **Enable Metrics Endpoint:**
   - Go to: **Manage Jenkins** → **Configure System**
   - Scroll down to find **Prometheus** section
   - Check: **Enable access to Prometheus metrics**
   - Set **Path** to: `/prometheus` (if available)
   - Click **Save**

2. **Enable Anonymous Read Access (Required):**
   - Go to: **Manage Jenkins** → **Configure Global Security**
   - Under **Authorization**, select: **Matrix-based security**
   - Add user: `anonymous`
   - Give `anonymous` the **Read** permission
   - Ensure `admin` has all permissions
   - Click **Save**

## Step 3: Verify Prometheus Scrape Config

The Prometheus configuration is already set up in Terraform to scrape Jenkins. Verify it:

```bash
ssh -i Monitoringweek4.pem ubuntu@<instance-ip>

# Check Prometheus config
sudo cat /etc/prometheus/prometheus.yml

# Should see:
# - job_name: 'jenkins'
#   metrics_path: '/prometheus'
#   static_configs:
#     - targets: ['localhost:8080']
```

If not present, update it:

```bash
sudo tee /etc/prometheus/prometheus.yml > /dev/null << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'jenkins'
    metrics_path: '/prometheus'
    static_configs:
      - targets: ['localhost:8080']
    scrape_interval: 10s
    scrape_timeout: 5s
EOF

sudo chown prometheus:prometheus /etc/prometheus/prometheus.yml
sudo systemctl restart prometheus
```

## Step 4: Validate Metrics Exist

### Test 1: Verify Metrics Endpoint

```bash
# From the server
curl http://localhost:8080/prometheus | grep jenkins_job

# Should see metrics like:
# jenkins_job_last_build_duration_seconds
# jenkins_job_last_build_result
# jenkins_job_builds_success_total
# jenkins_job_builds_failure_total
```

### Test 2: Check Prometheus Targets

1. Go to: `http://<instance-ip>:9090/targets`
2. Verify `jenkins` target shows as **UP** (green)
3. If DOWN, check the error message

### Test 3: Query Metrics in Prometheus

Go to: `http://<instance-ip>:9090` and try these queries:

#### Required Metrics:
```
# Build duration
jenkins_job_last_build_duration_seconds

# Build result
jenkins_job_last_build_result

# Successful builds
jenkins_job_builds_success_total

# Failed builds
jenkins_job_builds_failure_total
```

#### Expected Output Queries:

**Total Builds:**
```
sum(jenkins_job_builds_total)
```

**Successful Builds:**
```
sum(jenkins_job_builds_success_total)
```

**Failed/Unstable Builds:**
```
sum(jenkins_job_builds_failure_total)
```

**Build Durations:**
```
jenkins_job_last_build_duration_seconds
```

**Queue Length:**
```
jenkins_queue_buildable_value
```

## Step 5: Create Test Jenkins Jobs

To generate metrics, create some test jobs:

1. Go to Jenkins → **New Item**
2. Create a **Freestyle project** (name it "test-job")
3. Add build step: `echo "Hello World"`
4. **Build** the job a few times
5. Check metrics in Prometheus

## Troubleshooting

### Metrics endpoint returns 302 or 403
- Enable anonymous read access in Jenkins security settings
- Ensure Prometheus plugin is installed and enabled

### Prometheus shows Jenkins as DOWN
- Check Jenkins is running: `sudo systemctl status jenkins`
- Test endpoint: `curl http://localhost:8080/prometheus`
- Check Prometheus logs: `sudo journalctl -u prometheus -n 50`

### No metrics showing
- Create at least one Jenkins job and run it
- Wait a few minutes for metrics to be collected
- Check scrape interval in Prometheus config

## Validation Checklist

- [ ] Jenkins Prometheus plugin installed
- [ ] Metrics endpoint enabled in Jenkins
- [ ] Anonymous read access enabled
- [ ] Prometheus config includes Jenkins scrape job
- [ ] Prometheus target shows Jenkins as UP
- [ ] Can query `jenkins_job_builds_total` in Prometheus
- [ ] Can query `jenkins_job_builds_success_total`
- [ ] Can query `jenkins_job_builds_failure_total`
- [ ] Can query `jenkins_job_last_build_duration_seconds`
- [ ] Can query `jenkins_queue_buildable_value`

## Expected Output

After completing all steps, you should be able to:

✅ Query **Total builds** in Prometheus  
✅ Query **Successful builds** in Prometheus  
✅ Query **Failed/unstable builds** in Prometheus  
✅ Query **Build durations** in Prometheus  
✅ Query **Queue length** in Prometheus  

All metrics visible and queryable in Prometheus UI at `http://<instance-ip>:9090`

