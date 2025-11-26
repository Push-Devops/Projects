# Custom Jenkins Metrics for Prometheus

This guide shows you how to create and export custom metrics from Jenkins to Prometheus.

## Overview

Jenkins can expose custom metrics through:
1. **Prometheus Plugin** - Using Groovy scripts to add custom metrics
2. **Custom Plugin** - Creating a Jenkins plugin (advanced)
3. **Script Console** - Quick testing via Groovy scripts
4. **Metrics Plugin API** - Programmatically adding metrics

## Method 1: Using Prometheus Plugin with Groovy Scripts (Recommended)

The Prometheus plugin allows you to add custom metrics via Groovy scripts.

### Step 1: Access Jenkins Script Console

1. Go to: `Manage Jenkins` → `Script Console`
2. Or access directly: `http://YOUR_JENKINS:8080/script`

### Step 2: Add Custom Metrics Script

Create a Groovy script that exposes custom metrics. Example:

```groovy
import io.prometheus.client.Gauge
import io.prometheus.client.Counter
import io.prometheus.client.Histogram
import jenkins.model.Jenkins
import hudson.model.Job

// Define custom metrics (these will be exposed automatically)
def customBuildCounter = Counter.build()
    .name("jenkins_custom_total_builds")
    .help("Total number of builds across all jobs")
    .register()

def customFailedJobs = Gauge.build()
    .name("jenkins_custom_failed_jobs")
    .help("Number of jobs with failed builds")
    .register()

def customJobHealth = Gauge.build()
    .name("jenkins_custom_job_health_score")
    .help("Health score of a job (0-100)")
    .labelNames("job_name")
    .register()

def customBuildDuration = Histogram.build()
    .name("jenkins_custom_build_duration_seconds")
    .help("Build duration in seconds")
    .labelNames("job_name", "status")
    .buckets(10, 30, 60, 120, 300, 600, 1800, 3600)
    .register()

// Calculate and set metrics
def instance = Jenkins.getInstance()
def jobs = instance.getAllItems(Job.class)

int totalBuilds = 0
int failedJobsCount = 0

jobs.each { job ->
    // Count total builds
    def runs = job.getBuilds()
    totalBuilds += runs.size()
    
    // Check if job has failures
    def lastBuild = job.getLastBuild()
    if (lastBuild != null && lastBuild.getResult() != null) {
        if (lastBuild.getResult().toString() == "FAILURE") {
            failedJobsCount++
        }
        
        // Set job health score
        def health = job.getBuildHealth()
        if (health != null) {
            customJobHealth.labels(job.getName()).set(health.getScore())
        }
        
        // Record build duration
        if (lastBuild.getDuration() > 0) {
            def durationSeconds = lastBuild.getDuration() / 1000.0
            def status = lastBuild.getResult()?.toString() ?: "UNKNOWN"
            customBuildDuration.labels(job.getName(), status).observe(durationSeconds)
        }
    }
}

// Set counter value (Note: counters are cumulative, so we increment)
// For absolute values, use Gauge instead
customFailedJobs.set(failedJobsCount)

println "Custom metrics updated:"
println "  Total builds: ${totalBuilds}"
println "  Failed jobs: ${failedJobsCount}"
```

### Step 3: Create a Script File for Persistent Execution

To run this automatically, create a file on the Jenkins server:

```bash
# On Jenkins server
sudo nano /var/lib/jenkins/init.groovy.d/custom-metrics.groovy
```

Paste your Groovy script there. Jenkins will execute it during startup.

**OR** run it periodically using a Jenkins job:

1. Create a new Jenkins job (Freestyle project)
2. Add "Execute Groovy script" build step
3. Set to run periodically: `H/5 * * * *` (every 5 minutes)

## Method 2: Using Jenkins Metrics Plugin API

If you have the Metrics plugin installed, you can use its API:

### Example: Custom Counter

```groovy
import com.codahale.metrics.MetricRegistry
import jenkins.model.Jenkins

def instance = Jenkins.getInstance()
def registry = instance.getExtensionList(com.codahale.metrics.MetricRegistry.class)[0]

// Create custom counter
def customCounter = registry.counter("custom.jenkins.deployments.total")
customCounter.inc()

// Create custom gauge
def customGauge = registry.register("custom.jenkins.active.jobs", 
    new com.codahale.metrics.Gauge<Integer>() {
        @Override
        Integer getValue() {
            return Jenkins.getInstance().getAllItems(Job.class).size()
        }
    }
)
```

## Method 3: Custom Plugin (Advanced)

For production use, create a Jenkins plugin that exposes custom metrics.

### Step 1: Create Plugin Structure

```bash
# Install Jenkins plugin development tools
# Follow: https://www.jenkins.io/doc/developer/plugin-development/
```

