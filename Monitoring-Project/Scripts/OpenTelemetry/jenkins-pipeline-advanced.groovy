/**
 * Advanced Jenkins Pipeline with Detailed OpenTelemetry Tracing
 * 
 * This pipeline demonstrates detailed span creation for:
 * - Job start with metadata
 * - SCM checkout with commit information
 * - Build step with timing
 * - Test step with test results
 * - Artifact upload with artifact details
 * - Custom spans for specific operations
 * 
 * Usage:
 * 1. Create a new Pipeline job in Jenkins
 * 2. Copy this script to the Pipeline definition
 * 3. Ensure OpenTelemetry plugin is installed and configured
 */

@Library('shared-libraries') _

pipeline {
    agent any
    
    options {
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }
    
    environment {
        OTEL_SERVICE_NAME = 'jenkins-advanced-pipeline'
        OTEL_RESOURCE_ATTRIBUTES = 'service.name=jenkins-pipeline,deployment.environment=${ENVIRONMENT},team=devops'
        BUILD_TIMESTAMP = "${new Date().format('yyyy-MM-dd HH:mm:ss')}"
    }
    
    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'staging', 'production'],
            description: 'Deployment environment'
        )
        string(
            name: 'BUILD_VERSION',
            defaultValue: '1.0.0',
            description: 'Build version number'
        )
    }
    
    stages {
        stage('Job Start') {
            steps {
                script {
                    // Initialize tracing context
                    def jobStartTime = System.currentTimeMillis()
                    
                    echo """
                    ==========================================
                    Jenkins Pipeline Started
                    ==========================================
                    Job Name: ${env.JOB_NAME}
                    Build Number: ${env.BUILD_NUMBER}
                    Build ID: ${env.BUILD_ID}
                    Workspace: ${env.WORKSPACE}
                    Node Name: ${env.NODE_NAME}
                    Environment: ${params.ENVIRONMENT}
                    Build Version: ${params.BUILD_VERSION}
                    ==========================================
                    """
                    
                    // Set build description with trace information
                    currentBuild.description = """
                    Environment: ${params.ENVIRONMENT}
                    Version: ${params.BUILD_VERSION}
                    Started: ${BUILD_TIMESTAMP}
                    """
                    
                    // Store metadata for later spans
                    env.JOB_START_TIME = "${jobStartTime}"
                }
            }
        }
        
        stage('SCM Checkout') {
            steps {
                script {
                    def checkoutStartTime = System.currentTimeMillis()
                    
                    echo "=========================================="
                    echo "Stage: SCM Checkout"
                    echo "=========================================="
                }
                
                // Checkout will create automatic span
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[url: 'https://github.com/example/repo.git']],
                    extensions: [
                        [$class: 'CloneOption', depth: 1, shallow: true]
                    ]
                ])
                
                script {
                    // Extract and log SCM information
                    def gitCommit = sh(
                        script: 'git rev-parse HEAD',
                        returnStdout: true
                    ).trim()
                    
                    def gitBranch = sh(
                        script: 'git rev-parse --abbrev-ref HEAD',
                        returnStdout: true
                    ).trim()
                    
                    def gitAuthor = sh(
                        script: 'git log -1 --pretty=format:"%an"',
                        returnStdout: true
                    ).trim()
                    
                    def gitMessage = sh(
                        script: 'git log -1 --pretty=format:"%s"',
                        returnStdout: true
                    ).trim()
                    
                    def checkoutDuration = System.currentTimeMillis() - checkoutStartTime
                    
                    echo """
                    SCM Checkout Information:
                    - Repository: ${env.JOB_NAME}
                    - Branch: ${gitBranch}
                    - Commit: ${gitCommit}
                    - Author: ${gitAuthor}
                    - Message: ${gitMessage}
                    - Duration: ${checkoutDuration}ms
                    """
                    
                    // Store for later reference
                    env.GIT_COMMIT = gitCommit
                    env.GIT_BRANCH = gitBranch
                    env.CHECKOUT_DURATION = "${checkoutDuration}"
                }
            }
        }
        
        stage('Build') {
            steps {
                script {
                    def buildStartTime = System.currentTimeMillis()
                    
                    echo "=========================================="
                    echo "Stage: Build"
                    echo "=========================================="
                }
                
                // Parallel build steps for better tracing
                parallel(
                    'Build Application': {
                        script {
                            echo "Building application..."
                            sh '''
                                # Example: Maven build
                                # mvn clean package -DskipTests
                                
                                # Example: NPM build
                                # npm ci
                                # npm run build
                                
                                # Example: Docker build
                                # docker build -t myapp:${BUILD_NUMBER} .
                                
                                echo "Build process completed"
                                sleep 5  # Simulate build time
                            '''
                        }
                    },
                    'Build Documentation': {
                        script {
                            echo "Building documentation..."
                            sh '''
                                echo "Generating documentation..."
                                sleep 2
                                echo "Documentation generated"
                            '''
                        }
                    }
                )
                
                script {
                    def buildDuration = System.currentTimeMillis() - buildStartTime
                    echo "Build stage completed in ${buildDuration}ms"
                    env.BUILD_DURATION = "${buildDuration}"
                }
            }
        }
        
        stage('Test') {
            steps {
                script {
                    def testStartTime = System.currentTimeMillis()
                    
                    echo "=========================================="
                    echo "Stage: Test"
                    echo "=========================================="
                }
                
                // Run tests with detailed reporting
                script {
                    sh '''
                        echo "Running unit tests..."
                        # Example: JUnit tests
                        # mvn test
                        
                        # Example: Jest tests
                        # npm test -- --coverage
                        
                        # Example: Pytest
                        # pytest --junitxml=test-results.xml
                        
                        sleep 4  # Simulate test execution
                        echo "Tests completed"
                    '''
                    
                    // Simulate test results
                    def testResults = [
                        total: 150,
                        passed: 145,
                        failed: 3,
                        skipped: 2
                    ]
                    
                    def testDuration = System.currentTimeMillis() - testStartTime
                    
                    echo """
                    Test Results:
                    - Total: ${testResults.total}
                    - Passed: ${testResults.passed}
                    - Failed: ${testResults.failed}
                    - Skipped: ${testResults.skipped}
                    - Duration: ${testDuration}ms
                    - Success Rate: ${(testResults.passed / testResults.total * 100).round(2)}%
                    """
                    
                    env.TEST_TOTAL = "${testResults.total}"
                    env.TEST_PASSED = "${testResults.passed}"
                    env.TEST_FAILED = "${testResults.failed}"
                    env.TEST_DURATION = "${testDuration}"
                    
                    // Archive test results (creates span)
                    junit 'test-results.xml'
                }
            }
        }
        
        stage('Artifact Upload') {
            steps {
                script {
                    def uploadStartTime = System.currentTimeMillis()
                    
                    echo "=========================================="
                    echo "Stage: Artifact Upload"
                    echo "=========================================="
                }
                
                script {
                    // Create artifacts
                    sh '''
                        mkdir -p artifacts
                        echo "Build Number: ${BUILD_NUMBER}" > artifacts/build-info.txt
                        echo "Version: ${BUILD_VERSION}" >> artifacts/build-info.txt
                        echo "Environment: ${ENVIRONMENT}" >> artifacts/build-info.txt
                        echo "Git Commit: ${GIT_COMMIT}" >> artifacts/build-info.txt
                        echo "Build Time: $(date)" >> artifacts/build-info.txt
                        echo "Build Duration: ${BUILD_DURATION}ms" >> artifacts/build-info.txt
                        echo "Test Duration: ${TEST_DURATION}ms" >> artifacts/build-info.txt
                    '''
                    
                    // Upload to artifact repository (creates span)
                    archiveArtifacts artifacts: 'artifacts/**', fingerprint: true
                    
                    // Optional: Upload to external storage
                    // s3Upload(...)
                    // azureUpload(...)
                    
                    def uploadDuration = System.currentTimeMillis() - uploadStartTime
                    echo "Artifacts uploaded in ${uploadDuration}ms"
                    env.UPLOAD_DURATION = "${uploadDuration}"
                }
            }
        }
    }
    
    post {
        always {
            script {
                def totalDuration = System.currentTimeMillis() - Long.parseLong(env.JOB_START_TIME)
                
                echo """
                ==========================================
                Pipeline Execution Summary
                ==========================================
                Status: ${currentBuild.currentResult}
                Total Duration: ${totalDuration}ms
                
                Stage Durations:
                - Checkout: ${env.CHECKOUT_DURATION}ms
                - Build: ${env.BUILD_DURATION}ms
                - Test: ${env.TEST_DURATION}ms
                - Upload: ${env.UPLOAD_DURATION}ms
                
                Test Results:
                - Total: ${env.TEST_TOTAL}
                - Passed: ${env.TEST_PASSED}
                - Failed: ${env.TEST_FAILED}
                
                Build Information:
                - Version: ${params.BUILD_VERSION}
                - Environment: ${params.ENVIRONMENT}
                - Git Commit: ${env.GIT_COMMIT}
                - Build URL: ${env.BUILD_URL}
                ==========================================
                """
            }
        }
        success {
            script {
                echo "✓ Pipeline completed successfully"
                // Send notification, update deployment status, etc.
            }
        }
        failure {
            script {
                echo "✗ Pipeline failed"
                // Send alerts, create tickets, etc.
            }
        }
        cleanup {
            cleanWs()
        }
    }
}

