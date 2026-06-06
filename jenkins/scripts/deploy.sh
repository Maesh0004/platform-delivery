#!/bin/bash
set -e

NAMESPACE=$1
DEPLOYMENT=$2
REGISTRY=$3
IMAGE_NAME=$4
TAG=$5

echo "Deploying Kubernetes manifests..."

kubectl apply -f k8s/ride-connect-deployment.yaml -n $NAMESPACE
kubectl apply -f k8s/ride-connect-service.yaml -n $NAMESPACE
kubectl apply -f k8s/ride-connect-ingress.yaml -n $NAMESPACE
kubectl apply -f k8s/mysql-statefulset.yaml -n $NAMESPACE
kubectl apply -f k8s/mysql-service.yaml -n $NAMESPACE


echo "Updating deployment image..."

kubectl set image deployment/$DEPLOYMENT \
  ride-connect=$REGISTRY/$IMAGE_NAME:$TAG \
  -n $NAMESPACE

echo "Waiting for rollout..."

kubectl rollout status deployment/$DEPLOYMENT \
  -n $NAMESPACE \
  --timeout=300s

echo "Deployment completed successfully"