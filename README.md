# Ride Connect - Kubernetes CI/CD Platform

A production-style CI/CD platform demonstrating automated build, containerization, and Kubernetes deployment using Jenkins, Docker, and Kubernetes.

This project follows a **hybrid CI/CD architecture** where the application code resides in a separate repository and this repository handles all deployment automation and infrastructure orchestration.

---

## Tech Stack

- **CI/CD**: Jenkins (Declarative Pipeline)
- **Build Tool**: Maven
- **Containerization**: Docker (OpenJDK 17 base image)
- **Orchestration**: Kubernetes (kubeadm cluster)
- **Registry**: Docker Hub
- **Configuration Management**: Kubernetes ConfigMaps & Secrets
- **Deployment Strategy**: Rolling Updates (Zero Downtime)

---

##  Architecture Overview

GitHub (Application Repository)
        ↓
Jenkins (Platform Delivery Repository)
        ↓
Maven Build (Artifact Generation)
        ↓
Docker Build (Tagged Image - BUILD_NUMBER)
        ↓
Docker Hub Registry
        ↓
Kubernetes Cluster (kubeadm)
        ↓
Ingress Controller (NGINX)
        ↓
Ride Connect Application (3 Replicas)

---

##  What This Project Demonstrates

- End-to-end CI/CD automation with Jenkins multistage pipeline
- Multi-repository architecture (App repo + Platform repo separation)
- Containerized application builds with Docker image tagging
- Kubernetes deployment automation with rolling updates
- Secret and ConfigMap management for environment configuration
- Infrastructure as Code (IaC) using declarative YAML manifests
- Production-style deployment workflow with high availability
- Secure credential handling using Jenkins + Kubernetes Secrets

---

##  Image Tagging Strategy

This project uses Jenkins BUILD_NUMBER for versioned deployments:

- `maesh0004/ride-connect:<BUILD_NUMBER>`
- Ensures traceability of each deployment
- Enables rollback to specific builds using Kubernetes rollout history
- `latest` tag may be used only for local/testing purposes


## Project Structure

```text
platform-delivery/
├── docker/
│   └── ride-connect/
│       └── Dockerfile
├── jenkins/
│   ├── pipelines/
│   │   └── ride-connect.Jenkinsfile
│   └── scripts/
│       ├── build-image.sh
│       ├── push-image.sh
│       ├── deploy.sh
│       ├── create-docker-secret.sh
│       └── create-db-secret.sh
├── k8s/
│   ├── namespace.yaml
│   ├── ride-connect-deployment.yaml
│   ├── ride-connect-service.yaml
│   ├── ride-connect-configmap.yaml
│   └── ride-connect-ingress.yaml
└── README.md
```


## CI/CD Pipeline Flow

1. Clone Application Repository (GitHub - private repo)
2. Build Application using Maven
3. Build Docker Image (tagged with BUILD_NUMBER)
4. Push Docker Image to Docker Hub
5. Ensure Kubernetes Namespace exists
6. Create Docker Registry Secret in Kubernetes
7. Apply ConfigMap and Secrets
8. Deploy application to Kubernetes cluster
9. Trigger rolling update
10. Verify deployment with health checks


## Secrets Management

This project uses a dual-layer secrets strategy:

### Jenkins Credentials Store
- GitHub authentication token
- Docker Hub credentials

### Kubernetes Secrets
- Database username and password
- Injected into pods at runtime as environment variables

---

## Kubernetes Architecture

### Deployment
- 3 replicas for high availability
- RollingUpdate strategy (zero downtime)
- Image updated dynamically via Jenkins using BUILD_NUMBER-based tagging strategy

### Service
- ClusterIP service for internal communication
- Exposes application inside cluster

### Ingress
- NGINX Ingress Controller used for external access
- Routes HTTP traffic to service

### ConfigMap
Environment configuration for Spring Boot:

```yaml
SERVER_PORT: "8080"
SPRING_DATASOURCE_URL: jdbc:mysql://192.168.0.107:3306/ride_connect_db
SPRING_JPA_SHOW_SQL: "true"
SPRING_JPA_HIBERNATE_DDL_AUTO: update
```

## Deployment Verification

```bash
kubectl get pods -n ride-connect
kubectl get svc -n ride-connect
kubectl rollout status deployment/ride-connect-deployment -n ride-connect
kubectl logs -l app=ride-connect -n ride-connect --tail=50
```

## Rollback Strategy

```bash
kubectl rollout undo deployment/ride-connect-deployment -n ride-connect
```

## Key DevOps Principles Followed

- Separation of application and infrastructure repositories  
- Immutable container deployment strategy  
- Declarative Kubernetes configuration (YAML-based IaC)  
- Idempotent CI/CD operations using Jenkins  
- Secure secrets handling with Jenkins + Kubernetes  
- Automated rolling deployments with zero downtime  

---
## DevOps Model

This pipeline follows a hybrid CI/CD model combining:

- Jenkins as CI/CD orchestration engine  
- Kubernetes for declarative infrastructure management  
- Docker for immutable container packaging  


## Summary

This project demonstrates a real-world CI/CD pipeline design commonly used in enterprise DevOps environments.

- Application code is maintained in a separate repository  
- This repository manages CI/CD and deployment automation  
- Jenkins acts as the CI/CD orchestration layer  
- Kubernetes handles deployment, scaling, and reliability  

