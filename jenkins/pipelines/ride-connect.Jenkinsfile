pipeline {

    agent { label 'ub22-agent' }

    environment {
        APP_REPO = "https://github.com/Maesh0004/RideConnect.git"

        REGISTRY = "maesh0004"
        IMAGE_NAME = "ride-connect"

        NAMESPACE = "ride-connect"
        DEPLOYMENT = "ride-connect-deployment"
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
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh "./jenkins/scripts/create-docker-secret.sh ${NAMESPACE}"
                }
            }
        }

        stage("Deploy to Kubernetes") {
            steps {
                sh "./jenkins/scripts/deploy.sh ${NAMESPACE} ${DEPLOYMENT} ${REGISTRY} ${IMAGE_NAME} ${BUILD_NUMBER}"
            }
        }
    }

    post {

        success {
            echo "Deployment Successful"
        }

        failure {
            echo "Deployment Failed"

            sh "kubectl get pods -n ${NAMESPACE}"
            sh "kubectl describe pods -n ${NAMESPACE}"
        }

        always {
            deleteDir()
        }
    }
}