# ShopVerse GitOps

This folder contains the Helm chart and Argo CD application used to deploy ShopVerse to your kops cluster.

## Required GitHub Secrets
- `AWS_ACCESS_KEY_ID` - AWS key with permissions to push to ECR and optionally create secrets.
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION` - e.g. `us-east-1`
- `ECR_REGISTRY` - full ECR registry host (e.g. `123456789012.dkr.ecr.us-east-1.amazonaws.com`)

## How the flow works
1. CI builds images and pushes them to ECR.
2. CI updates the Helm values file with the new image tags.
3. Argo CD detects the change and applies the Helm chart to your cluster.

## Cluster setup checklist
- Install Argo CD in the kops cluster and expose the server.
- Install Traefik (or your chosen ingress controller) and ensure it creates a LoadBalancer.
- Create the ECR image pull secret in the `shopverse` namespace, named `ecr-registry-secret`.

## Install Argo CD on the cluster
Run the helper script from a machine that has access to your kops cluster:

```bash
cd shopverse-gitops
chmod +x scripts/install-argocd.sh
./scripts/install-argocd.sh
```

## Create the ECR pull secret
Run the helper script from a machine that has access to your kops cluster:

```bash
cd shopverse-gitops
chmod +x scripts/create-ecr-secret.sh
AWS_REGION=us-east-1 \
AWS_ACCOUNT_ID=123456789012 \
ECR_REGISTRY=123456789012.dkr.ecr.us-east-1.amazonaws.com \
./scripts/create-ecr-secret.sh
```

## Apply the Argo CD Application

```bash
kubectl apply -f apps/argocd/shopverse-application.yaml
```

## Helm values files
- `helm/shopverse/values.yaml` — base values; CI updates image tags here.
- `helm/shopverse/values.kops.yaml` — kops/Traefik-specific overrides. Edit `frontend.ingressHost` and `backend.ingressHost` to match your DNS.

