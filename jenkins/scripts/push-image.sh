#!/bin/bash
set -e

REGISTRY=$1
IMAGE=$2

echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin

docker push $REGISTRY/$IMAGE:latest
docker push $REGISTRY/$IMAGE:$BUILD_NUMBER