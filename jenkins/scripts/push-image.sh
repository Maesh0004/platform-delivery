#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Push the RideConnect Docker image to Docker Hub.
#
# Requires DOCKER_USER / DOCKER_PASS in the environment (Jenkins credentials).
#
# Usage: ./push-image.sh -r REGISTRY -i IMAGE -t TAG
#   -r REGISTRY   Docker Hub repository (e.g. maesh0004)
#   -i IMAGE      Image name (e.g. ride-connect)
#   -t TAG        Image tag to push (e.g. the build number)
# ---------------------------------------------------------------------------

usage() {
    echo "Usage: $0 -r REGISTRY -i IMAGE -t TAG" >&2
    exit 1
}

while getopts "r:i:t:" opt; do
    case "$opt" in
        r) REGISTRY=$OPTARG ;;
        i) IMAGE=$OPTARG ;;
        t) TAG=$OPTARG ;;
        *) usage ;;
    esac
done

[[ -z "${REGISTRY:-}" || -z "${IMAGE:-}" || -z "${TAG:-}" ]] && usage

: "${DOCKER_USER:?DOCKER_USER is required}"
: "${DOCKER_PASS:?DOCKER_PASS is required}"

echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin

docker push "$REGISTRY/$IMAGE:latest"
docker push "$REGISTRY/$IMAGE:$TAG"
