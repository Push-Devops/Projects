# Complete Testing Guide - Jenkins, Prometheus, Grafana Stack

## Prerequisites

1. Terraform deployment completed successfully
2. Instance is running (wait 10-15 minutes after deployment for all services to install)
3. You have SSH access to the instance
4. You know the instance public IP (from `terraform output`)

---

## Part 1: Infrastructure Testing

### Test 1.1: Verify Instance is Running

```bash
# Get instance IP
terraform output instance_public_ip

# Or check in AWS Console: EC2 → Instances
```

**Expected Result:** Instance should be in "running" state

### Test 1.2: Verify Network Connectivity

```bash
# SSH into the instance
ssh -i Monitoringweek4.pem ubuntu@<instance-ip>

# Test internet connectivity
ping -c 3 8.8.8.8

# Test DNS resolution
nslookup google.com
```

**Expected Result:** 
- Ping should succeed
- DNS should resolve

---

## Part 2: Jenkins Testing

### Test 2.1: Verify Jenkins Service Status

```bash
# On the server
sudo systemctl status jenkins
```

**Expected Result:**
- Status: `active (running)`
- No errors in the output

### Test 2.2: Verify Jenkins Port is Listening

```bash
# Check if port 8080 is listening
sudo ss -tlnp | grep 8080
# OR
sudo netstat -tlnp | grep 8080
```

**Expected Result:**
```
LISTEN  0  50  *:8080  *:*  users:(("java",pid=XXXX,fd=XX))
```

### Test 2.3: Access Jenkins Web UI

1. **Open browser:** `http://<instance-ip>:8080`
2. **Get initial password:**
   ```bash
   ssh -i Monitoringweek4.pem ubuntu@<instance-ip> 'sudo cat /var/lib/jenkins/secrets/initialAdminPassword'
   ```
3. **Login with:** `admin` / `<password-from-above>`

**Expected Result:**
- Jenkins login page loads
- Can login successfully
- Jenkins dashboard appears

### Test 2.4: Verify Jenkins Prometheus Plugin

1. **In Jenkins UI:**
   - Go to: **Manage Jenkins** → **Manage Plugins** → **Installed**
   - Search for: `Prometheus metrics`

**Expected Result:**
- Plugin should be listed as installed
- Status: Enabled

### Test 2.5: Verify Jenkins Metrics Endpoint

```bash
# From the server
curl -L http://localhost:8080/prometheus | head -50

# Should see metrics starting with jenkins_
```

**Expected Result:**
- HTTP 200 response
- Metrics visible like:
  - `jenkins_job_builds_total`
  - `jenkins_job_builds_success_total`
  - `jenkins_job_builds_failure_total`
  - `jenkins_executor_current_value`

### Test 2.6: Create Test Jenkins Job

1. **In Jenkins UI:**
   - Click: **New Item**
   - Name: `test-job`
   - Type: **Freestyle project**
   - Click **OK**
   - Scroll to **Build Steps**
   - Add build step: **Execute shell**
   - Command: `echo "Hello World from Jenkins"`
   - Click **Save**
   - Click **Build Now** (run it 2-3 times)

**Expected Result:**
- Job created successfully
- Builds complete successfully
- Build history shows completed builds

---

## Part 3: Prometheus Testing

### Test 3.1: Verify Prometheus Service Status

```bash
# On the server
sudo systemctl status prometheus
```

**Expected Result:**
- Status: `active (running)`
- No errors

### Test 3.2: Verify Prometheus Port is Listening

```bash
sudo ss -tlnp | grep 9090
```

**Expected Result:**
```
LISTEN  0  4096  *:9090  *:*  users:(("prometheus",pid=XXXX,fd=XX))
```

### Test 3.3: Access Prometheus Web UI

1. **Open browser:** `http://<instance-ip>:9090`
2. **Verify UI loads**

**Expected Result:**
- Prometheus UI loads
- Can see query interface
- Can see Status menu

