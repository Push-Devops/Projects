/**
 * Jenkins Pipeline with OpenTelemetry Tracing
 * 
 * This pipeline exports spans for:
 * - Job start
 * - SCM checkout
 * - Build step
 * - Test step
 * - Artifact upload
 * 
 * Prerequisites:
 * - OpenTelemetry Plugin installed in Jenkins
 * - OpenTelemetry Collector running and configured
 * - Jenkins configured to export traces to collector
 */

pipeline {
    agent any
    
    options {
        // Enable OpenTelemetry tracing for this pipeline
        timestamps()
    }
    
    environment {
        // OpenTelemetry configuration
        OTEL_SERVICE_NAME = 'jenkins-pipeline'
        OTEL_RESOURCE_ATTRIBUTES = 'service.name=jenkins-pipeline,service.version=1.0.0'
    }
    
    stages {
        stage('Job Start') {
            steps {
                script {
                    // This creates a span for job start
                    echo "Starting Jenkins job: ${env.JOB_NAME}"
                    echo "Build Number: ${env.BUILD_NUMBER}"
                    echo "Build URL: ${env.BUILD_URL}"
                    
                    // Add custom attributes to the span
                    currentBuild.description = "Job started at ${new Date()}"
                }
            }
        }
        
        stage('SCM Checkout') {
            steps {
                script {
                    echo "=========================================="
                    echo "Checking out source code from SCM"
                    echo "=========================================="
                }
                // SCM checkout will automatically create a span
                checkout scm
                
                script {
                    // Add SCM information as span attributes
                    def gitCommit = sh(
                        script: 'git rev-parse HEAD',
                        returnStdout: true
                    ).trim()
                    
                    def gitBranch = sh(
                        script: 'git rev-parse --abbrev-ref HEAD',
                        returnStdout: true
                    ).trim()
                    
                    echo "Git Commit: ${gitCommit}"
                    echo "Git Branch: ${gitBranch}"
                }
            }
        }
        
        stage('Build') {
            steps {
                script {
                    echo "=========================================="
                    echo "Building application"
                    echo "=========================================="
                }
                
                // Build step span
                sh '''
                    echo "Starting build process..."
                    # Example build commands
                    # mvn clean package
                    # npm install && npm run build
                    # docker build -t myapp:latest .
                    
                    echo "Build completed successfully"
                    sleep 2  # Simulate build time
                '''
                
                script {
                    echo "Build step completed"
                }
            }
        }
        
        stage('Test') {
            steps {
                script {
                    echo "=========================================="
                    echo "Running tests"
                    echo "=========================================="
                }
                
                // Test step span
                sh '''
                    echo "Running unit tests..."
                    # Example test commands
                    # mvn test
                    # npm test
                    # pytest tests/
                    
                    echo "All tests passed"
                    sleep 3  # Simulate test execution
                '''
                
                script {
                    echo "Test step completed"
                }
            }
        }
        
        stage('Artifact Upload') {
            steps {
                script {
                    echo "=========================================="
                    echo "Uploading artifacts"
                    echo "=========================================="
                }
                
                // Artifact upload span
                script {
                    // Create a test artifact
                    sh 'echo "Build artifact" > artifact.txt'
                    sh 'echo "Build ${BUILD_NUMBER}" >> artifact.txt'
                    sh 'date >> artifact.txt'
                }
                
                // Archive artifacts
                archiveArtifacts artifacts: 'artifact.txt', fingerprint: true
                
                script {
                    echo "Artifacts uploaded successfully"
                    echo "Artifact: artifact.txt"
                }
            }
        }
    }
    
    post {
        always {
            script {
                echo "=========================================="
                echo "Pipeline completed: ${currentBuild.currentResult}"
                echo "=========================================="
                echo "Job Name: ${env.JOB_NAME}"
                echo "Build Number: ${env.BUILD_NUMBER}"
                echo "Duration: ${currentBuild.durationString}"
                echo "Build URL: ${env.BUILD_URL}"
            }
        }
        success {
            echo "Pipeline succeeded!"
        }
        failure {
            echo "Pipeline failed!"
        }
        cleanup {
            // Cleanup actions
            cleanWs()
        }
    }
}

