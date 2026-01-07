#!/bin/bash
set -e

NAMESPACE=${1:-argocd}
RELEASE=${2:-argocd}

helm uninstall "$RELEASE" --namespace "$NAMESPACE"

echo "ArgoCD uninstalled from namespace $NAMESPACE."

