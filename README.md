# ShopVerse - Step-by-Step Deployment Guide

ShopVerse is a full-stack e-commerce application with a React frontend, a Go Fiber backend, and a MySQL database. This repository includes everything needed to run it locally, deploy it to AWS with Terraform, and roll it out to a kOps-based Kubernetes cluster using GitHub Actions and Argo CD.

## 1. Project Overview

- Frontend: React 18 + Vite + Tailwind CSS
- Backend: Go 1.24 + Fiber + GORM + JWT
- Database: MySQL 8.0
- Deployment: Docker, Helm, Argo CD, GitHub Actions
- Target platform: AWS EKS / kOps-managed Kubernetes cluster

## 2. Local Development

### Step 1: Prerequisites
Install the following tools:
- Docker and Docker Compose
- Node.js 18+
- Go 1.24+

### Step 2: Start the app locally
```bash
git clone <repo-url>
cd shopverse
docker compose up --build
```

Access the application:
- Frontend: http://localhost:3000
- Backend: http://localhost:8080
- Health check: http://localhost:8080/health

### Step 3: Verify the app works
```bash
curl http://localhost:8080/health
curl http://localhost:3000/api/products
```

---

## 3. CI/CD and GitOps Flow

This repository is prepared for the following pipeline:

1. GitHub Actions runs tests and security checks.
2. Docker images are built and pushed to Amazon ECR.
3. The GitHub workflow updates the Helm values file.
4. Argo CD detects the GitOps change and deploys the updated release.

### Required GitHub Secrets
Add these in your GitHub repository settings:
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- AWS_REGION
- ECR_REGISTRY

Example values:
```text
AWS_REGION=us-east-1
ECR_REGISTRY=123456789012.dkr.ecr.us-east-1.amazonaws.com
```

---

## 4. Deploy to Your Existing kOps Cluster

### Step 1: Prepare the cluster
Make sure your existing kOps cluster has:
- kubectl configured and connected to the cluster
- Traefik installed
- a LoadBalancer service available for ingress
- permissions to pull images from ECR

### Step 2: Install Argo CD
```bash
cd shopverse-gitops
chmod +x scripts/install-argocd.sh
./scripts/install-argocd.sh
```

### Step 3: Create the ECR pull secret
```bash
cd shopverse-gitops
chmod +x scripts/create-ecr-secret.sh
AWS_REGION=us-east-1 \
AWS_ACCOUNT_ID=123456789012 \
ECR_REGISTRY=123456789012.dkr.ecr.us-east-1.amazonaws.com \
./scripts/create-ecr-secret.sh
```

### Step 4: Apply the Argo CD Application
```bash
kubectl apply -f apps/argocd/shopverse-application.yaml
```

### Step 5: Retrieve the Argo CD admin password
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

---

## 5. Helm and Ingress Configuration

The Helm chart is located in:
- [shopverse-gitops/helm/shopverse](shopverse-gitops/helm/shopverse)

Update the hostnames in [shopverse-gitops/helm/shopverse/values.kops.yaml](shopverse-gitops/helm/shopverse/values.kops.yaml) before deployment:
```yaml
frontend:
  ingressHost: shopverse.example.com

backend:
  ingressHost: api.shopverse.example.com
```

You should replace these placeholders with your real DNS names.

---

## 6. Traefik Setup for kOps

Use the provided values file at [traefik-values.yaml](traefik-values.yaml) when installing Traefik:
```bash
helm repo add traefik https://traefik.github.io/charts
helm repo update
helm install traefik traefik/traefik -f traefik-values.yaml -n kube-system
```

The values file configures Traefik to expose a LoadBalancer service for ingress traffic.

---

## 7. GitHub Actions Deployment Flow

Every push to the main branch will:
- run tests
- scan images for vulnerabilities
- build and push images to ECR
- update the Helm values used by Argo CD

After that, Argo CD will sync the deployment automatically.

---

## 8. Useful Commands

```bash
# Check pods
kubectl get pods -n shopverse

# Check services
kubectl get svc -n shopverse

# Check ingress
kubectl get ingress -n shopverse

# Check Argo CD applications
kubectl get applications -n argocd
```

---

## 9. Troubleshooting

If the app does not come up:
- check pod logs with `kubectl logs`
- verify the ECR image pull secret exists
- confirm the ingress host points to the correct DNS name
- verify Argo CD sync status in the Argo CD UI

