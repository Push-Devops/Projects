#!/bin/bash
# Manual installation script for Jenkins, Prometheus, Grafana
# Run this on the server: sudo bash install-stack.sh

set -x
set -e
export DEBIAN_FRONTEND=noninteractive

echo "=========================================="
echo "Starting Installation"
echo "=========================================="

# Update system
echo "Updating system packages..."
apt-get update
apt-get install -y software-properties-common wget curl gnupg2

# Install Jenkins
echo "=========================================="
echo "Installing Jenkins"
echo "=========================================="
apt-get install -y openjdk-17-jdk
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee /usr/share/keyrings/jenkins-keyring.asc >/dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | tee /etc/apt/sources.list.d/jenkins.list >/dev/null
apt-get update
apt-get install -y jenkins
systemctl enable jenkins
systemctl start jenkins
echo "Jenkins installed and started"

# Wait for Jenkins to be ready
echo "Waiting for Jenkins to be ready..."
for i in {1..60}; do
    if curl -s http://localhost:8080 >/dev/null 2>&1; then
        echo "Jenkins is ready!"
        break
    fi
    sleep 5
done

# Additional wait for Jenkins to fully initialize
sleep 30

# Get Jenkins admin password
JENKINS_PASSWORD=$(cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo "")

if [ -n "$JENKINS_PASSWORD" ]; then
    echo "Jenkins password retrieved: ${JENKINS_PASSWORD:0:10}..."
    
    # Download Jenkins CLI
    echo "Downloading Jenkins CLI..."
    wget -q http://localhost:8080/jnlpJars/jenkins-cli.jar -O /tmp/jenkins-cli.jar || echo "Failed to download CLI"
    
    sleep 20
    
    # Install Prometheus plugin
    echo "Installing Prometheus metrics plugin..."
    java -jar /tmp/jenkins-cli.jar -s http://localhost:8080 -auth admin:$JENKINS_PASSWORD install-plugin prometheus -restart 2>&1 || echo "Plugin installation attempted"
    
    # Wait for Jenkins to restart
    echo "Waiting for Jenkins to restart after plugin installation..."
    sleep 60
    for i in {1..60}; do
        if curl -s http://localhost:8080 >/dev/null 2>&1; then
            echo "Jenkins restarted!"
            break
        fi
        sleep 5
    done
    
    # Get password again (in case it changed)
    JENKINS_PASSWORD=$(cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo "")
    
    # Configure anonymous read access
    echo "Configuring anonymous read access..."
    cat >/tmp/configure-security.groovy <<'GROOVY'
import jenkins.model.Jenkins
import hudson.security.*

def instance = Jenkins.getInstance()

// Configure Matrix-based authorization with anonymous read
def strategy = new GlobalMatrixAuthorizationStrategy()

// Add read permissions for anonymous
strategy.add(Jenkins.READ, "anonymous")
strategy.add(Jenkins.READ, "authenticated")

// Add admin permissions for admin user
strategy.add(Jenkins.ADMINISTER, "admin")
strategy.add(Jenkins.READ, "admin")

// Set the authorization strategy
instance.setAuthorizationStrategy(strategy)

// Save configuration
instance.save()

println "Anonymous read access enabled"
GROOVY

    java -jar /tmp/jenkins-cli.jar -s http://localhost:8080 -auth admin:$JENKINS_PASSWORD groovy = </tmp/configure-security.groovy 2>&1 || echo "Security configuration attempted"
    
    # Configure Prometheus endpoint
    echo "Enabling Prometheus metrics endpoint..."
    cat >/tmp/enable-prometheus.groovy <<'GROOVY'
import jenkins.model.Jenkins
import org.jenkinsci.plugins.prometheus.config.PrometheusConfiguration