### Step 2: Example Plugin Code

**src/main/java/io/example/CustomMetricsAction.java:**

```java
package io.example;

import hudson.Extension;
import hudson.model.RootAction;
import io.prometheus.client.Gauge;
import io.prometheus.client.CollectorRegistry;
import jenkins.model.Jenkins;

@Extension
public class CustomMetricsAction implements RootAction {
    
    private static final Gauge customMetric = Gauge.build()
        .name("jenkins_custom_metric_example")
        .help("Example custom metric")
        .register();
    
    @Override
    public String getIconFileName() {
        return null;
    }
    
    @Override
    public String getDisplayName() {
        return null;
    }
    
    @Override
    public String getUrlName() {
        return "custom-metrics";
    }
    
    public void updateMetrics() {
        // Update your custom metrics here
        int activeJobs = Jenkins.getInstance().getAllItems(Job.class).size();
        customMetric.set(activeJobs);
    }
}
```

## Method 4: Using Script Console for Quick Testing

For quick testing, use the Script Console directly:

### Example 1: Count Active Jobs

```groovy
import jenkins.model.Jenkins

def instance = Jenkins.getInstance()
def activeJobs = instance.getAllItems(Job.class).size()

println "Active jobs: ${activeJobs}"

// Expose as metric (if Prometheus plugin is installed)
def metric = io.prometheus.client.Gauge.build()
    .name("jenkins_active_jobs_custom")
    .help("Number of active Jenkins jobs")
    .register()

metric.set(activeJobs)
```

### Example 2: Track Deployment Frequency

```groovy
import jenkins.model.Jenkins
import hudson.model.Job

def instance = Jenkins.getInstance()
def jobs = instance.getAllItems(Job.class)

def deploymentCounter = io.prometheus.client.Counter.build()
    .name("jenkins_deployments_total")
    .help("Total number of deployments")
    .labelNames("environment")
    .register()

// Count deployments by environment (assuming job name contains environment)
jobs.each { job ->
    def name = job.getName().toLowerCase()
    def env = "unknown"
    
    if (name.contains("prod") || name.contains("production")) {
        env = "production"
    } else if (name.contains("staging") || name.contains("stage")) {
        env = "staging"
    } else if (name.contains("dev") || name.contains("development")) {
        env = "development"
    }
    
    deploymentCounter.labels(env).inc(job.getBuilds().size())
}
```

### Example 3: Track Job Success Rate

```groovy
import jenkins.model.Jenkins
import hudson.model.Job
import io.prometheus.client.Gauge

def successRateGauge = Gauge.build()
    .name("jenkins_job_success_rate")
    .help("Success rate of a job (0-100)")
    .labelNames("job_name")
    .register()

def instance = Jenkins.getInstance()
def jobs = instance.getAllItems(Job.class)

jobs.each { job ->
    def builds = job.getBuilds()
    if (builds.size() > 0) {
        def successful = builds.findAll { 
            it.getResult()?.toString() == "SUCCESS" 
        }.size()
        def rate = (successful / builds.size()) * 100
        successRateGauge.labels(job.getName()).set(rate)
    }
}
```

## Method 5: Scheduled Metrics Update Job

Create a Jenkins job that updates custom metrics periodically:

1. **Create a Pipeline Job** named `update-custom-metrics`

2. **Pipeline Script:**

```groovy
pipeline {
    agent any
    
    triggers {
        cron('H/5 * * * *')  // Every 5 minutes
    }
    
    stages {
        stage('Update Metrics') {
            steps {
                script {
                    // Your custom metrics code here
                    def instance = jenkins.model.Jenkins.getInstance()
                    def jobs = instance.getAllItems(hudson.model.Job.class)
                    
                    // Example: Track number of jobs
                    def metric = io.prometheus.client.Gauge.build()
                        .name("jenkins_custom_job_count")
                        .help("Total number of Jenkins jobs")
                        .register()
                    
                    metric.set(jobs.size())
                    
                    echo "Updated custom metrics: ${jobs.size()} jobs"
                }
            }
        }
    }
}
```

## Accessing Custom Metrics

After creating custom metrics, they will be automatically available at:

```
http://localhost:8080/prometheus
```

Prometheus will scrape them along with other Jenkins metrics.

### Query in Prometheus

Once Prometheus is scraping, you can query:

```promql
# Your custom metrics
jenkins_custom_total_builds
jenkins_custom_failed_jobs
jenkins_custom_job_health_score{job_name="my-job"}
jenkins_custom_build_duration_seconds{job_name="my-job"}
```

## Best Practices

### 1. Naming Conventions

- Prefix custom metrics with `jenkins_custom_` to distinguish them
- Use lowercase with underscores
- Be descriptive: `jenkins_custom_deployment_count` not `jenkins_dc`

