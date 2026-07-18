#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-$(aws sts get-caller-identity --query Account --output text)}"
ECR_REGISTRY="${ECR_REGISTRY:-${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com}"
NAMESPACE="${NAMESPACE:-shopverse}"
SECRET_NAME="${SECRET_NAME:-ecr-registry-secret}"

if ! command -v aws >/dev/null 2>&1; then
  echo "aws CLI is required but was not found" >&2
  exit 1
fi

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl is required but was not found" >&2
  exit 1
fi

PASSWORD="$(aws ecr get-login-password --region "$AWS_REGION")"

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

kubectl -n "$NAMESPACE" create secret docker-registry "$SECRET_NAME" \
  --docker-server="$ECR_REGISTRY" \
  --docker-username=AWS \
  --docker-password="$PASSWORD" \
  --docker-email=dev@example.com \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Created or updated secret '$SECRET_NAME' in namespace '$NAMESPACE'"
