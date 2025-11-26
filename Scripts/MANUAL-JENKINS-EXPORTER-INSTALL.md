# Manual Jenkins Exporter Installation Guide

This guide walks you through manually installing `simplesurance/jenkins-exporter` on your server.

## Prerequisites

- Jenkins is running and accessible at `http://localhost:8080`
- Prometheus is installed and running
- You have sudo/root access
- You know your Jenkins admin username (usually `admin`)

## Step 1: Download the Jenkins Exporter

### Option A: Download from GitHub Releases (Recommended)

1. Visit the releases page: https://github.com/simplesurance/jenkins-exporter/releases
2. Find the latest release (currently v0.8.0)
3. Download the Linux AMD64 binary:
   ```bash
   cd /tmp
   wget https://github.com/simplesurance/jenkins-exporter/releases/download/v0.8.0/jenkins-exporter_0.8.0_linux_amd64.tar.gz
   ```

### Option B: Download Specific Version

If v0.8.0 doesn't work, try other versions:
```bash
# Try v0.7.0
wget https://github.com/simplesurance/jenkins-exporter/releases/download/v0.7.0/jenkins-exporter_0.7.0_linux_amd64.tar.gz

# Or v0.6.0
wget https://github.com/simplesurance/jenkins-exporter/releases/download/v0.6.0/jenkins-exporter_0.6.0_linux_amd64.tar.gz
```

## Step 2: Extract and Install the Binary

```bash
# Extract the archive
tar xzf jenkins-exporter_*.tar.gz

# Find the binary (it might be in a subdirectory or root)
ls -la

# Copy to /usr/local/bin
cp jenkins-exporter /usr/local/bin/jenkins_exporter

# Or if it's in a subdirectory:
# cp jenkins-exporter_*/jenkins-exporter /usr/local/bin/jenkins_exporter

# Make it executable
chmod +x /usr/local/bin/jenkins_exporter

# Set ownership
chown prometheus:prometheus /usr/local/bin/jenkins_exporter
# Or if prometheus user doesn't exist:
# chown root:root /usr/local/bin/jenkins_exporter
```

## Step 3: Create Jenkins API Token

Since your Jenkins is already configured, you need an API token instead of the initial password:

1. **Login to Jenkins Web UI**: `http://YOUR_SERVER_IP:8080`
2. **Go to**: `Manage Jenkins` → `Users` → Click on `admin` (or your username)
3. **Click**: `Configure` (on the left sidebar)
4. **Scroll down** to `API Token` section
5. **Click**: `Add new Token` → Give it a name (e.g., "prometheus-exporter")
6. **Click**: `Generate`
7. **Copy the token** (you'll only see it once!)

**Alternative: If you know your Jenkins password, you can use that instead of API token.**

## Step 4: Create Systemd Service

Create the service file:

```bash
sudo nano /etc/systemd/system/jenkins-exporter.service
```

Paste the following content (replace `YOUR_API_TOKEN` with your actual token):

```ini
[Unit]
Description=Jenkins Exporter for Prometheus
After=network-online.target jenkins.service
Wants=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/jenkins_exporter \
  --jenkins.url=http://localhost:8080 \
  --jenkins.user=admin \
  --jenkins.pass=YOUR_API_TOKEN \
  --web.listen-address=0.0.0.0:9118
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**Important Notes:**
- Replace `YOUR_API_TOKEN` with the token you copied in Step 3
- If your Jenkins username is not `admin`, change `--jenkins.user=admin`
- If `prometheus` user doesn't exist, change `User=prometheus` to `User=root` and `Group=prometheus` to `Group=root`

## Step 5: Start the Service

```bash
# Reload systemd to recognize the new service
sudo systemctl daemon-reload

# Enable to start on boot
sudo systemctl enable jenkins-exporter

# Start the service
sudo systemctl start jenkins-exporter

# Check status
sudo systemctl status jenkins-exporter
```

## Step 6: Verify the Exporter is Working

```bash
# Check if it's listening on port 9118
sudo ss -tlnp | grep 9118

# Test the metrics endpoint
curl http://localhost:9118/metrics | head -20

# Look for Jenkins-specific metrics
curl http://localhost:9118/metrics | grep jenkins
```

You should see metrics like:
- `jenkins_builds_total`
- `jenkins_builds_success_total`
- `jenkins_builds_failure_total`
- etc.

## Step 7: Configure Prometheus

Add the exporter to Prometheus configuration:

```bash
# Backup existing config
sudo cp /etc/prometheus/prometheus.yml /etc/prometheus/prometheus.yml.backup

# Edit the config
sudo nano /etc/prometheus/prometheus.yml
```

Add this job to the `scrape_configs` section:

```yaml
scrape_configs:
  # ... existing jobs ...
  
  - job_name: 'jenkins_exporter'
    static_configs:
      - targets: ['localhost:9118']
    scrape_interval: 10s
    scrape_timeout: 5s
```

**Full example `prometheus.yml`:**

```yaml
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

  - job_name: 'jenkins_exporter'
    static_configs:
      - targets: ['localhost:9118']
    scrape_interval: 10s
    scrape_timeout: 5s
```

Reload Prometheus:

```bash
# Reload config (preferred - doesn't restart service)
sudo systemctl reload prometheus

# Or restart if reload doesn't work
sudo systemctl restart prometheus
```

## Step 8: Verify in Prometheus

1. **Open Prometheus UI**: `http://YOUR_SERVER_IP:9090`
2. **Go to**: `Status` → `Targets`
3. **Check**: `jenkins_exporter` target should show as `UP`
4. **Test query**: In the query box, try:
   ```
   jenkins_builds_total
   ```

## Troubleshooting

### Service won't start

```bash
# Check service logs
sudo journalctl -u jenkins-exporter -f

# Common issues:
# 1. Authentication failed - check API token
# 2. Jenkins URL wrong - verify http://localhost:8080 is accessible
# 3. Permission denied - check file ownership
```

### Authentication Errors

If you see authentication errors in logs:

1. **Verify API token** is correct in the service file
2. **Test manually**:
   ```bash
   /usr/local/bin/jenkins_exporter \
     --jenkins.url=http://localhost:8080 \
     --jenkins.user=admin \
     --jenkins.pass=YOUR_TOKEN \
     --web.listen-address=0.0.0.0:9118
   ```
3. **Check Jenkins security settings** - ensure API tokens are enabled

### Port Already in Use

If port 9118 is already in use:

```bash
# Check what's using the port
sudo lsof -i :9118

# Change port in service file (e.g., to 9119)
# Update both service file and prometheus.yml
```

### Prometheus Target Down

1. **Check exporter is running**: `sudo systemctl status jenkins-exporter`
2. **Check metrics endpoint**: `curl http://localhost:9118/metrics`
3. **Verify Prometheus config**: `sudo promtool check config /etc/prometheus/prometheus.yml`
4. **Check Prometheus logs**: `sudo journalctl -u prometheus -f`

## Quick Verification Commands

```bash
# Check all services
sudo systemctl status jenkins prometheus jenkins-exporter

# Check ports
sudo ss -tlnp | grep -E ':(8080|9090|9118)'

# Test all endpoints
curl -I http://localhost:8080/prometheus
curl -I http://localhost:9090
curl -I http://localhost:9118/metrics

# Check Prometheus targets
curl http://localhost:9090/api/v1/targets | python3 -m json.tool
```

## Summary

After completing these steps, you should have:

✅ Jenkins Exporter running on port 9118  
✅ Prometheus scraping metrics from the exporter  
✅ Additional Jenkins metrics available in Prometheus  
✅ No disruption to existing services  

The exporter provides additional metrics beyond what the Jenkins Prometheus plugin offers, giving you more detailed build and stage information.

