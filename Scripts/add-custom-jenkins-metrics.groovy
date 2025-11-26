/**
 * Custom Jenkins Metrics for Prometheus
 * 
 * This script adds custom metrics to Jenkins that will be exposed via /prometheus endpoint
 * 
 * Usage:
 * 1. Copy this script to Jenkins Script Console: http://YOUR_JENKINS:8080/script
 * 2. Or save as: /var/lib/jenkins/init.groovy.d/custom-metrics.groovy (runs on startup)
 * 3. Or run via Jenkins CLI: java -jar jenkins-cli.jar -s http://localhost:8080 groovy = < this-file.groovy
 */

import jenkins.model.Jenkins
import hudson.model.Job
import hudson.model.Queue
import io.prometheus.client.*
import java.util.concurrent.TimeUnit

def instance = Jenkins.getInstance()

// ============================================
// CUSTOM METRICS DEFINITIONS
// ============================================

// 1. Active Jobs Count
def customActiveJobs = Gauge.build()
    .name("jenkins_custom_active_jobs")
    .help("Total number of active Jenkins jobs")
    .register()

// 2. Queued Items Count
def customQueuedItems = Gauge.build()
    .name("jenkins_custom_queued_items")
    .help("Number of items currently in build queue")
    .register()

// 3. Total Builds per Job
def customJobBuildsTotal = Counter.build()
    .name("jenkins_custom_job_builds_total")
    .help("Total number of builds per job")
    .labelNames("job_name", "job_type")
    .register()

// 4. Job Last Build Age (seconds since last build)
def customJobLastBuildAge = Gauge.build()
    .name("jenkins_custom_job_last_build_age_seconds")
    .help("Age of last build in seconds")
    .labelNames("job_name")
    .register()

// 5. Job Success Rate (0-100 percentage)
def customJobSuccessRate = Gauge.build()
    .name("jenkins_custom_job_success_rate")
    .help("Job success rate percentage (0-100)")
    .labelNames("job_name")
    .register()

// 6. Jobs by Status
def customJobsByStatus = Gauge.build()
    .name("jenkins_custom_jobs_by_status")
    .help("Number of jobs by last build status")
    .labelNames("status")
    .register()

// 7. Total Build Duration (sum of all build times)
def customTotalBuildDuration = Gauge.build()
    .name("jenkins_custom_total_build_duration_seconds")
    .help("Total build duration across all jobs in seconds")
    .register()

// 8. Average Build Duration per Job
def customAvgBuildDuration = Gauge.build()
    .name("jenkins_custom_avg_build_duration_seconds")
    .help("Average build duration per job in seconds")
    .labelNames("job_name")
    .register()

// 9. Builds Today
def customBuildsToday = Counter.build()
    .name("jenkins_custom_builds_today_total")
    .help("Number of builds today")
    .labelNames("job_name")
    .register()

// 10. Deployment Count by Environment
def customDeployments = Counter.build()
    .name("jenkins_custom_deployments_total")
    .help("Number of deployments by environment")
    .labelNames("environment", "status")
    .register()

// ============================================
// UPDATE METRICS
// ============================================

try {
    def jobs = instance.getAllItems(Job.class)
    def queue = Queue.getInstance()
    
    // Update simple gauges
    customActiveJobs.set(jobs.size())
    customQueuedItems.set(queue.getItems().size())
    
    // Reset status counters (they will be set below)
    customJobsByStatus.labels("SUCCESS").set(0)
    customJobsByStatus.labels("FAILURE").set(0)
    customJobsByStatus.labels("UNSTABLE").set(0)
    customJobsByStatus.labels("ABORTED").set(0)
    customJobsByStatus.labels("NOT_BUILT").set(0)
    
    long totalDuration = 0
    def todayStart = System.currentTimeMillis() - TimeUnit.HOURS.toMillis(24)
    int buildsTodayCount = 0
    
    // Process each job
    jobs.each { job ->
        def jobName = job.getName()
        def jobType = job.getClass().getSimpleName()
        def builds = job.getBuilds()
        
        if (builds.size() > 0) {
            // Total builds
            // Note: Counter should be incremented, but for demo we'll set the total
            // In production, you'd track this differently
            customJobBuildsTotal.labels(jobName, jobType).inc(0) // Reset, then add
            
            // Last build age
            def lastBuild = job.getLastBuild()
            if (lastBuild != null) {
                def lastBuildTime = lastBuild.getTimeInMillis()
                def age = (System.currentTimeMillis() - lastBuildTime) / 1000
                customJobLastBuildAge.labels(jobName).set(age)
                
                // Success rate
                def successful = builds.findAll { 
                    def result = it.getResult()
                    result != null && result.toString() == "SUCCESS"
                }.size()
                def rate = builds.size() > 0 ? (successful / builds.size()) * 100 : 0
                customJobSuccessRate.labels(jobName).set(rate)
                
                // Jobs by status
                def status = lastBuild.getResult()?.toString() ?: "NOT_BUILT"
                customJobsByStatus.labels(status).inc()
                
                // Average build duration
                def durations = builds.findAll { it.getDuration() > 0 }.collect { it.getDuration() / 1000.0 }
                if (durations.size() > 0) {
                    def avgDuration = durations.sum() / durations.size()
                    customAvgBuildDuration.labels(jobName).set(avgDuration)
                    totalDuration += durations.sum()
                }
                
                // Builds today
                def buildsToday = builds.findAll { it.getTimeInMillis() >= todayStart }
                buildsTodayCount += buildsToday.size()
                customBuildsToday.labels(jobName).inc(buildsToday.size())
                
                // Deployment tracking (if job name contains environment keywords)
                def nameLower = jobName.toLowerCase()
                def env = "unknown"
                if (nameLower.contains("prod") || nameLower.contains("production")) {
                    env = "production"
                } else if (nameLower.contains("staging") || nameLower.contains("stage")) {
                    env = "staging"
                } else if (nameLower.contains("dev") || nameLower.contains("development")) {
                    env = "development"
                }
                
                if (env != "unknown" && lastBuild.getResult() != null) {
                    customDeployments.labels(env, status).inc()
                }
            }
        }
    }
    
    // Set total duration
    customTotalBuildDuration.set(totalDuration)
    
    println "=========================================="
    println "Custom Metrics Updated Successfully"
    println "=========================================="
    println "Active jobs: ${jobs.size()}"
    println "Queued items: ${queue.getItems().size()}"
    println "Builds today: ${buildsTodayCount}"
    println "Total build duration: ${totalDuration}s"
    println ""
    println "Metrics are now available at: http://localhost:8080/prometheus"
    println "Query them in Prometheus with: jenkins_custom_*"
    
} catch (Exception e) {
    println "ERROR updating custom metrics: ${e.message}"
    e.printStackTrace()
}