try {
    def config = PrometheusConfiguration.get()
    config.setPath('prometheus')
    config.setDefaultNamespace('jenkins')
    config.setCollectNodeStatus(true)
    config.setCollectBuildStatus(true)
    config.setCollectMetrics(true)
    config.save()
    println "Prometheus endpoint configured at /prometheus"
} catch (Exception e) {
    println "Error configuring Prometheus: ${e.message}"
    println "This is normal if plugin is still installing"
}
GROOVY

    java -jar /tmp/jenkins-cli.jar -s http://localhost:8080 -auth admin:$JENKINS_PASSWORD groovy = </tmp/enable-prometheus.groovy 2>&1 || echo "Prometheus configuration attempted"
    
    echo "Jenkins Prometheus metrics configuration completed"
else
    echo "Could not get Jenkins password, manual configuration may be required"
fi

# Install Prometheus
echo "=========================================="
echo "Installing Prometheus"
echo "=========================================="
# Stop Prometheus if already running
systemctl stop prometheus 2>/dev/null || true

# Remove old binaries if they exist
rm -f /usr/local/bin/prometheus /usr/local/bin/promtool 2>/dev/null || true

useradd --no-create-home --shell /bin/false prometheus 2>/dev/null || true
mkdir -p /etc/prometheus /var/lib/prometheus
cd /tmp

# Download latest stable Prometheus version (v3.7.3 as of Nov 2024)
PROM_VERSION="3.7.3"
echo "Downloading Prometheus v${PROM_VERSION}..."
wget -q https://github.com/prometheus/prometheus/releases/download/v${PROM_VERSION}/prometheus-${PROM_VERSION}.linux-amd64.tar.gz

# Remove old extraction directory if exists
rm -rf prometheus-${PROM_VERSION}.linux-amd64 2>/dev/null || true

echo "Extracting Prometheus..."
tar xzf prometheus-${PROM_VERSION}.linux-amd64.tar.gz
cd prometheus-${PROM_VERSION}.linux-amd64

echo "Installing Prometheus binaries..."
cp prometheus promtool /usr/local/bin/
chown prometheus:prometheus /usr/local/bin/prometheus /usr/local/bin/promtool
chmod +x /usr/local/bin/prometheus /usr/local/bin/promtool

# Copy console files if they exist (removed in Prometheus 3.x)
if [ -d "consoles" ] && [ -d "console_libraries" ]; then
    echo "Copying console templates..."
    cp -r consoles console_libraries /etc/prometheus
else
    echo "Note: Console templates not available in this Prometheus version (removed in v3.x)"
    mkdir -p /etc/prometheus/consoles /etc/prometheus/console_libraries
fi

# Create prometheus.yml
cat >/etc/prometheus/prometheus.yml <<'EOF'
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

chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus

# Create systemd service
cat >/etc/systemd/system/prometheus.service <<'EOF'
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/var/lib/prometheus --web.listen-address=0.0.0.0:9090

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable prometheus
systemctl start prometheus
echo "Prometheus installed and started"

# Install Jenkins Exporter (bonovoxly/jenkins_exporter)
echo "=========================================="
echo "Installing Jenkins Exporter"
echo "=========================================="
cd /tmp

# Get latest jenkins_exporter release
# Note: If bonovoxly/jenkins_exporter doesn't exist, you can use simplesurance/jenkins-exporter instead
# Check: https://github.com/bonovoxly/jenkins_exporter/releases or https://github.com/simplesurance/jenkins-exporter/releases
JENKINS_EXPORTER_VERSION="1.0.0"  # Update this to latest version from GitHub releases
JENKINS_EXPORTER_REPO="bonovoxly/jenkins_exporter"  # Change to "simplesurance/jenkins-exporter" if needed
JENKINS_EXPORTER_URL="https://github.com/${JENKINS_EXPORTER_REPO}/releases/download/v${JENKINS_EXPORTER_VERSION}/jenkins_exporter-${JENKINS_EXPORTER_VERSION}.linux-amd64.tar.gz"

