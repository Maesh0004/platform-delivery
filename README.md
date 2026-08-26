# Platform Delivery

A DevOps project that automates the build and deployment of a Java application using **Jenkins, Docker, and Kubernetes**.

The pipeline builds and scans the application, creates and scans a Docker image, pushes it to Docker Hub, and deploys it to a Kubernetes cluster.

## Project Overview

This project covers a basic CI/CD workflow:

* Build the application with Maven
* Create a Docker image
* Push the image to Docker Hub
* Create Kubernetes configuration and secrets
* Deploy the application to Kubernetes
* Deploy MySQL with persistent storage
* Check the deployment status

## Architecture

```text
Java Application
       │
       ▼
    Jenkins
       │
       ├── Maven Build
       ├── Docker Build
       ├── Push Image
       └── Kubernetes Deploy
                │
                ▼
        Kubernetes Cluster
                │
        ┌───────┴───────┐
        │               │
   Application        MySQL
        │               │
   Deployment      StatefulSet
        │               │
     Service           PVC
        │
     Ingress
```

## CI/CD Pipeline

```text
Checkout
   ↓
Maven Build
   ↓
SonarQube Scan and Quality Gate
   ↓
Docker Image Build
   ↓
Trivy Image Scan
   ↓
Push to Docker Hub
   ↓
Create Kubernetes Secrets
   ↓
Deploy to Kubernetes
   ↓
Update Image
   ↓
Check Rollout
```

## Technologies

| Technology    | Used For                  |
| ------------- | ------------------------- |
| Jenkins       | CI/CD                     |
| Maven         | Java application build    |
| SonarQube     | Source code quality       |
| Docker        | Container image           |
| Docker Hub    | Image registry            |
| Trivy         | Image vulnerability scan  |
| Kubernetes    | Application deployment    |
| NGINX Ingress | External access           |
| MySQL         | Database                  |
| ConfigMap     | Application configuration |
| Secrets       | Credentials               |
| PVC           | Persistent storage        |

## Repository Structure

```text
platform-delivery/
├── docker/
│   └── ride-connect/
│       └── Dockerfile
│
├── jenkins/
│   ├── pipelines/
│   │   └── ride-connect.Jenkinsfile
│   │
│   └── scripts/
│       ├── build-image.sh
│       ├── push-image.sh
│       ├── create-docker-secret.sh
│       ├── create-db-secret.sh
│       └── deploy.sh
│
├── k8s/
│   ├── namespace.yaml
│   ├── ride-connect-configmap.yaml
│   ├── ride-connect-deployment.yaml
│   ├── ride-connect-service.yaml
│   ├── ride-connect-ingress.yaml
│   ├── mysql-statefulset.yaml
│   └── mysql-service.yaml
│
├── .gitignore
├── .gitattributes
└── README.md
```

## Kubernetes Resources

The application is deployed in the `ride-connect` namespace.

The Kubernetes setup includes:

* **Namespace** — separates the application resources
* **Deployment** — runs the application pods
* **Service** — provides internal access to the application
* **Ingress** — handles external HTTP access
* **ConfigMap** — stores application configuration
* **Secrets** — stores sensitive values
* **StatefulSet** — runs MySQL
* **PVC** — provides persistent storage for MySQL

## Deployment Flow

The Jenkins pipeline handles the deployment from start to finish:

1. Checkout the application source code
2. Build the application using Maven
3. Prepare the Docker build
4. Build the Docker image
5. Push the image to Docker Hub
6. Create the required Kubernetes secrets
7. Apply the Kubernetes manifests
8. Update the application image
9. Check the rollout status

## Requirements

Before running the pipeline, you need:

* Jenkins
* Docker
* Docker Hub account
* Kubernetes cluster
* kubectl
* Maven
* Trivy installed on the Jenkins agent
* SonarQube server configured in Jenkins as `sonarqube-server`
* Jenkins SonarQube Scanner plugin installed
* NGINX Ingress Controller
* Kubernetes StorageClass

## Check the Deployment

After deployment, you can check the resources with:

```bash
kubectl get pods -n ride-connect
kubectl get svc -n ride-connect
kubectl get ingress -n ride-connect
kubectl get pvc -n ride-connect
```

Check the application rollout:

```bash
kubectl rollout status deployment/ride-connect -n ride-connect
```

## Summary

This project is a practical example of using Jenkins, Docker, and Kubernetes together to build and deploy a Java application. It covers the main parts of a basic DevOps delivery process: build, containerize, push, deploy, and verify.
