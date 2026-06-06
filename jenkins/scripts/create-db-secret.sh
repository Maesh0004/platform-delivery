#!/bin/bash

NAMESPACE=$1

# Application Secret

kubectl create secret generic ride-connect-secret \
  --from-literal=SPRING_DATASOURCE_USERNAME=$DB_USER \
  --from-literal=SPRING_DATASOURCE_PASSWORD=$DB_PASS \
  -n $NAMESPACE \
  --dry-run=client -o yaml | kubectl apply -f -

# MySQL Secret
kubectl create secret generic mysql-secret \
  --from-literal=MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_PASSWORD" \
  --from-literal=MYSQL_USER="$DB_USER" \
  --from-literal=MYSQL_PASSWORD="$DB_PASS" \
  -n "$NAMESPACE" \
  --dry-run=client -o yaml | kubectl apply -f -
