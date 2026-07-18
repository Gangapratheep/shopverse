#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-argocd}"
ARGOCD_VERSION="${ARGOCD_VERSION:-v2.11.0}"

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl is required but was not found" >&2
  exit 1
fi

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -n "$NAMESPACE" -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"

kubectl patch svc argocd-server -n "$NAMESPACE" --type='merge' -p '{"spec":{"type":"LoadBalancer"}}' >/dev/null 2>&1 || true

echo "Argo CD installed in namespace '$NAMESPACE'."
echo "To get the initial admin password:"
echo "  kubectl -n $NAMESPACE get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
