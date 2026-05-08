#!/bin/bash
set -e

REGISTRY=$1
IMAGE=$2
BUILD=$3

docker build \
  -t $REGISTRY/$IMAGE:$BUILD \
  -t $REGISTRY/$IMAGE:latest \
  docker/ride-connect