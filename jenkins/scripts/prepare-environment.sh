#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Prepare the target environment for a Helm deployment (idempotent).
#
# Creates the namespace plus the secrets the chart references:
#   - ride-connect-secret  application database credentials
#   - mysql-secret         MySQL root / user credentials
#   - dockerhub-secret     image pull secret
#
# Credentials are supplied by the CI job as environment variables:
#   DB_USER, DB_PASS, MYSQL_ROOT_PASSWORD, DOCKER_USER, DOCKER_PASS
#
# Usage: ./prepare-environment.sh -n NAMESPACE
#   -n NAMESPACE   Target Kubernetes namespace
# ---------------------------------------------------------------------------

usage() {
    echo "Usage: $0 -n NAMESPACE" >&2
    exit 1
}

while getopts "n:" opt; do
    case "$opt" in
        n) NAMESPACE=$OPTARG ;;
        *) usage ;;
    esac
done
[[ -z "${NAMESPACE:-}" ]] && usage

: "${DB_USER:?DB_USER is required}"
: "${DB_PASS:?DB_PASS is required}"
: "${MYSQL_ROOT_PASSWORD:?MYSQL_ROOT_PASSWORD is required}"
: "${DOCKER_USER:?DOCKER_USER is required}"
: "${DOCKER_PASS:?DOCKER_PASS is required}"

echo "Preparing environment '${NAMESPACE}'..."

# Namespace (idempotent - no-op if it already exists)
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Application database credentials
kubectl create secret generic ride-connect-secret \
    --from-literal=SPRING_DATASOURCE_USERNAME="$DB_USER" \
    --from-literal=SPRING_DATASOURCE_PASSWORD="$DB_PASS" \
    -n "$NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f -

# MySQL credentials
kubectl create secret generic mysql-secret \
    --from-literal=MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_PASSWORD" \
    --from-literal=MYSQL_USER="$DB_USER" \
    --from-literal=MYSQL_PASSWORD="$DB_PASS" \
    -n "$NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f -

# Image pull secret
kubectl create secret docker-registry dockerhub-secret \
    --docker-username="$DOCKER_USER" \
    --docker-password="$DOCKER_PASS" \
    --docker-server=https://index.docker.io/v1/ \
    -n "$NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f -

echo "Environment prepared successfully"
