# Environment Setup Guide

Step-by-step installation for every tool used in this project.
All free. AWS free tier is enough to run the full pipeline.

---

## 1. Git & GitHub

```bash
# Check if installed
git --version

# Configure identity (required before first commit)
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

Create a repo on GitHub, then:

```bash
git init
git remote add origin https://github.com/yourusername/devops-pipeline-project.git
git add .
git commit -m "initial project structure"
git push -u origin main
```

---

## 2. Python & Flask

```bash
# Check Python version (need 3.11+)
python3 --version

# Create a virtual environment for the project
cd app
python3 -m venv venv
source venv/bin/activate          # Mac/Linux
# venv\Scripts\activate           # Windows

pip install -r requirements.txt

# Run locally (dev mode)
python app.py
# Or via gunicorn (production mode)
gunicorn --bind 0.0.0.0:5000 app:app
```

Test it:
```bash
curl http://localhost:5000/health
# {"status": "healthy"}
```

---

## 3. Docker

### Install (Ubuntu/Debian)
```bash
sudo apt update
sudo apt install -y docker.io docker-compose
sudo usermod -aG docker $USER   # run docker without sudo
newgrp docker                   # apply group change immediately
```

### Install (Mac)
Download Docker Desktop from https://www.docker.com/products/docker-desktop

### Build and run manually
```bash
# From project root
docker build -t devops-demo-app:local -f docker/Dockerfile ./app

# Run the container
docker run -d -p 5000:5000 --name demo-app devops-demo-app:local

# Check it
curl http://localhost:5000/health

# Stop and remove
docker stop demo-app && docker rm demo-app
```

### Docker Compose (for local dev)
```bash
docker-compose -f docker/docker-compose.yml up -d
docker-compose -f docker/docker-compose.yml down
```

### Docker Hub (needed for Jenkins push)
1. Sign up at https://hub.docker.com (free)
2. Create a repository named `devops-demo-app`
3. Note your username — update `DOCKER_IMAGE` in the Jenkinsfile

---

## 4. Jenkins

### Run Jenkins in Docker (easiest setup)
```bash
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts
```

The `-v /var/run/docker.sock` bind mount gives Jenkins access to the host Docker daemon so it can build images without Docker-in-Docker.

### Unlock Jenkins
```bash
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```
Open http://localhost:8080, paste the password, install suggested plugins.

### Extra plugins to install
Go to: Manage Jenkins → Plugins → Available
- Pipeline
- Git
- Docker Pipeline
- Credentials Binding
- GitHub Integration

### Add credentials
Manage Jenkins → Credentials → System → Global → Add Credential

| What            | Kind               | ID                      |
|-----------------|--------------------|-------------------------|
| Docker Hub      | Username/Password  | `dockerhub-credentials` |
| Kubeconfig file | Secret File        | `kubeconfig`            |
| AWS SSH Key     | SSH Username + key | `ec2-ssh-key`           |

### Create the pipeline job
1. New Item → Pipeline → name: `devops-demo`
2. Pipeline → Pipeline script from SCM
3. SCM: Git → your repo URL
4. Script Path: `jenkins/Jenkinsfile`

---

## 5. Ansible

```bash
# Install (Ubuntu)
sudo apt update && sudo apt install -y ansible

# Install (Mac)
brew install ansible

# Verify
ansible --version

# Install community.docker collection (needed for docker_container module)
ansible-galaxy collection install community.docker
```

### Test connectivity before running playbooks
```bash
cd ansible
ansible -i inventory/hosts.ini webservers -m ping
```

### Run the playbook manually
```bash
ansible-playbook -i inventory/hosts.ini playbooks/provision.yml
```

### Useful debug flags
```bash
ansible-playbook ... -v      # verbose
ansible-playbook ... -vvv    # very verbose (shows SSH commands)
ansible-playbook ... --check # dry run, doesn't make changes
ansible-playbook ... --diff  # shows file diffs
```

---

## 6. Terraform

### Install (Ubuntu)
```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

### Install (Mac)
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

### AWS credentials for Terraform
Terraform needs your AWS creds. Don't hardcode them in .tf files.

```bash
# Option 1: Environment variables (recommended for CI)
export AWS_ACCESS_KEY_ID="your-key-id"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"

# Option 2: AWS CLI profile (recommended for local work)
aws configure     # prompts for key, secret, region
```

### Terraform workflow
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

terraform init        # download providers
terraform fmt         # format code
terraform validate    # check syntax
terraform plan        # preview changes
terraform apply       # create resources
terraform output      # show output values
terraform destroy     # delete everything
```

---

## 7. Kubernetes (Minikube for local)

### Install kubectl
```bash
# Ubuntu
curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/

# Mac
brew install kubectl
```

### Install Minikube
```bash
# Ubuntu
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Mac
brew install minikube
```

### Start and use Minikube
```bash
minikube start                  # starts a local single-node cluster

# Point Docker to Minikube's daemon (build images directly into cluster)
eval $(minikube docker-env)

# Deploy the app
kubectl apply -f kubernetes/manifests/

# Check everything
kubectl get pods
kubectl get services
kubectl describe pod <pod-name>
kubectl logs <pod-name>

# Access the app
minikube service devops-demo-app-svc --url

# Stop Minikube when done
minikube stop
```

### Useful kubectl commands
```bash
kubectl get all                          # everything in default namespace
kubectl rollout status deployment/devops-demo-app
kubectl rollout undo deployment/devops-demo-app    # rollback
kubectl scale deployment devops-demo-app --replicas=3
kubectl exec -it <pod-name> -- /bin/bash  # shell into pod
```

---

## 8. AWS Account Setup (Free Tier)

1. Create account at https://aws.amazon.com (credit card required but t2.micro is free)
2. Create an IAM user with programmatic access:
   - IAM → Users → Add user
   - Attach policy: `AmazonEC2FullAccess`, `AmazonVPCFullAccess`
   - Save the Access Key ID and Secret
3. Create a key pair for SSH:
   - EC2 → Key Pairs → Create key pair
   - Name it `devops-demo-key`
   - Download the `.pem` file → save to `~/.ssh/devops-demo-key.pem`
   - `chmod 400 ~/.ssh/devops-demo-key.pem`
4. Install AWS CLI:
   ```bash
   # Ubuntu
   sudo apt install awscli
   # Mac
   brew install awscli

   aws configure    # enter key, secret, region (us-east-1)
   aws sts get-caller-identity   # verify it works
   ```

---

## Full Pipeline Run Order

Once everything is installed:

```
1.  git push origin main
        ↓ GitHub webhook fires
2.  Jenkins: Checkout code
        ↓
3.  Jenkins: pip install + pytest
        ↓
4.  Jenkins: docker build + docker push
        ↓
5.  Jenkins: ansible-playbook provision.yml
        ↓  (SSH into EC2, pull image, run container)
6.  Jenkins: kubectl apply
        ↓  (rolling deploy)
7.  App is live at EC2 public IP
```
