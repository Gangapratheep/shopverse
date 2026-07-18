# ShopVerse GitOps

This folder contains the Helm chart and Argo CD application used to deploy ShopVerse to your kops cluster.

Required GitHub Secrets (for CI):
- `AWS_ACCESS_KEY_ID` - AWS key with permissions to push to ECR and optionally create secrets.
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION` - e.g. `us-east-1`
- `ECR_REGISTRY` - full ECR registry host (e.g. `123456789012.dkr.ecr.us-east-1.amazonaws.com`)
- `GITHUB_TOKEN` - default token provided to Actions is used for PR creation.

Optional for automatic cluster secret creation:
- `KUBE_CONFIG_DATA` - base64-encoded kubeconfig for the kops cluster. If provided, CI will attempt to create the `ecr-registry-secret` in the `shopverse` namespace.

How the flow works:
1. CI builds images and pushes to ECR.
2. CI updates `shopverse-gitops/helm/shopverse/values.yaml` with the new image tags and opens a Pull Request using `peter-evans/create-pull-request`.
3. Merge the PR into `main` to update the GitOps repo.
4. Argo CD (installed on the kops cluster) watches the GitOps repo and applies the Helm chart. The Argo CD `Application` is located at `apps/argocd/shopverse-application.yaml`.

Cluster setup checklist:
- Install Argo CD in the kops cluster and expose the server.
- Install Traefik (or your chosen ingress controller) and ensure it creates a LoadBalancer.
- Create the ECR image pull secret in `shopverse` namespace, named `ecr-registry-secret`, or provide `KUBE_CONFIG_DATA` to CI for automatic creation.

Helm values files:
- `values.yaml` — base values; CI will update image tags here.
- `values.kops.yaml` — kops/Traefik-specific overrides. Edit `frontend.ingressHost` and `backend.ingressHost` to match your DNS.

Argo CD Application:
- `apps/argocd/shopverse-application.yaml` — configures Argo CD to sync the Helm chart with `values.yaml` and `values.kops.yaml`.
