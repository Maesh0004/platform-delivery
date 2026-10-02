#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Deploy the RideConnect Helm chart to Kubernetes.
#
# Renders values.yaml (plus any --set overrides) and applies the release, then
# waits for the Deployment rollout to complete.
#
# Usage: ./deploy-chart.sh -r RELEASE -c CHART -n NAMESPACE \
#                          -g REGISTRY -i IMAGE_NAME -t TAG
#   -r RELEASE     Helm release name
#   -c CHART       Path to the Helm chart
#   -n NAMESPACE   Target Kubernetes namespace
#   -g REGISTRY    Docker Hub repository (e.g. maesh0004)
#   -i IMAGE_NAME  Image name (e.g. ride-connect)
#   -t TAG         Image tag (e.g. the build number)
# ---------------------------------------------------------------------------

usage() {
    echo "Usage: $0 -r RELEASE -c CHART -n NAMESPACE -g REGISTRY -i IMAGE_NAME -t TAG" >&2
    exit 1
}

while getopts "r:c:n:g:i:t:" opt; do
    case "$opt" in
        r) RELEASE=$OPTARG ;;
        c) CHART=$OPTARG ;;
        n) NAMESPACE=$OPTARG ;;
        g) REGISTRY=$OPTARG ;;
        i) IMAGE_NAME=$OPTARG ;;
        t) TAG=$OPTARG ;;
        *) usage ;;
    esac
done

if [[ -z "${RELEASE:-}" || -z "${CHART:-}" || -z "${NAMESPACE:-}" || \
      -z "${REGISTRY:-}" || -z "${IMAGE_NAME:-}" || -z "${TAG:-}" ]]; then
    usage
fi

echo "Deploying release '${RELEASE}' from '${CHART}' to namespace '${NAMESPACE}'..."

# The chart reads values.yaml by default. To deploy another environment later,
# create a values-<env>.yaml file and pass it with: -f values-<env>.yaml
helm upgrade --install "$RELEASE" "$CHART" \
  --namespace "$NAMESPACE" \
  --create-namespace \
  --set image.repository="$REGISTRY/$IMAGE_NAME" \
  --set image.tag="$TAG" \
  --wait \
  --timeout 5m

echo "Waiting for rollout..."

kubectl rollout status deployment/"$RELEASE" \
  -n "$NAMESPACE" \
  --timeout=300s

echo "Deployment completed successfully"