### Test 3.4: Verify Prometheus Configuration

```bash
# On the server
sudo cat /etc/prometheus/prometheus.yml
```

**Expected Result:**
- Should see `job_name: 'prometheus'` targeting `localhost:9090`
- Should see `job_name: 'jenkins'` targeting `localhost:8080` with path `/prometheus`

### Test 3.5: Validate Prometheus Config

```bash
# On the server
sudo /usr/local/bin/promtool check config /etc/prometheus/prometheus.yml
```

**Expected Result:**
```
Checking /etc/prometheus/prometheus.yml
  SUCCESS: 0 rule files found
```

### Test 3.6: Check Prometheus Targets

1. **In Prometheus UI:**
   - Go to: **Status** → **Targets**
   - Or: `http://<instance-ip>:9090/targets`

**Expected Result:**
- `prometheus` target: **UP** (green)
- `jenkins` target: **UP** (green)
- If Jenkins is DOWN, check error message

### Test 3.7: Query Required Metrics

**In Prometheus UI, go to the query box and test each:**

#### Test 3.7.1: jenkins_job_last_build_duration_seconds
```
jenkins_job_last_build_duration_seconds
```
**Expected Result:** Returns metric values (may be empty if no jobs run yet)

#### Test 3.7.2: jenkins_job_last_build_result
```
jenkins_job_last_build_result
```
**Expected Result:** Returns metric with result values (0=success, 1=failure, etc.)

#### Test 3.7.3: jenkins_job_builds_success_total
```
jenkins_job_builds_success_total
```
**Expected Result:** Returns counter of successful builds

#### Test 3.7.4: jenkins_job_builds_failure_total
```
jenkins_job_builds_failure_total
```
**Expected Result:** Returns counter of failed builds

### Test 3.8: Query Expected Output Metrics

#### Test 3.8.1: Total Builds
```
sum(jenkins_job_builds_total)
```
**Expected Result:** Returns total number of builds

#### Test 3.8.2: Successful Builds
```
sum(jenkins_job_builds_success_total)
```
**Expected Result:** Returns total successful builds

#### Test 3.8.3: Failed/Unstable Builds
```
sum(jenkins_job_builds_failure_total)
```
**Expected Result:** Returns total failed builds

#### Test 3.8.4: Build Durations
```
jenkins_job_last_build_duration_seconds
```
**Expected Result:** Returns build duration in seconds for each job

#### Test 3.8.5: Queue Length
```
jenkins_queue_buildable_value
```
**Expected Result:** Returns number of jobs in queue

---

## Part 4: Grafana Testing

### Test 4.1: Verify Grafana Service Status

```bash
# On the server
sudo systemctl status grafana-server
```

**Expected Result:**
- Status: `active (running)`
- No errors

### Test 4.2: Verify Grafana Port is Listening

```bash
sudo ss -tlnp | grep 3000
```

**Expected Result:**
```
LISTEN  0  4096  *:3000  *:*  users:(("grafana",pid=XXXX,fd=XX))
```

### Test 4.3: Access Grafana Web UI

1. **Open browser:** `http://<instance-ip>:3000`
2. **Login:** `admin` / `admin`
3. **Change password** (if prompted)

**Expected Result:**
- Grafana login page loads
- Can login successfully
- Grafana home page appears

### Test 4.4: Verify Prometheus Data Source

1. **In Grafana UI:**
   - Go to: **Configuration** (gear icon) → **Data Sources**
   - Click on **Prometheus**

**Expected Result:**
- Prometheus data source is listed
- Status: **Working** (green checkmark)
- URL: `http://localhost:9090`
- Access: Proxy

**If not configured:**
- Click **Add data source**
- Select **Prometheus**
- URL: `http://localhost:9090`
- Click **Save & Test**
- Should show "Data source is working"

### Test 4.5: Test Data Source Query