---

## 10. Full Step-by-Step Checklist for Your kOps Cluster

### Step 1: Make sure your local machine can reach the cluster
Run these commands on your laptop or jump box:
```bash
kubectl get nodes
kubectl get ns
```
If these commands fail, fix your kubeconfig first.

### Step 2: Install prerequisites locally
Install the following tools if they are not already available:
```bash
kubectl version --client
helm version
aws --version
```

### Step 3: Configure AWS access
Make sure your AWS credentials are available:
```bash
aws configure
aws sts get-caller-identity
```

### Step 4: Create or confirm the ECR registry
You need an ECR registry for the frontend and backend images.
```bash
AWS_REGION=us-east-1
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY=${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

echo "$ECR_REGISTRY"
```

### Step 5: Install Traefik on the cluster
```bash
helm repo add traefik https://traefik.github.io/charts
helm repo update
helm install traefik traefik/traefik -f traefik-values.yaml -n kube-system
```

### Step 6: Verify Traefik is running
```bash
kubectl get pods -n kube-system | grep traefik
kubectl get svc -n kube-system | grep traefik
```

### Step 7: Install Argo CD
```bash
cd shopverse-gitops
chmod +x scripts/install-argocd.sh
./scripts/install-argocd.sh
```

### Step 8: Get Argo CD access details
```bash
kubectl get svc -n argocd
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

### Step 9: Create the ECR pull secret in the cluster
```bash
cd shopverse-gitops
chmod +x scripts/create-ecr-secret.sh
AWS_REGION=us-east-1 \
AWS_ACCOUNT_ID=123456789012 \
ECR_REGISTRY=123456789012.dkr.ecr.us-east-1.amazonaws.com \
./scripts/create-ecr-secret.sh
```

### Step 10: Update the Helm host values
Edit [shopverse-gitops/helm/shopverse/values.kops.yaml](shopverse-gitops/helm/shopverse/values.kops.yaml) and set real hostnames:
```yaml
frontend:
  ingressHost: shopverse.your-domain.com

backend:
  ingressHost: api.shopverse.your-domain.com
```

### Step 11: Add the required GitHub repository secrets
In GitHub, go to your repository settings and add:
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- AWS_REGION
- ECR_REGISTRY

Example:
```text
AWS_REGION=us-east-1
ECR_REGISTRY=123456789012.dkr.ecr.us-east-1.amazonaws.com
```

### Step 12: Push the changes to GitHub
```bash
git add .
git commit -m "chore: finalize Argo CD deployment flow"
git push origin main
```
This triggers the GitHub Actions workflow.

### Step 13: Watch the GitHub Actions workflow
Open the Actions tab in GitHub and confirm the workflow completes successfully.

### Step 14: Apply the Argo CD Application manifest
```bash
kubectl apply -f shopverse-gitops/apps/argocd/shopverse-application.yaml
```

### Step 15: Verify Argo CD sync status
```bash
kubectl get applications -n argocd
kubectl describe application shopverse -n argocd
```

### Step 16: Verify the app is running
```bash
kubectl get pods -n shopverse
kubectl get svc -n shopverse
kubectl get ingress -n shopverse
```

### Step 17: Access the application
Once the ingress and load balancer are ready, open your domain in the browser.

If your DNS is configured, the app should be available at:
- https://shopverse.your-domain.com
- https://api.shopverse.your-domain.com

---

## 18. Copy-Paste Commands Version

Use the commands below if you want to run the deployment flow directly from your terminal.

```bash
# 1) Set your values
export AWS_REGION=us-east-1
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
export FRONTEND_HOST="shopverse.your-domain.com"
export BACKEND_HOST="api.shopverse.your-domain.com"

echo "AWS_REGION=$AWS_REGION"
echo "ECR_REGISTRY=$ECR_REGISTRY"

echo "Checking cluster access..."
kubectl get nodes
kubectl get ns

# 2) Install Traefik
helm repo add traefik https://traefik.github.io/charts
helm repo update
helm install traefik traefik/traefik -f traefik-values.yaml -n kube-system

# 3) Install Argo CD
cd shopverse-gitops
chmod +x scripts/install-argocd.sh
./scripts/install-argocd.sh

