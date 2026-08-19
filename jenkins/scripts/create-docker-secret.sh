#!/bin/bash
set -euo pipefail

NAMESPACE=$1

kubectl create secret docker-registry dockerhub-secret \
  --docker-username="$DOCKER_USER" \
  --docker-password="$DOCKER_PASS" \
  --docker-server=https://index.docker.io/v1/ \
  -n "$NAMESPACE" \
  --dry-run=client -o yaml | kubectl apply -f -