1. **In Grafana UI:**
   - Go to: **Explore** (compass icon)
   - Select data source: **Prometheus**
   - Enter query: `up`
   - Click **Run query**

**Expected Result:**
- Query executes successfully
- Returns metric data
- Graph displays

---

## Part 5: Dashboard Testing

### Test 5.1: Access Jenkins CI/CD Dashboard

1. **In Grafana UI:**
   - Go to: **Dashboards** → **Browse**
   - Look for: **Jenkins CI/CD Overview**
   - Click to open

**Expected Result:**
- Dashboard loads
- All 8 panels are visible

### Test 5.2: Verify Dashboard Panels

Check each panel:

#### Panel 1: Total Builds (5m)
- **Location:** Top left
- **Query:** `sum(increase(jenkins_job_builds_total[5m]))`
- **Expected:** Shows number (may be 0 if no builds yet)

#### Panel 2: Successful Builds (5m)
- **Location:** Top center-left
- **Query:** `sum(increase(jenkins_job_builds_success_total[5m]))`
- **Expected:** Shows number, green color

#### Panel 3: Failed Builds (5m)
- **Location:** Top center-right
- **Query:** `sum(increase(jenkins_job_builds_failure_total[5m]))`
- **Expected:** Shows number, red color

#### Panel 4: Average Build Duration
- **Location:** Top right
- **Query:** `avg(jenkins_job_last_build_duration_seconds)`
- **Expected:** Shows duration in seconds

#### Panel 5: Executors Busy / Idle
- **Location:** Second row, left
- **Queries:** 
  - `jenkins_executor_current_value` (Busy)
  - `jenkins_executor_available_value` (Available)
- **Expected:** Shows executor counts

#### Panel 6: Build Duration Over Time
- **Location:** Second row, center
- **Type:** Time series graph
- **Query:** `jenkins_job_last_build_duration_seconds`
- **Expected:** Graph showing build durations over time

#### Panel 7: Build Results Over Time
- **Location:** Second row, right
- **Type:** Time series graph
- **Queries:**
  - `increase(jenkins_job_builds_success_total[5m])` (Success)
  - `increase(jenkins_job_builds_failure_total[5m])` (Failure)
- **Expected:** Graph showing success/failure trends

#### Panel 8: Queue Length
- **Location:** Third row, left
- **Type:** Time series graph
- **Query:** `jenkins_queue_buildable_value`
- **Expected:** Graph showing queue length over time

### Test 5.3: Fix "No Data" Errors

If panels show "No Data":

1. **Check if metrics exist:**
   ```bash
   curl http://localhost:8080/prometheus | grep jenkins_job
   ```

2. **Create and run Jenkins jobs:**
   - Create a test job in Jenkins
   - Run it multiple times
   - Wait 1-2 minutes for metrics to update

3. **Refresh dashboard:**
   - Click refresh icon in Grafana
   - Or change time range to "Last 1 hour"

4. **Verify Prometheus has data:**
   - Go to Prometheus: `http://<instance-ip>:9090`
   - Query: `jenkins_job_builds_total`
   - Should return data

---

## Part 6: Integration Testing

### Test 6.1: End-to-End Metrics Flow

1. **Create Jenkins Job:**
   - Create a new job in Jenkins
   - Run it 3-4 times

2. **Wait 2-3 minutes**

3. **Check Prometheus:**
   - Go to: `http://<instance-ip>:9090`
   - Query: `jenkins_job_builds_total`
   - Should show increased count

4. **Check Grafana Dashboard:**
   - Refresh dashboard
   - Panels should show updated data

**Expected Result:**
- Metrics flow from Jenkins → Prometheus → Grafana
- Dashboard shows real-time data
- All panels display correctly

### Test 6.2: Real-Time Updates

1. **Run a Jenkins build**
2. **Wait 30 seconds**
3. **Refresh Grafana dashboard**

**Expected Result:**
- Dashboard updates with new build data
- Counts increase
- Graphs show new data points