# 4) Create the ECR pull secret
chmod +x scripts/create-ecr-secret.sh
AWS_REGION="$AWS_REGION" \
AWS_ACCOUNT_ID="$AWS_ACCOUNT_ID" \
ECR_REGISTRY="$ECR_REGISTRY" \
./scripts/create-ecr-secret.sh

# 5) Update the ingress hostnames in the Helm values file
python - <<'PY'
from pathlib import Path
path = Path('shopverse-gitops/helm/shopverse/values.kops.yaml')
text = path.read_text()
text = text.replace('shopverse.example.com', 'shopverse.your-domain.com')
text = text.replace('api.shopverse.example.com', 'api.shopverse.your-domain.com')
path.write_text(text)
PY

# 6) Apply the Argo CD Application
kubectl apply -f apps/argocd/shopverse-application.yaml

# 7) Get the Argo CD admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d

# 8) Verify resources
kubectl get applications -n argocd
kubectl get pods -n shopverse
kubectl get svc -n shopverse
kubectl get ingress -n shopverse
```

> Replace the example domains with your real DNS names before you run the commands.

---

## Querying the Database

### Understanding the Database

ShopVerse uses MySQL 8.0 running as a Kubernetes StatefulSet. The database contains these tables:

| Table | Description |
|-------|-------------|
| `users` | Registered users (name, email, hashed password) |
| `products` | Product catalog - 28 products across 6 categories |
| `orders` | Customer orders (total amount, status, timestamps) |
| `order_items` | Individual items within each order (product, quantity, price) |
| `cart_items` | Current shopping cart contents per user |

### Step 1: Get the Database Password

The MySQL password is stored as a Kubernetes secret (base64 encoded):

```bash
# Decode the database password from the Kubernetes secret
DB_PASSWORD=$(kubectl get secret -n shopverse shopverse-secret \
  -o jsonpath='{.data.DB_PASSWORD}' | base64 -d)

# Verify you got the password (optional)
echo $DB_PASSWORD
```

**How this works:**
- `kubectl get secret` fetches the Kubernetes secret object
- `-o jsonpath='{.data.DB_PASSWORD}'` extracts just the password field
- `| base64 -d` decodes it from base64 (Kubernetes stores secrets in base64)

### Step 2: Connect to MySQL Shell

```bash
# Open an interactive MySQL shell inside the MySQL pod
kubectl exec -it -n shopverse shopverse-mysql-0 -- mysql -u shopverse -p"$DB_PASSWORD" shopverse
```

**How this works:**
- `kubectl exec -it` runs an interactive command inside a pod
- `-n shopverse` specifies the namespace
- `shopverse-mysql-0` is the MySQL pod name (StatefulSet pod naming: `<name>-0`)
- `-- mysql -u shopverse -p"$DB_PASSWORD" shopverse` runs the MySQL client
  - `-u shopverse` = database username
  - `-p"$DB_PASSWORD"` = password (no space between `-p` and the password)
  - `shopverse` (at end) = database name to connect to

### Step 3: Run Queries Inside MySQL Shell

Once inside the MySQL shell (you'll see `mysql>` prompt):

#### View all tables
```sql
SHOW TABLES;
```
This shows all 5 tables: `users`, `products`, `orders`, `order_items`, `cart_items`.

#### View registered users
```sql
SELECT id, name, email, created_at FROM users;
```
Shows all users who registered through the app. Passwords are hashed with bcrypt so they are not shown here.

#### View all products
```sql
SELECT id, name, category, price, original_price, rating, badge FROM products;
```
Lists all 28 seeded products with their category, pricing, rating, and badge info.

#### View products grouped by category
```sql
SELECT category, COUNT(*) AS total_products,
       ROUND(AVG(price), 2) AS avg_price,
       ROUND(MIN(price), 2) AS min_price,
       ROUND(MAX(price), 2) AS max_price
FROM products
GROUP BY category
ORDER BY total_products DESC;
```
Shows product count and price stats per category (Electronics, Clothing, Accessories, Food & Drinks, Sports, Home & Living).

#### View all orders with customer info
```sql
SELECT
    o.id AS order_id,
    u.name AS customer_name,
    u.email AS customer_email,
    o.total_amount,
    o.status,
    o.created_at AS order_date
