# ShopVerse GitOps (kops + Argo CD + ECR + Traefik)

This folder contains the Helm chart, Argo CD Application, and guidance to deploy ShopVerse to a kops cluster using ECR-hosted images and Traefik as the ingress.

## Quick summary
- CI builds frontend/backend images and pushes them to ECR.
- CI opens a Pull Request that updates `shopverse-gitops/helm/shopverse/values.yaml` with the new image tag.
- Merge the PR to `main` → Argo CD detects the change and syncs the Helm chart (it uses `values.yaml` + `values.kops.yaml`).

## Required GitHub Secrets
- `AWS_ACCESS_KEY_ID` - AWS key with permissions to push to ECR and optionally create secrets.
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION` - e.g. `us-east-1`
- `ECR_REGISTRY` - full ECR registry host (e.g. `123456789012.dkr.ecr.us-east-1.amazonaws.com`)
- `GITHUB_TOKEN` - used by the action to create PRs (provided by Actions by default).

## Optional for automatic cluster secret creation
- `KUBE_CONFIG_DATA` - base64-encoded kubeconfig for your kops cluster. If set, CI can create the `ecr-registry-secret` in-cluster.

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

## Key files
- `apps/argocd/shopverse-application.yaml` — Argo CD `Application` (points to this repository; syncs `helm/shopverse` using `values.yaml` and `values.kops.yaml`).
- `helm/shopverse/values.yaml` — base values (CI updates image fields here).
- `helm/shopverse/values.kops.yaml` — kops / Traefik overrides (set `frontend.ingressHost`, `backend.ingressHost`, `imagePullSecrets`).

## Cluster checklist (one-time)
1. Install Argo CD on the kops cluster and expose the server:
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

2. Install Traefik (LoadBalancer) in the cluster:
```bash
kubectl create namespace traefik
helm repo add traefik https://helm.traefik.io/traefik
helm repo update
helm install traefik traefik/traefik -n traefik --set service.type=LoadBalancer
```

3. Create the image-pull secret (or provide `KUBE_CONFIG_DATA` to CI):
```bash
kubectl create namespace shopverse
kubectl create secret docker-registry ecr-registry-secret \
        --docker-server=<ECR_REGISTRY> \
        --docker-username=AWS \
        --docker-password="$(aws ecr get-login-password --region <AWS_REGION>)" \
        -n shopverse
```

4. Edit `helm/shopverse/values.kops.yaml` and set `frontend.ingressHost` and `backend.ingressHost` to your DNS names.

## How CI interacts with GitOps
- The workflow `.github/workflows/deploy.yaml` builds and pushes Docker images, then updates `helm/shopverse/values.yaml` and opens a PR (`ci/gitops-update-<sha>`). Review/merge the PR to trigger Argo CD.

## Notes
- The Argo CD `Application` in this repo currently points to `https://github.com/Gangapratheep/shopverse.git` so Argo CD will sync from your repo.
- If you prefer direct pushes instead of PRs, the workflow can be adjusted to push to `main` automatically.

## Support
- If you want, I can change the workflow to push directly to `main`, or add automation to create DNS records, certificates, or the image-pull secret using Terraform/kops. Let me know which automation you prefer.
