# Platform Delivery

A DevOps project that automates the build and deployment of a Java application
using **Jenkins, Docker, Kubernetes, and Helm**.

The pipeline builds and scans the application, creates and scans a Docker image,
pushes it to Docker Hub, and deploys it to a Kubernetes cluster with Helm.

## Project Overview

This project covers a complete CI/CD workflow:

* Build the application with Maven and run the SonarQube quality gate
* Create a Docker image and scan it with Trivy
* Push the image to Docker Hub
* Create the Kubernetes secrets
* Package and deploy the application to Kubernetes with Helm
* Deploy MySQL with persistent storage
* Check the deployment and roll back if needed

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
       └── Helm Upgrade (helm/ride-connect)
                │
                ▼
      Kubernetes Cluster (namespace: ride-connect)
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
Helm Lint
   ↓
Helm Template (render preview)
   ↓
Helm Upgrade --install (deploy)
   ↓
Rollout Check
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
| Helm          | Kubernetes packaging and deployment |
| Kubernetes    | Application deployment    |
| NGINX Ingress | External access           |
| MySQL         | Database                  |
| ConfigMap     | Application configuration |
| Secrets       | Credentials               |
| PVC           | Persistent storage        |

## Repository Structure

```text
platform-delivery/
├── helm/
│   └── ride-connect/              # active Helm chart
│       ├── Chart.yaml
│       ├── values.yaml            # default values
│       ├── .helmignore
│       └── templates/
│           ├── _helpers.tpl
│           ├── configmap.yaml
│           ├── deployment.yaml
│           ├── service.yaml
│           ├── ingress.yaml
│           ├── mysql-statefulset.yaml
│           ├── mysql-service.yaml
│           ├── serviceaccount.yaml
│           └── NOTES.txt
│
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
│       ├── helm-deploy.sh
│       ├── create-docker-secret.sh
│       └── create-db-secret.sh
│
├── .gitignore
├── .gitattributes
└── README.md
```

## Helm Chart

### Values

Key values from `helm/ride-connect/values.yaml`:

| Value | Default | Description |
| ----- | ------- | ----------- |
| `replicaCount` | `3` | Number of application replicas |
| `image.repository` | `maesh0004/ride-connect` | Application image repository |
| `image.tag` | `latest` | Image tag (the pipeline sets the build number) |
| `image.pullPolicy` | `Always` | Image pull policy |
| `imagePullSecrets` | `dockerhub-secret` | Pull secret used for Docker Hub |
| `service.type` / `port` / `targetPort` | `ClusterIP` / `8080` / `8080` | Application Service |
| `ingress.enabled` | `true` | Create the Ingress resource |
| `ingress.className` | `nginx` | Ingress class |
| `ingress.host` | `rideconnect.local` | Ingress host |
| `config.*` | see `values.yaml` | Environment variables rendered into the ConfigMap |
| `appSecretName` | `ride-connect-secret` | Pre-created Secret with database credentials |
| `mysql.enabled` | `true` | Deploy MySQL together with the application |
| `mysql.image` | `mysql:8.0` | MySQL image |
| `mysql.persistence.size` | `5Gi` | PVC size for MySQL |
| `mysql.persistence.storageClass` | `local-path` | StorageClass for the MySQL PVC |
| `mysql.secretName` | `mysql-secret` | Pre-created Secret with MySQL credentials |

### Commands

```bash
# Validate and preview
helm lint helm/ride-connect
helm template ride-connect helm/ride-connect --namespace ride-connect
helm upgrade --install ride-connect helm/ride-connect --dry-run --debug

# Deploy
helm upgrade --install ride-connect helm/ride-connect \
  --namespace ride-connect --create-namespace \
  --set image.tag=42

# Inspect, roll back, remove
helm list -n ride-connect
helm history ride-connect -n ride-connect
helm rollback ride-connect 3 -n ride-connect
helm uninstall ride-connect -n ride-connect
```

### Adding another environment

The chart reads `values.yaml` by default. To deploy a different environment
later, create a `values-<env>.yaml` containing only the overrides you need
(it is merged on top of `values.yaml`) and pass it with `-f`:

```bash
helm upgrade --install ride-connect helm/ride-connect \
  --namespace ride-connect --create-namespace \
  -f helm/ride-connect/values-prod.yaml \
  --set image.tag=42
```

## Kubernetes Resources

The application is deployed in the `ride-connect` namespace. Resource names are
derived from the Helm release name, so a release named `ride-connect` creates:

* **Deployment** `ride-connect` - runs the application pods
* **Service** `ride-connect` - internal access to the application
* **Ingress** `ride-connect` - external HTTP access
* **ConfigMap** `ride-connect` - application configuration
* **StatefulSet** `mysql` - MySQL (the name is kept stable because the JDBC URL
  points at the `mysql` host)
* **Service** `mysql` - internal access to MySQL
* **PVC** - created by the MySQL StatefulSet `volumeClaimTemplates`

Secrets are **not** created by the chart. The pipeline creates them first and the
chart only references them:

* `dockerhub-secret` - image pull secret (`imagePullSecrets`)
* `ride-connect-secret` - application database credentials (`secretRef`)
* `mysql-secret` - MySQL root/user credentials (`secretKeyRef`)

### Config change restarts

The Deployment carries a `checksum/config` annotation computed from the rendered
ConfigMap. Changing any value under `config:` therefore changes the pod template
and triggers a rolling restart - the application always picks up new
configuration.

## Deployment Flow

The Jenkins pipeline handles the deployment from start to finish:

1. Checkout the application source code
2. Build the application with Maven and pass the SonarQube quality gate
3. Build the Docker image and scan it with Trivy
4. Push the image to Docker Hub
5. Create the required Kubernetes secrets
6. `helm lint` the chart
7. `helm template` to render and archive the manifests
8. `helm upgrade --install` the chart, using the build number as the image tag
9. Verify the rollout status

## Requirements

Before running the pipeline, you need:

* Jenkins
* Docker
* Docker Hub account
* Kubernetes cluster
* kubectl
* Helm 3 installed on the Jenkins agent
* Maven
* Trivy installed on the Jenkins agent
* SonarQube server configured in Jenkins as `sonarqube-server`
* Jenkins SonarQube Scanner plugin installed
* NGINX Ingress Controller
* Kubernetes StorageClass

## Check the Deployment

```bash
helm list -n ride-connect
helm status ride-connect -n ride-connect
kubectl get pods -n ride-connect
kubectl get svc -n ride-connect
kubectl get ingress -n ride-connect
kubectl get pvc -n ride-connect
```

Check the application rollout:

```bash
kubectl rollout status deployment/ride-connect -n ride-connect
```

## Rollback

Every `helm upgrade` creates a new revision, so a bad deploy can be reverted in
one command:

```bash
helm history ride-connect -n ride-connect
helm rollback ride-connect <revision> -n ride-connect
```

## Summary

This project is a practical example of using **Jenkins, Docker, Kubernetes and
Helm** together to build and deploy a Java application. It covers the main parts of
a realistic DevOps delivery process - build, containerize, scan, push, package,
deploy and verify - with the deployment packaged as a parameterized, versioned
Helm chart.