FROM orders o
JOIN users u ON o.user_id = u.id
ORDER BY o.created_at DESC;
```
**How this works:**
- `JOIN users u ON o.user_id = u.id` links each order to the user who placed it
- `ORDER BY o.created_at DESC` shows newest orders first
- `o.status` shows the order status (e.g., pending, completed)

#### View order items with product details
```sql
SELECT
    oi.order_id,
    p.name AS product_name,
    p.category,
    oi.quantity,
    oi.price AS unit_price,
    (oi.quantity * oi.price) AS subtotal
FROM order_items oi
JOIN products p ON oi.product_id = p.id
ORDER BY oi.order_id, p.name;
```
**How this works:**
- `order_items` stores what was purchased in each order
- `JOIN products p ON oi.product_id = p.id` links item to its product details
- `(oi.quantity * oi.price)` calculates the subtotal for each line item

#### View complete order breakdown (orders + items together)
```sql
SELECT
    o.id AS order_id,
    u.name AS customer,
    p.name AS product,
    oi.quantity,
    oi.price AS unit_price,
    (oi.quantity * oi.price) AS subtotal,
    o.total_amount AS order_total,
    o.status,
    o.created_at
FROM orders o
JOIN users u ON o.user_id = u.id
JOIN order_items oi ON oi.order_id = o.id
JOIN products p ON oi.product_id = p.id
ORDER BY o.id, p.name;
```
This is the most complete view - joins 4 tables to show who ordered what, quantities, prices, and order status.

#### View current cart items
```sql
SELECT
    ci.id AS cart_item_id,
    u.name AS customer,
    p.name AS product,
    p.category,
    ci.quantity,
    p.price AS unit_price,
    (ci.quantity * p.price) AS subtotal
FROM cart_items ci
JOIN users u ON ci.user_id = u.id
JOIN products p ON ci.product_id = p.id
ORDER BY u.name;
```
Shows items currently in users' shopping carts (items that haven't been ordered yet).

#### Dashboard summary
```sql
SELECT
    (SELECT COUNT(*) FROM users) AS total_users,
    (SELECT COUNT(*) FROM products) AS total_products,
    (SELECT COUNT(*) FROM orders) AS total_orders,
    (SELECT COALESCE(SUM(total_amount), 0) FROM orders) AS total_revenue,
    (SELECT COUNT(*) FROM cart_items) AS items_in_carts;
```
A quick overview of the entire application's data - total users, products, orders, revenue, and active cart items.

#### Exit MySQL shell
```sql
EXIT;
```

### Quick One-Liner Queries (Without Entering MySQL Shell)

These run a query directly from your terminal without opening the interactive MySQL shell:

```bash
# First, get the DB password
DB_PASSWORD=$(kubectl get secret -n shopverse shopverse-secret \
  -o jsonpath='{.data.DB_PASSWORD}' | base64 -d)
```

```bash
# List all registered users
kubectl exec -n shopverse shopverse-mysql-0 -- \
  mysql -u shopverse -p"$DB_PASSWORD" shopverse \
  -e "SELECT id, name, email, created_at FROM users;"
```

```bash
# List all orders with customer names
kubectl exec -n shopverse shopverse-mysql-0 -- \
  mysql -u shopverse -p"$DB_PASSWORD" shopverse \
  -e "SELECT o.id, u.name, o.total_amount, o.status, o.created_at FROM orders o JOIN users u ON o.user_id = u.id;"
```

```bash
# List order items with product details
kubectl exec -n shopverse shopverse-mysql-0 -- \
  mysql -u shopverse -p"$DB_PASSWORD" shopverse \
  -e "SELECT oi.order_id, p.name, oi.quantity, oi.price, (oi.quantity * oi.price) AS subtotal FROM order_items oi JOIN products p ON oi.product_id = p.id ORDER BY oi.order_id;"
```

```bash
# Count products per category
kubectl exec -n shopverse shopverse-mysql-0 -- \
  mysql -u shopverse -p"$DB_PASSWORD" shopverse \
  -e "SELECT category, COUNT(*) AS count FROM products GROUP BY category ORDER BY count DESC;"
```

```bash
# Quick dashboard summary
kubectl exec -n shopverse shopverse-mysql-0 -- \
  mysql -u shopverse -p"$DB_PASSWORD" shopverse \
  -e "SELECT (SELECT COUNT(*) FROM users) AS users, (SELECT COUNT(*) FROM products) AS products, (SELECT COUNT(*) FROM orders) AS orders, (SELECT COALESCE(SUM(total_amount),0) FROM orders) AS revenue;"
