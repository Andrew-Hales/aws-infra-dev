#!/bin/bash
set -e

NAMESPACE=${1:-argo-rollouts}
RELEASE=${2:-argo-rollouts}
VALUES=${3:-values.yaml}

# Add the Argo Rollouts Helm repo if not already present
helm repo add argo https://argoproj.github.io/argo-helm || true
helm repo update

# Create namespace if it doesn't exist
kubectl get namespace "$NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$NAMESPACE"

# Install or upgrade Argo Rollouts
helm upgrade --install "$RELEASE" argo/argo-rollouts \
  --namespace "$NAMESPACE" --create-namespace \
  -f "$VALUES"

echo "Argo Rollouts installed in namespace $NAMESPACE."