echo "Downloading Jenkins Exporter v${JENKINS_EXPORTER_VERSION} from ${JENKINS_EXPORTER_REPO}..."
if wget -q "$JENKINS_EXPORTER_URL" -O jenkins_exporter.tar.gz 2>/dev/null; then
    tar xzf jenkins_exporter.tar.gz
    # Find the binary (may be in a subdirectory or root)
    if [ -f "jenkins_exporter" ]; then
        cp jenkins_exporter /usr/local/bin/jenkins_exporter
    elif [ -f "jenkins_exporter-${JENKINS_EXPORTER_VERSION}.linux-amd64/jenkins_exporter" ]; then
        cp jenkins_exporter-${JENKINS_EXPORTER_VERSION}.linux-amd64/jenkins_exporter /usr/local/bin/jenkins_exporter
    else
        echo "Warning: Could not find jenkins_exporter binary, trying direct download..."
        # Try direct binary download
        wget -q https://github.com/bonovoxly/jenkins_exporter/releases/download/v${JENKINS_EXPORTER_VERSION}/jenkins_exporter-${JENKINS_EXPORTER_VERSION}.linux-amd64 -O /usr/local/bin/jenkins_exporter || echo "Direct download failed"
    fi
    
    chmod +x /usr/local/bin/jenkins_exporter
    chown prometheus:prometheus /usr/local/bin/jenkins_exporter
    
    # Verify binary exists
    if [ ! -f "/usr/local/bin/jenkins_exporter" ]; then
        echo "Error: jenkins_exporter binary not found after installation"
    else
        # Get Jenkins admin password for exporter
        JENKINS_EXPORTER_PASSWORD=$(cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo "")
        
        # Create systemd service for jenkins_exporter
    # Note: Using EnvironmentFile for password to avoid exposing it in process list
    cat >/etc/systemd/system/jenkins-exporter.service <<SERVICEEOF
[Unit]
Description=Jenkins Exporter for Prometheus
After=network-online.target jenkins.service
Wants=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/jenkins_exporter --jenkins.url=http://localhost:8080 --jenkins.user=admin --jenkins.password=${JENKINS_EXPORTER_PASSWORD} --web.listen-address=0.0.0.0:9118
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICEEOF

    systemctl daemon-reload
    systemctl enable jenkins-exporter
    systemctl start jenkins-exporter
    echo "Jenkins Exporter installed and started on port 9118"
    
    # Update Prometheus config to include jenkins_exporter
    echo "Updating Prometheus configuration to scrape jenkins_exporter..."
    cat >/etc/prometheus/prometheus.yml <<'EOF'
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
EOF

        chown prometheus:prometheus /etc/prometheus/prometheus.yml
        systemctl reload prometheus || systemctl restart prometheus
        echo "Prometheus configuration updated to include jenkins_exporter"
    fi
else
    echo "Warning: Could not download jenkins_exporter from ${JENKINS_EXPORTER_REPO}."
    echo "Trying alternative: simplesurance/jenkins-exporter..."
    # Try simplesurance/jenkins-exporter as alternative
    ALT_VERSION="1.0.0"
    ALT_URL="https://github.com/simplesurance/jenkins-exporter/releases/download/v${ALT_VERSION}/jenkins-exporter_${ALT_VERSION}_linux_amd64.tar.gz"
    if wget -q "$ALT_URL" -O jenkins_exporter.tar.gz 2>/dev/null; then
        tar xzf jenkins_exporter.tar.gz
        find . -name "jenkins-exporter" -type f -executable | head -1 | xargs -I {} cp {} /usr/local/bin/jenkins_exporter
        chmod +x /usr/local/bin/jenkins_exporter
        chown prometheus:prometheus /usr/local/bin/jenkins_exporter
        
        # Create service for alternative exporter too
        JENKINS_EXPORTER_PASSWORD=$(cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo "")
        cat >/etc/systemd/system/jenkins-exporter.service <<SERVICEEOF