```

**How the `-e` flag works:**
- `-e "SQL QUERY"` executes the query and exits immediately (no interactive shell)
- Useful for quick checks or scripting

---

## CI/CD Pipeline (GitHub Actions)

### Configure GitHub Secrets

Go to your GitHub repo > Settings > Secrets and variables > Actions, and add:

| Secret                  | Description                                          |
|-------------------------|------------------------------------------------------|
| `AWS_ACCESS_KEY_ID`     | IAM user access key                                  |
| `AWS_SECRET_ACCESS_KEY` | IAM user secret key                                  |
| `AWS_REGION`            | e.g., `us-east-1`                                    |
| `ECR_REGISTRY`          | e.g., `123456789.dkr.ecr.us-east-1.amazonaws.com`    |
| `EKS_CLUSTER_NAME`      | e.g., `shopverse-cluster`                            |
| `TF_STATE_BUCKET`       | Root@1234                                            |
| `MYSQL_ROOT_PASSWORD`   | MySQL root password                                  |
| `MYSQL_PASSWORD`        | App@1234                                             |
| `JWT_SECRET`            | shopverse-secret-key-2024                            |

### Pipeline Stages

Push to `main` branch triggers the 4-stage pipeline:

1. **Test** - Go tests + frontend linting
2. **Security Scan** - Trivy vulnerability scanning on Docker images
3. **Build & Push** - Build images, tag with SHA, push to ECR
4. **Deploy** - Provision infra with Terraform if needed, deploy Helm chart

---

## Modify / Scale the Application

```bash
# Scale frontend to 3 replicas
kubectl scale deployment shopverse-frontend -n shopverse --replicas=3

# Scale backend to 3 replicas
kubectl scale deployment shopverse-backend -n shopverse --replicas=3

# Rolling restart (picks up new config without downtime)
kubectl rollout restart deployment/shopverse-frontend -n shopverse
kubectl rollout restart deployment/shopverse-backend -n shopverse

# Update images (deploy new version)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URI=${ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com

helm upgrade shopverse ./helm/shopverse \
  --set frontend.image=${ECR_URI}/shopverse-frontend:v2 \
  --set backend.image=${ECR_URI}/shopverse-backend:v2 \
  --reuse-values -n shopverse
```

## Destroy Everything

```bash
# Step 1: Delete application resources
helm uninstall shopverse -n shopverse
kubectl delete pvc --all -n shopverse
kubectl delete namespace shopverse

