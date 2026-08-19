#!/bin/bash
set -euo pipefail

REGISTRY=$1
IMAGE=$2
BUILD=$3

docker buildx build --load \
  -t "$REGISTRY/$IMAGE:$BUILD" \
  -t "$REGISTRY/$IMAGE:latest" \
  docker/ride-connect