---

## Part 7: Validation Checklist

Use this checklist to verify everything is working:

### Infrastructure
- [ ] Instance is running
- [ ] Can SSH into instance
- [ ] All ports (22, 8080, 9090, 3000) are accessible

### Jenkins
- [ ] Jenkins service is running
- [ ] Jenkins UI accessible at port 8080
- [ ] Can login to Jenkins
- [ ] Prometheus plugin is installed
- [ ] Metrics endpoint `/prometheus` returns data
- [ ] Can create and run Jenkins jobs

### Prometheus
- [ ] Prometheus service is running
- [ ] Prometheus UI accessible at port 9090
- [ ] Prometheus config is valid
- [ ] Both targets (prometheus, jenkins) show as UP
- [ ] Can query `jenkins_job_builds_total`
- [ ] Can query `jenkins_job_builds_success_total`
- [ ] Can query `jenkins_job_builds_failure_total`
- [ ] Can query `jenkins_job_last_build_duration_seconds`
- [ ] Can query `jenkins_queue_buildable_value`

### Grafana
- [ ] Grafana service is running
- [ ] Grafana UI accessible at port 3000
- [ ] Can login to Grafana
- [ ] Prometheus data source is configured and working
- [ ] Can query Prometheus from Grafana Explore

### Dashboard
- [ ] Jenkins CI/CD Overview dashboard exists
- [ ] All 8 panels are visible
- [ ] Panel 1: Total Builds shows data
- [ ] Panel 2: Successful Builds shows data
- [ ] Panel 3: Failed Builds shows data
- [ ] Panel 4: Average Build Duration shows data
- [ ] Panel 5: Executors shows data
- [ ] Panel 6: Build Duration graph shows data
- [ ] Panel 7: Build Results graph shows data
- [ ] Panel 8: Queue Length graph shows data
- [ ] No "No Data" errors
- [ ] Dashboard refreshes automatically

---

## Troubleshooting Common Issues

### Issue: Jenkins metrics endpoint returns 302/403

**Solution:**
```bash
# Enable anonymous read access in Jenkins UI:
# Manage Jenkins → Configure Global Security → Matrix-based security
# Add 'anonymous' user with 'Read' permission
```

### Issue: Prometheus shows Jenkins as DOWN

**Solution:**
1. Check Jenkins is running: `sudo systemctl status jenkins`
2. Test endpoint: `curl http://localhost:8080/prometheus`
3. Check Prometheus logs: `sudo journalctl -u prometheus -n 50`

### Issue: Grafana shows "No Data"

**Solution:**
1. Verify data source: Configuration → Data Sources → Prometheus → Save & Test
2. Create Jenkins jobs and run them
3. Wait 2-3 minutes for metrics to be collected
4. Check time range in dashboard (set to "Last 1 hour")

### Issue: Dashboard panels show "No Data"

**Solution:**
1. Verify metrics exist in Prometheus first
2. Create and run Jenkins jobs
3. Check query syntax matches exactly
4. Verify time range includes when metrics were collected

---

## Quick Test Commands

Run these on the server for quick verification:

```bash
# All services status
sudo systemctl status jenkins prometheus grafana-server

# All ports listening
sudo ss -tlnp | grep -E ':(8080|9090|3000)'

# Test Jenkins metrics
curl -L http://localhost:8080/prometheus | grep jenkins_job | head -10

# Test Prometheus
curl http://localhost:9090/api/v1/query?query=up

# Test Grafana
curl http://localhost:3000/api/health
```

---

## Expected Final State

After all tests pass:

✅ **Jenkins:** Running, plugin installed, metrics exposed  
✅ **Prometheus:** Running, scraping Jenkins, all metrics queryable  
✅ **Grafana:** Running, data source connected, dashboard showing real-time data  
✅ **Integration:** Complete metrics pipeline working end-to-end  

All components should be fully functional and integrated!