# Step 2: Destroy AWS infrastructure
cd terraform
terraform destroy
# Type 'yes' when prompted
```

> **Warning:** This deletes the EKS cluster, VPC, jump server, and all associated resources.

---

## Project Structure

```
shopverse/
├── frontend/                  # React + TailwindCSS (Vite)
│   ├── src/
│   │   ├── components/        # Navbar, ProductCard, CartSidebar
│   │   ├── pages/             # Auth, Home, Products, Cart, Orders, Wishlist
│   │   ├── App.jsx            # Routes, context, API client
│   │   └── main.jsx           # Entry point
│   ├── Dockerfile             # Multi-stage: Node -> Nginx
│   └── nginx.conf             # React Router + API proxy
├── backend/                   # Go + Fiber REST API
│   ├── cmd/main.go            # Entry point, routes
│   ├── internal/
│   │   ├── handlers/          # Auth, Products, Cart, Orders
│   │   ├── models/            # GORM models
│   │   ├── database/          # DB connection + seed data (28 products)
│   │   └── middleware/        # JWT auth middleware
│   └── Dockerfile             # Multi-stage: Go -> Distroless
├── helm/shopverse/            # Helm chart
│   ├── templates/             # K8s manifests (10 YAML files)
│   │   ├── secret.yaml        # DB passwords, JWT secret
│   │   ├── configmap.yaml     # DB host, port, name config
│   │   ├── mysql-pvc.yaml     # 5Gi persistent volume claim
│   │   ├── mysql-statefulset.yaml  # MySQL 8.0 pod
│   │   ├── mysql-service.yaml      # MySQL ClusterIP service
│   │   ├── backend-deployment.yaml # Go API (2 replicas)
│   │   ├── backend-service.yaml    # NodePort 30081
│   │   ├── frontend-deployment.yaml # React+Nginx (2 replicas)
│   │   ├── frontend-service.yaml    # NodePort 30080
│   │   └── ingress.yaml            # ALB ingress
│   ├── values.yaml            # Configurable values
│   └── Chart.yaml             # Chart metadata
├── terraform/                 # Infrastructure as Code (Modules)
│   ├── main.tf                # Root - wires all modules
│   ├── variables.tf           # Root input variables
│   ├── outputs.tf             # Root outputs
│   ├── versions.tf            # Provider versions + S3 backend
│   ├── terraform.tfvars.example
│   ├── README.md              # Detailed Terraform guide
│   └── modules/
│       ├── vpc/               # VPC, subnets, IGW, NAT, routes
│       ├── eks/               # EKS cluster, node group, OIDC, addons
│       └── ec2/               # Jump server (Ubuntu 22.04)
├── .github/workflows/         # CI/CD pipeline
│   └── deploy.yml             # 4-stage: test -> scan -> build -> deploy
├── docker-compose.yml         # Local development
└── README.md
```

## Troubleshooting

### Pods stuck in Pending
```bash
kubectl describe pod <pod-name> -n shopverse
kubectl get pvc -n shopverse
# Common cause: EBS CSI driver not installed (PVC can't bind)
```

### Frontend can't reach backend (502/504)
```bash
kubectl get svc -n shopverse
kubectl logs -n shopverse -l component=backend
# Verify backend pods are running and healthy
```

### MySQL connection refused
```bash
kubectl get pods -n shopverse -l component=mysql
kubectl logs -n shopverse shopverse-mysql-0
# Check if MySQL is still initializing
```

### Can't access NodePort from browser
```bash
# Check node security group allows ports 30080 and 30081
# AWS Console > EC2 > Security Groups > Node security group > Inbound rules
# Add: Custom TCP, Port 30080, Source 0.0.0.0/0
# Add: Custom TCP, Port 30081, Source 0.0.0.0/0
```

### Images not updating after push
```bash
# Use a new tag instead of reusing the same one
helm upgrade shopverse ./helm/shopverse \
  --set frontend.image=<ECR>/shopverse-frontend:v2 \
  --set backend.image=<ECR>/shopverse-backend:v2 \
  --reuse-values -n shopverse
```




**pipeline**

```
name: ShopVerse CI/CD

on:
  push:
    branches: [main]

env:
  AWS_REGION: ${{ secrets.AWS_REGION }}
  ECR_REGISTRY: ${{ secrets.ECR_REGISTRY }}
  EKS_CLUSTER_NAME: ${{ secrets.EKS_CLUSTER_NAME }}
  HELM_CHART_NAME: shopverse
  TF_STATE_BUCKET: ${{ secrets.TF_STATE_BUCKET }}

