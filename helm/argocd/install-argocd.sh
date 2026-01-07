#!/bin/bash
set -e

NAMESPACE=${1:-argocd}
RELEASE=${2:-argocd}
VALUES=${3:-values.yaml}

helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm upgrade --install "$RELEASE" argo/argo-cd \
  --namespace "$NAMESPACE" --create-namespace \
  -f "$VALUES"

echo "ArgoCD installed in namespace $NAMESPACE."

