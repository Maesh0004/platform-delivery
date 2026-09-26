#!/bin/bash
set -euo pipefail

RELEASE=$1
CHART=$2
NAMESPACE=$3
REGISTRY=$4
IMAGE_NAME=$5
TAG=$6

echo "Deploying release ${RELEASE} from ${CHART} to namespace ${NAMESPACE}..."

# The chart reads values.yaml by default. To deploy another environment later,
# create a values-<env>.yaml file and pass it with: -f values-<env>.yaml
#
# The chart derives resource names from the release name, so the Deployment is
# named after the release (see templates/_helpers.tpl).
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
