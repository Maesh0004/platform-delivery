#!/bin/bash

NAMESPACE=$1

kubectl create secret generic ride-connect-secret \
  --from-literal=SPRING_DATASOURCE_USERNAME=$DB_USER \
  --from-literal=SPRING_DATASOURCE_PASSWORD=$DB_PASS \
  -n $NAMESPACE \
  --dry-run=client -o yaml | kubectl apply -f -