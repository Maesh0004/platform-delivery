pipeline {

    agent { label 'ub22-agent' }

    environment {
        APP_REPO = "https://github.com/Maesh0004/RideConnect.git"

        REGISTRY = "maesh0004"
        IMAGE_NAME = "ride-connect"

        NAMESPACE = "ride-connect"
        DEPLOYMENT = "ride-connect"
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

        stage("Build Application") {
            steps {
                dir("RideConnect") {
                    sh "mvn clean package -DskipTests"
                }
            }
        }

        stage("Prepare Docker Context") {
            steps {
                sh "cp RideConnect/target/*.jar docker/ride-connect/"
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

        stage("Push Docker Image") {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh "./jenkins/scripts/push-image.sh ${REGISTRY} ${IMAGE_NAME}"
                }
            }
        }

        stage("Deploy to Kubernetes") {
            steps {
                sh "./jenkins/scripts/deploy.sh ${NAMESPACE} ${DEPLOYMENT} ${BUILD_NUMBER}"
            }
        }
    }

    post {
        success {
            echo "Deployment Successful"
        }

        failure {
            echo "Deployment Failed"
        }

        always {
            deleteDir()
        }
    }
}