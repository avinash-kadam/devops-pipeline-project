# DevOps Pipeline Demo

A full end-to-end DevOps project built to demonstrate a production-style CI/CD pipeline using:
**Flask · Docker · Jenkins · Ansible · Terraform · Kubernetes · AWS**

---

## What This Project Does

A push to the `main` branch kicks off a Jenkins pipeline that:
1. Runs tests and checks coverage
2. Builds a Docker image and pushes it to Docker Hub
3. Uses Ansible to configure the target server
4. Deploys the new image to a Kubernetes cluster (Minikube locally, EKS in prod)

The app itself is a simple task management REST API — the point isn't the app, it's the pipeline around it.

---

## Architecture

```
Developer (local)
      │
      │  git push origin main
      ▼
   GitHub Repo
      │
      │  Webhook (POST /github-webhook/)
      ▼
   Jenkins
      ├── Run tests (pytest)
      ├── Build Docker image
      ├── Push to Docker Hub
      ├── Run Ansible playbook
      │       └── SSH into EC2
      │           └── Pull & run latest container
      └── kubectl apply → Kubernetes cluster
                └── Rolling deploy (zero downtime)
```

**Infrastructure (Terraform):**
```
AWS us-east-1
└── VPC (10.0.0.0/16)
    └── Public Subnet (10.0.1.0/24)
        ├── EC2 t2.micro  ← app runs here
        └── Security Group (port 80 open, port 22 locked to your IP)
```

---

## Project Structure

```
devops-pipeline-project/
├── app/                        # Flask application
│   ├── app.py                  # API routes
│   ├── requirements.txt
│   ├── .dockerignore
│   └── tests/
│       └── test_app.py
│
├── docker/
│   ├── Dockerfile              # Multi-stage, non-root user
│   └── docker-compose.yml      # Local dev stack
│
├── jenkins/
│   ├── Jenkinsfile             # Declarative pipeline (5 stages)
│   └── JENKINS_SETUP.md
│
├── ansible/
│   ├── ansible.cfg
│   ├── inventory/
│   │   └── hosts.ini           # EC2 target hosts (gitignored)
│   ├── playbooks/
│   │   └── provision.yml       # Main playbook
│   └── roles/
│       ├── docker/             # Installs Docker on server
│       └── webserver/          # Deploys app container
│
├── terraform/
│   ├── main.tf                 # VPC, Subnet, EC2, Security Group
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
│
├── kubernetes/
│   └── manifests/
│       ├── namespace.yaml
│       ├── deployment.yaml     # 2 replicas, rolling update
│       ├── service.yaml        # NodePort (or LoadBalancer on EKS)
│       └── configmap.yaml
│
├── scripts/
│   └── local-run.sh            # Dev shortcuts (build/test/deploy)
│
└── docs/
    └── SETUP.md                # Step-by-step environment setup
```

---

## Quick Start (Local — No AWS Needed)

### Prerequisites
- Docker + Docker Compose
- Minikube (`brew install minikube` or see [minikube.sigs.k8s.io](https://minikube.sigs.k8s.io))
- kubectl
- Python 3.11+

### 1. Run the app locally

```bash
git clone https://github.com/yourusername/devops-pipeline-project.git
cd devops-pipeline-project

# Start with Docker Compose
./scripts/local-run.sh run

# App is up at:
curl http://localhost:5000/
curl http://localhost:5000/health
curl http://localhost:5000/tasks
```

### 2. Run tests

```bash
./scripts/local-run.sh test
```

### 3. Deploy to local Kubernetes (Minikube)

```bash
# Start Minikube
minikube start

# Build image inside Minikube's Docker daemon (no push needed locally)
eval $(minikube docker-env)
./scripts/local-run.sh build

# Deploy
./scripts/local-run.sh k8s-deploy
./scripts/local-run.sh k8s-status

# Get the app URL from Minikube
minikube service devops-demo-app-svc --url
```

---

## AWS Deployment (Full Pipeline)

### Step 1 — Provision infrastructure with Terraform

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: add your key pair name and your IP

terraform init
terraform plan     # review what will be created
terraform apply    # creates VPC, Subnet, EC2, Security Group
```

Copy the `instance_public_ip` from the output.

### Step 2 — Update Ansible inventory

```bash
# Edit ansible/inventory/hosts.ini
# Replace <EC2_PUBLIC_IP> with the IP from Terraform output
```

### Step 3 — Run Ansible manually (or let Jenkins do it)

```bash
cd ansible
ansible-playbook -i inventory/hosts.ini playbooks/provision.yml
```

### Step 4 — Set up Jenkins (one-time)

See `jenkins/JENKINS_SETUP.md` for the full walkthrough. Summary:
1. Run Jenkins in Docker
2. Add Docker Hub and kubeconfig credentials
3. Create a Pipeline job pointing to this repo
4. Add a GitHub webhook

### Step 5 — Push and watch it deploy

```bash
git add .
git commit -m "trigger pipeline"
git push origin main
# Jenkins picks it up → tests → builds → pushes → deploys
```

---

## API Endpoints

| Method | Endpoint       | Description              |
|--------|----------------|--------------------------|
| GET    | `/`            | App info + hostname      |
| GET    | `/health`      | Liveness/readiness probe |
| GET    | `/tasks`       | List all tasks           |
| GET    | `/tasks/<id>`  | Get a single task        |
| POST   | `/tasks`       | Create a new task        |

Example:
```bash
curl -X POST http://localhost:5000/tasks \
  -H "Content-Type: application/json" \
  -d '{"title": "Write Terraform modules"}'
```

---

## Environment Variables

| Variable      | Default       | Description                    |
|---------------|---------------|--------------------------------|
| `APP_ENV`     | development   | Environment name               |
| `APP_VERSION` | 1.0.0         | Injected by Jenkins build num  |
| `PORT`        | 5000          | Port the app listens on        |

---

## Tools & Versions Used

| Tool       | Version  | Purpose                            |
|------------|----------|------------------------------------|
| Python     | 3.11     | Application runtime                |
| Flask      | 3.0.3    | Web framework                      |
| Docker     | 24+      | Containerisation                   |
| Jenkins    | LTS      | CI/CD automation                   |
| Ansible    | 2.15+    | Server provisioning                |
| Terraform  | 1.6+     | Infrastructure as Code             |
| Kubernetes | 1.28+    | Container orchestration            |
| AWS        | -        | Cloud provider (free tier)         |

---

## Tear Down AWS Resources

When you're done, avoid unexpected charges:

```bash
cd terraform
terraform destroy
```

---

## License

MIT
