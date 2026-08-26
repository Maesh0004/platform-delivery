pipeline {

    agent { label 'jenkins-agent-01' }

    tools {
        jdk 'jdk-21'
        maven 'maven-3.9.16'
    }

    options {
        disableConcurrentBuilds(abortPrevious: true)

        timeout(time: 30, unit: 'MINUTES')

        timestamps()

        buildDiscarder(logRotator(
            numToKeepStr: '15',
            artifactNumToKeepStr: '5'
        ))
    }

    environment {
        APP_REPO = "https://github.com/Maesh0004/RideConnect.git"

        REGISTRY = "maesh0004"
        IMAGE_NAME = "ride-connect"

        NAMESPACE = "ride-connect"
        DEPLOYMENT = "ride-connect-deployment"

        SONAR_PROJECT_KEY = "ride-connect"

        SONAR_MAVEN_PLUGIN_VERSION = "5.7.0.6970"
    }

    stages {

        stage("Clone App Repo") {
            steps {
                dir("RideConnect") {
                    git branch: 'main',
                        credentialsId: 'github-token',
                        url: "${APP_REPO}"
                }
            }
        }

        stage("Build") {
            steps {
                dir("RideConnect") {
                    sh "mvn clean verify"
                }
            }
        }

        stage("SonarQube Scan") {
            steps {
                dir("RideConnect") {
                    withCredentials([
                        string(
                            credentialsId: 'sonarqube-token',
                            variable: 'SONAR_TOKEN'
                        )
                    ]) {
                        withSonarQubeEnv("sonarqube-server") {
                            sh '''
                                mvn org.sonarsource.scanner.maven:sonar-maven-plugin:${SONAR_MAVEN_PLUGIN_VERSION}:sonar \
                                    -Dsonar.projectKey="${SONAR_PROJECT_KEY}" \
                                    -Dsonar.sources=src/main/java \
                                    -Dsonar.tests=src/test/java \
                                    -Dsonar.java.binaries=target/classes \
                                    -Dsonar.java.test.binaries=target/test-classes \
                                    -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml \
                                    -Dsonar.token="$SONAR_TOKEN"
                            '''
                        }
                    }
                }
            }
        }

        stage("SonarQube Quality Gate") {
            steps {
                timeout(time: 10, unit: "MINUTES") {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage("Prepare Docker Context") {
            steps {
                sh "cp RideConnect/target/rideconnect.jar docker/ride-connect/"
            }
        }

        stage("Prepare Scripts") {
            steps {
                sh "chmod +x jenkins/scripts/*.sh"
            }
        }

        stage("Build Docker Image") {
            steps {
                sh "./jenkins/scripts/build-image.sh ${REGISTRY} ${IMAGE_NAME} ${BUILD_NUMBER}"
            }
        }

        stage("Trivy Image Scan") {
            steps {
                script {
                    def trivyStatus = sh(
                        script: "trivy image --no-progress --ignore-unfixed --exit-code 1 --format json --output trivy-${IMAGE_NAME}-${BUILD_NUMBER}.json --severity HIGH,CRITICAL ${REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}",
                        returnStatus: true
                    )

                    archiveArtifacts artifacts: "trivy-${IMAGE_NAME}-${BUILD_NUMBER}.json", fingerprint: true

                    if (trivyStatus != 0) {
                        error "Trivy found HIGH or CRITICAL vulnerabilities"
                    }
                }
            }
        }

        stage("Push Docker Image") {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-creds',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )
                ]) {
                    sh "./jenkins/scripts/push-image.sh ${REGISTRY} ${IMAGE_NAME} ${BUILD_NUMBER}"
                }
            }
        }

        stage("Provision Namespace") {
            steps {
                sh "kubectl apply -f k8s/namespace.yaml"
            }
        }

        stage("Apply ConfigMap") {
            steps {
                sh "kubectl apply -f k8s/ride-connect-configmap.yaml"
            }
        }

        stage("Create DB Secret") {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'mysql-creds',
                        usernameVariable: 'DB_USER',
                        passwordVariable: 'DB_PASS'
                    ),
                    string(
                        credentialsId: 'mysql-root-password',
                        variable: 'MYSQL_ROOT_PASSWORD'
                    )
                ]) {
                    sh "./jenkins/scripts/create-db-secret.sh ${NAMESPACE}"
                }
            }
        }

        stage("Create Docker Pull Secret") {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-creds',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )
                ]) {
                    sh "./jenkins/scripts/create-docker-secret.sh ${NAMESPACE}"
                }
            }
        }

        stage("Deploy to Kubernetes") {
            steps {
                sh "./jenkins/scripts/deploy.sh ${NAMESPACE} ${DEPLOYMENT} ${REGISTRY} ${IMAGE_NAME} ${BUILD_NUMBER}"
            }

            post {
                failure {
                    echo "Kubernetes deployment failed. Collecting diagnostics..."

                    sh "kubectl get pods -n ${NAMESPACE} -o wide || true"

                    sh "kubectl get events -n ${NAMESPACE} --sort-by=.lastTimestamp || true"

                    sh "kubectl describe deployment ${DEPLOYMENT} -n ${NAMESPACE} || true"
                }
            }
        }
    }

    post {

        success {
            echo "Deployment Successful"
        }

        failure {
            echo "Pipeline Failed"
        }

        always {
            deleteDir()
        }
    }
}