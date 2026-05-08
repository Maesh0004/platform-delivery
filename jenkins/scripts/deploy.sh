#!/bin/bash
set -e

NAMESPACE=$1
DEPLOYMENT=$2
TAG=$3

echo "Applying Kubernetes manifests..."

kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/ -n $NAMESPACE

echo "Updating image tag..."

kubectl set image deployment/$DEPLOYMENT \
  $DEPLOYMENT=$REGISTRY/$IMAGE_NAME:$TAG \
  -n $NAMESPACE

kubectl rollout status deployment/$DEPLOYMENT \
  -n $NAMESPACE --timeout=300s