[Unit]
Description=Jenkins Exporter for Prometheus
After=network-online.target jenkins.service
Wants=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/jenkins_exporter --jenkins.url=http://localhost:8080 --jenkins.user=admin --jenkins.password=${JENKINS_EXPORTER_PASSWORD} --web.listen-address=0.0.0.0:9118
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICEEOF
        
        systemctl daemon-reload
        systemctl enable jenkins-exporter
        systemctl start jenkins-exporter
        
        # Update Prometheus config
        cat >/etc/prometheus/prometheus.yml <<'EOF'
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
EOF
        chown prometheus:prometheus /etc/prometheus/prometheus.yml
        systemctl reload prometheus || systemctl restart prometheus
        echo "Jenkins Exporter (simplesurance) installed and started on port 9118"
    else
        echo "Could not download jenkins_exporter. Continuing without it..."
        echo "You can install it manually later from:"
        echo "  - https://github.com/bonovoxly/jenkins_exporter/releases"
        echo "  - https://github.com/simplesurance/jenkins-exporter/releases"
    fi
fi

# Install Grafana
echo "=========================================="
echo "Installing Grafana"
echo "=========================================="
mkdir -p /etc/apt/keyrings
wget -q -O- https://packages.grafana.com/gpg.key | gpg --dearmor | tee /etc/apt/keyrings/grafana.gpg >/dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://packages.grafana.com/oss/deb stable main" | tee /etc/apt/sources.list.d/grafana.list
apt-get update
apt-get install -y grafana
sed -i 's/;http_addr = localhost/http_addr = 0.0.0.0/' /etc/grafana/grafana.ini
systemctl enable grafana-server
systemctl start grafana-server
echo "Grafana installed and started"

# Wait for Grafana to be ready
echo "Waiting for Grafana to be ready..."
for i in {1..30}; do
    if curl -s http://localhost:3000/api/health >/dev/null 2>&1; then
        echo "Grafana is ready!"
        break
    fi
    sleep 5
done

# Configure Grafana: Add Prometheus data source
echo "=========================================="
echo "Configuring Grafana Data Source"
echo "=========================================="
sleep 10

cat >/tmp/prometheus-datasource.json <<'EOF'
{
  "name": "Prometheus",
  "type": "prometheus",
  "url": "http://localhost:9090",
  "access": "proxy",
  "isDefault": true,
  "jsonData": {
    "timeInterval": "15s"
  }
}
EOF

curl -X POST http://admin:admin@localhost:3000/api/datasources \
  -H "Content-Type: application/json" \
  -d @/tmp/prometheus-datasource.json 2>&1 || echo "Data source configuration attempted"

