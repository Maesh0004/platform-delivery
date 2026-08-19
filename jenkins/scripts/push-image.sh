#!/bin/bash
set -euo pipefail

REGISTRY=$1
IMAGE=$2
TAG=$3

echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin

docker push "$REGISTRY/$IMAGE:latest"
docker push "$REGISTRY/$IMAGE:$TAG"