### 2. Metric Types

- **Counter**: For values that only increase (build counts, deployments)
- **Gauge**: For values that can go up/down (active jobs, queue length)
- **Histogram**: For distributions (build duration, queue wait time)

### 3. Labels

Use labels for dimensions:
```groovy
Gauge.build()
    .name("jenkins_custom_build_count")
    .labelNames("job_name", "branch", "status")
    .register()
```

### 4. Performance

- Don't query Jenkins API too frequently
- Cache results when possible
- Use asynchronous updates for heavy operations

### 5. Error Handling

```groovy
try {
    // Your metric update code
    customMetric.set(value)
} catch (Exception e) {
    println "Error updating metrics: ${e.message}"
    // Don't fail the entire script
}
```

## Complete Example: Comprehensive Custom Metrics

Here's a complete example that tracks multiple custom metrics:

```groovy
import jenkins.model.Jenkins
import hudson.model.Job
import hudson.model.Queue
import io.prometheus.client.*

def instance = Jenkins.getInstance()

// Custom Metrics Definitions
def customActiveJobs = Gauge.build()
    .name("jenkins_custom_active_jobs")
    .help("Number of active Jenkins jobs")
    .register()

def customQueuedItems = Gauge.build()
    .name("jenkins_custom_queued_items")
    .help("Number of items in build queue")
    .register()

def customJobBuildsTotal = Counter.build()
    .name("jenkins_custom_job_builds_total")
    .help("Total builds per job")
    .labelNames("job_name", "job_type")
    .register()

def customJobLastBuildAge = Gauge.build()
    .name("jenkins_custom_job_last_build_age_seconds")
    .help("Age of last build in seconds")
    .labelNames("job_name")
    .register()

def customJobSuccessRate = Gauge.build()
    .name("jenkins_custom_job_success_rate")
    .help("Success rate percentage (0-100)")
    .labelNames("job_name")
    .register()

// Update Metrics
def jobs = instance.getAllItems(Job.class)
customActiveJobs.set(jobs.size())

// Queue length
def queue = Queue.getInstance()
customQueuedItems.set(queue.getItems().size())

// Job-specific metrics
jobs.each { job ->
    def jobName = job.getName()
    def jobType = job.getClass().getSimpleName()
    
    def builds = job.getBuilds()
    if (builds.size() > 0) {
        // Total builds
        customJobBuildsTotal.labels(jobName, jobType).inc(builds.size())
        
        // Last build age
        def lastBuild = job.getLastBuild()
        if (lastBuild != null) {
            def age = (System.currentTimeMillis() - lastBuild.getTimeInMillis()) / 1000
            customJobLastBuildAge.labels(jobName).set(age)
            
            // Success rate
            def successful = builds.findAll { 
                it.getResult()?.toString() == "SUCCESS" 
            }.size()
            def rate = (successful / builds.size()) * 100
            customJobSuccessRate.labels(jobName).set(rate)
        }
    }
}

println "Custom metrics updated successfully"
println "  Active jobs: ${jobs.size()}"
println "  Queued items: ${queue.getItems().size()}"
```

## Testing Your Custom Metrics

1. **Check if metrics are exposed:**
   ```bash
   curl http://localhost:8080/prometheus | grep jenkins_custom
   ```

2. **Verify in Prometheus:**
   - Go to Prometheus UI: `http://localhost:9090`
   - Query: `jenkins_custom_active_jobs`
   - Should show your custom metric value

3. **Add to Grafana Dashboard:**
   - Use the custom metric names in your Grafana queries
   - Example: `jenkins_custom_job_success_rate{job_name="my-job"}`

## Troubleshooting

### Metrics Not Appearing

1. **Check Script Execution:**
   - Verify script runs without errors
   - Check Jenkins logs: `/var/log/jenkins/jenkins.log`

2. **Verify Prometheus Plugin:**
   - Ensure Prometheus plugin is installed
   - Check plugin is enabled

3. **Check Metric Names:**
   - Metrics must follow Prometheus naming conventions
   - No hyphens, use underscores
   - Must start with letter

### Performance Issues

1. **Optimize Scripts:**
   - Avoid querying all builds for every job
   - Use caching for expensive operations
   - Limit label cardinality

2. **Schedule Appropriately:**
   - Don't run too frequently
   - Use Jenkins job triggers or cron

## References

- [Prometheus Client Library for Java](https://github.com/prometheus/client_java)
- [Jenkins Prometheus Plugin](https://plugins.jenkins.io/prometheus/)
- [Jenkins Script Console](https://www.jenkins.io/doc/book/managing/script-console/)
- [Prometheus Metric Types](https://prometheus.io/docs/concepts/metric_types/)