jobs:
  # ──────────────────────────────────────────────
  # Stage 1: Test
  # ──────────────────────────────────────────────
  test:
    name: Test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Go
        uses: actions/setup-go@v5
        with:
          go-version: "1.24"

      - name: Update go.sum
        working-directory: ./backend
        run: go mod tidy

      - name: Run Go tests
        working-directory: ./backend
        run: go test ./...

      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: "18"

      - name: Install frontend dependencies
        working-directory: ./frontend
        run: npm install

      - name: Run frontend lint
        working-directory: ./frontend
        run: npx eslint . --ext js,jsx --report-unused-disable-directives --max-warnings 0 --config .eslintrc.cjs

  # ──────────────────────────────────────────────
  # Stage 2: Security Scan
  # ──────────────────────────────────────────────
  security-scan:
    name: Security Scan
    runs-on: ubuntu-latest
    needs: test
    steps:
      - uses: actions/checkout@v4

      - name: Build frontend image
        run: docker build -t shopverse-frontend:scan ./frontend

      - name: Build backend image
        run: docker build -t shopverse-backend:scan ./backend

      - name: Install Trivy
        run: |
          sudo apt-get install -y wget apt-transport-https gnupg
          wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
          echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" | sudo tee /etc/apt/sources.list.d/trivy.list
          sudo apt-get update -q
          sudo apt-get install -y trivy

      - name: Run Trivy scan on frontend
        run: |
          trivy image --exit-code 1 --severity CRITICAL --ignore-unfixed --format table shopverse-frontend:scan

      - name: Run Trivy scan on backend
        run: |
          trivy image --exit-code 1 --severity CRITICAL --ignore-unfixed --format table shopverse-backend:scan

  # ──────────────────────────────────────────────
  # Stage 3: Build, Tag & Push Images + Helm Chart
  # ──────────────────────────────────────────────
  build-and-push:
    name: Build, Tag & Push
    runs-on: ubuntu-latest
    needs: security-scan
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2

      - name: Ensure ECR repositories exist
        run: |
          for repo in shopverse-frontend shopverse-backend shopverse-helmchart/shopverse; do
            aws ecr describe-repositories --repository-names $repo --region ${{ env.AWS_REGION }} 2>/dev/null || \
            aws ecr create-repository --repository-name $repo --region ${{ env.AWS_REGION }}
          done

      - name: Build and tag frontend image
        run: |
          docker build -t ${{ env.ECR_REGISTRY }}/shopverse-frontend:${{ github.sha }} \
                        -t ${{ env.ECR_REGISTRY }}/shopverse-frontend:latest \
                        ./frontend

      - name: Build and tag backend image
        run: |
          docker build -t ${{ env.ECR_REGISTRY }}/shopverse-backend:${{ github.sha }} \
                        -t ${{ env.ECR_REGISTRY }}/shopverse-backend:latest \
                        ./backend

      - name: Push frontend image
        run: |
          docker push ${{ env.ECR_REGISTRY }}/shopverse-frontend:${{ github.sha }}
          docker push ${{ env.ECR_REGISTRY }}/shopverse-frontend:latest

      - name: Push backend image
        run: |
          docker push ${{ env.ECR_REGISTRY }}/shopverse-backend:${{ github.sha }}
          docker push ${{ env.ECR_REGISTRY }}/shopverse-backend:latest

      - name: Update Helm values.yaml with new image tags
        run: |
          FRONTEND_IMG="${{ env.ECR_REGISTRY }}/shopverse-frontend:${{ github.sha }}"
          BACKEND_IMG="${{ env.ECR_REGISTRY }}/shopverse-backend:${{ github.sha }}"
          sed -i "s|image:.*# frontend-image|image: ${FRONTEND_IMG}  # frontend-image|" helm/shopverse/values.yaml
          sed -i "s|image:.*# backend-image|image: ${BACKEND_IMG}  # backend-image|" helm/shopverse/values.yaml
          echo "Updated values.yaml:"
          cat helm/shopverse/values.yaml

      - name: Install Helm
        uses: azure/setup-helm@v3

      - name: Login Helm to ECR
        run: |
          aws ecr get-login-password --region ${{ env.AWS_REGION }} | \
            helm registry login --username AWS --password-stdin ${{ env.ECR_REGISTRY }}

      - name: Package Helm chart
        run: |
          helm package ./helm/shopverse \
            --version 1.0.0-${{ github.sha }} \
            --app-version ${{ github.sha }}

      - name: Push Helm chart to ECR
        run: |
          helm push shopverse-1.0.0-${{ github.sha }}.tgz \
            oci://${{ env.ECR_REGISTRY }}/shopverse-helmchart

  # ──────────────────────────────────────────────
  # Stage 4: Provision Infra (if needed) + Deploy
  # ──────────────────────────────────────────────
  deploy:
    name: Provision Infra & Deploy
    runs-on: ubuntu-latest
    needs: build-and-push
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Check if EKS cluster exists
        id: check-cluster
        run: |
          if aws eks describe-cluster --name ${{ env.EKS_CLUSTER_NAME }} --region ${{ env.AWS_REGION }} > /dev/null 2>&1; then
            echo "cluster_exists=true" >> "$GITHUB_OUTPUT"
            echo "EKS cluster '${{ env.EKS_CLUSTER_NAME }}' found."
          else
            echo "cluster_exists=false" >> "$GITHUB_OUTPUT"
            echo "EKS cluster '${{ env.EKS_CLUSTER_NAME }}' NOT found. Will provision with Terraform."
          fi

      - name: Setup Terraform
        if: steps.check-cluster.outputs.cluster_exists == 'false'
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "1.7.0"

      - name: Terraform Init
        if: steps.check-cluster.outputs.cluster_exists == 'false'
        working-directory: ./terraform
        run: |
          terraform init \
            -backend-config="bucket=${{ env.TF_STATE_BUCKET }}" \
            -backend-config="key=eks/terraform.tfstate" \
            -backend-config="region=${{ env.AWS_REGION }}"

      - name: Terraform Plan
        if: steps.check-cluster.outputs.cluster_exists == 'false'
        working-directory: ./terraform
        run: |
          terraform plan \
            -var="aws_region=${{ env.AWS_REGION }}" \
            -var="cluster_name=${{ env.EKS_CLUSTER_NAME }}" \
            -var="project_name=shopverse" \
            -var="create_jump_server=false" \
            -out=tfplan

      - name: Terraform Apply
        if: steps.check-cluster.outputs.cluster_exists == 'false'
        working-directory: ./terraform
        run: terraform apply -auto-approve tfplan

      - name: Wait for EKS cluster to be active
        if: steps.check-cluster.outputs.cluster_exists == 'false'
        run: |
          echo "Waiting for EKS cluster to become ACTIVE..."
          aws eks wait cluster-active --name ${{ env.EKS_CLUSTER_NAME }} --region ${{ env.AWS_REGION }}
          echo "Waiting for node group to become ACTIVE..."
          aws eks wait nodegroup-active \
            --cluster-name ${{ env.EKS_CLUSTER_NAME }} \
            --nodegroup-name ${{ env.EKS_CLUSTER_NAME }}-nodes \
            --region ${{ env.AWS_REGION }}
          echo "Cluster and nodes are ready."

      - name: Install AWS Load Balancer Controller
        if: steps.check-cluster.outputs.cluster_exists == 'false'
        run: |
          aws eks update-kubeconfig --name ${{ env.EKS_CLUSTER_NAME }} --region ${{ env.AWS_REGION }}
          helm repo add eks https://aws.github.io/eks-charts
          helm repo update
          ALB_ROLE_ARN=$(cd terraform && terraform output -raw alb_controller_role_arn)
          helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
            -n kube-system \
            --set clusterName=${{ env.EKS_CLUSTER_NAME }} \
            --set serviceAccount.create=true \
            --set serviceAccount.name=aws-load-balancer-controller \
            --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=$ALB_ROLE_ARN

      - name: Install kubectl
        uses: azure/setup-kubectl@v3

      - name: Install Helm
        uses: azure/setup-helm@v3

      - name: Update kubeconfig
        run: aws eks update-kubeconfig --name ${{ env.EKS_CLUSTER_NAME }} --region ${{ env.AWS_REGION }}

      - name: Login to ECR for Helm
        run: |
          aws ecr get-login-password --region ${{ env.AWS_REGION }} | \
            helm registry login --username AWS --password-stdin ${{ env.ECR_REGISTRY }}

      - name: Deploy Helm chart
        run: |
          helm upgrade --install shopverse \
            oci://${{ env.ECR_REGISTRY }}/shopverse-helmchart/shopverse \
            --version 1.0.0-${{ github.sha }} \
            --set frontend.image=${{ env.ECR_REGISTRY }}/shopverse-frontend:${{ github.sha }} \
            --set backend.image=${{ env.ECR_REGISTRY }}/shopverse-backend:${{ github.sha }} \
            --set mysql.rootPassword=${{ secrets.MYSQL_ROOT_PASSWORD }} \
            --set mysql.password=${{ secrets.MYSQL_PASSWORD }} \
            --set jwtSecret=${{ secrets.JWT_SECRET }} \
            --namespace shopverse \
            --create-namespace \
            --wait --timeout 300s \
            --cleanup-on-fail

      - name: Verify deployment
        run: |
          echo ""
          echo "--- Nodes ---"
          kubectl get nodes -o wide
          echo ""
          echo "--- Pods ---"
          kubectl get pods -n shopverse
          echo ""
          echo "--- StatefulSets ---"
          kubectl get sts -n shopverse
          echo ""
          echo "--- Services ---"
          kubectl get svc -n shopverse
          echo ""
          echo "--- PV & PVC ---"
          kubectl get pv,pvc -n shopverse
          echo ""
          echo "--- Secrets ---"
          kubectl get secrets -n shopverse
          echo ""
          echo "--- Ingress ---"
          kubectl get ingress -n shopverse 2>/dev/null || echo "No ingress configured"



```

---

## License

MIT