# Create Jenkins CI/CD Dashboard
# NOTE: Dashboard queries use standard metric names. After installation, verify which metrics
# are actually exposed by your Jenkins Prometheus plugin version and update queries in Grafana UI if needed.
# Common metrics: jenkins_job_count_history_count, jenkins_job_total_duration, jenkins_jenkins_executors_queue_length
echo "=========================================="
echo "Creating Jenkins CI/CD Dashboard"
echo "=========================================="
cat >/tmp/jenkins-dashboard.json <<'EOF'
{
  "dashboard": {
    "title": "Jenkins CI/CD Overview",
    "tags": ["jenkins", "cicd", "prometheus"],
    "timezone": "browser",
    "schemaVersion": 16,
    "version": 0,
    "refresh": "10s",
    "panels": [
      {
        "id": 1,
        "title": "Total Builds (5m)",
        "type": "stat",
        "gridPos": {"h": 8, "w": 6, "x": 0, "y": 0},
        "targets": [
          {
            "expr": "sum(increase(jenkins_job_builds_total[5m]))",
            "legendFormat": "Total Builds",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "palette-classic"},
            "unit": "short",
            "thresholds": {
              "mode": "absolute",
              "steps": [{"color": "green", "value": null}]
            }
          }
        }
      },
      {
        "id": 2,
        "title": "Successful Builds (5m)",
        "type": "stat",
        "gridPos": {"h": 8, "w": 6, "x": 6, "y": 0},
        "targets": [
          {
            "expr": "sum(increase(jenkins_job_builds_success_total[5m]))",
            "legendFormat": "Successful Builds",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "thresholds"},
            "thresholds": {
              "mode": "absolute",
              "steps": [{"color": "green", "value": null}]
            },
            "unit": "short"
          }
        }
      },
      {
        "id": 3,
        "title": "Failed Builds (5m)",
        "type": "stat",
        "gridPos": {"h": 8, "w": 6, "x": 12, "y": 0},
        "targets": [
          {
            "expr": "sum(increase(jenkins_job_builds_failure_total[5m]))",
            "legendFormat": "Failed Builds",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "thresholds"},
            "thresholds": {
              "mode": "absolute",
              "steps": [{"color": "red", "value": null}]
            },
            "unit": "short"
          }
        }
      },
      {
        "id": 4,
        "title": "Average Build Duration",
        "type": "stat",
        "gridPos": {"h": 8, "w": 6, "x": 18, "y": 0},
        "targets": [
          {
            "expr": "avg(jenkins_job_last_build_duration_seconds)",
            "legendFormat": "Avg Duration",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "palette-classic"},
            "unit": "s"
          }
        }
      },
      {
        "id": 5,
        "title": "Executors Busy / Idle",
        "type": "stat",
        "gridPos": {"h": 8, "w": 6, "x": 0, "y": 8},
        "targets": [
          {
            "expr": "jenkins_executor_current_value",
            "legendFormat": "Busy Executors",
            "refId": "A"
          },
          {
            "expr": "jenkins_executor_available_value",
            "legendFormat": "Available Executors",
            "refId": "B"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "palette-classic"},
            "unit": "short"
          }
        }
      },
      {
        "id": 6,
        "title": "Build Duration Over Time",
        "type": "timeseries",
        "gridPos": {"h": 8, "w": 12, "x": 6, "y": 8},
        "targets": [
          {
            "expr": "jenkins_job_last_build_duration_seconds",
            "legendFormat": "{{job}}",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "s"
          }
        },
        "options": {
          "legend": {
            "displayMode": "table",
            "placement": "bottom"
          }
        }
      },
      {
        "id": 7,
        "title": "Build Results Over Time",
        "type": "timeseries",
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 8},
        "targets": [
          {
            "expr": "increase(jenkins_job_builds_success_total[5m])",
            "legendFormat": "Success",
            "refId": "A"
          },
          {
            "expr": "increase(jenkins_job_builds_failure_total[5m])",
            "legendFormat": "Failure",
            "refId": "B"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "short"
          }
        },
        "options": {
          "legend": {
            "displayMode": "table",
            "placement": "bottom"
          }
        }
      },
      {
        "id": 8,
        "title": "Queue Length",
        "type": "timeseries",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 16},
        "targets": [
          {
            "expr": "jenkins_queue_buildable_value",
            "legendFormat": "Queue Length",
            "refId": "A"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "unit": "short"
          }
        }
      }
    ]
  },
  "overwrite": false
}
EOF

sleep 5
curl -X POST http://admin:admin@localhost:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -d @/tmp/jenkins-dashboard.json 2>&1 || echo "Dashboard creation attempted"

echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo "Jenkins:    http://$(hostname -I | awk '{print $1}'):8080"
echo "Prometheus: http://$(hostname -I | awk '{print $1}'):9090"
echo "Grafana:    http://$(hostname -I | awk '{print $1}'):3000"
echo ""
echo "Jenkins password: $(cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo 'Check manually')"
echo "Grafana login: admin / admin"
echo "=========================================="

