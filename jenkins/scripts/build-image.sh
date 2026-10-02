#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Build the RideConnect Docker image.
#
# Tags the image with the build number and with "latest".
#
# Usage: ./build-image.sh -r REGISTRY -i IMAGE -b BUILD
#   -r REGISTRY   Docker Hub repository (e.g. maesh0004)
#   -i IMAGE      Image name (e.g. ride-connect)
#   -b BUILD      Build number, used as the image tag
# ---------------------------------------------------------------------------

usage() {
    echo "Usage: $0 -r REGISTRY -i IMAGE -b BUILD" >&2
    exit 1
}

while getopts "r:i:b:" opt; do
    case "$opt" in
        r) REGISTRY=$OPTARG ;;
        i) IMAGE=$OPTARG ;;
        b) BUILD=$OPTARG ;;
        *) usage ;;
    esac
done

[[ -z "${REGISTRY:-}" || -z "${IMAGE:-}" || -z "${BUILD:-}" ]] && usage

docker buildx build --load \
  -t "$REGISTRY/$IMAGE:$BUILD" \
  -t "$REGISTRY/$IMAGE:latest" \
  docker/ride-connect
