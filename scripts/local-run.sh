#!/usr/bin/env bash
# scripts/local-run.sh
# Quick commands for local development without memorising docker/kubectl syntax

set -e

ACTION=${1:-help}

case $ACTION in
  build)
    echo ">>> Building Docker image..."
    docker build -t devops-demo-app:local -f docker/Dockerfile ./app
    ;;

  run)
    echo ">>> Starting app via Docker Compose..."
    docker-compose -f docker/docker-compose.yml up -d
    echo "App running at http://localhost:5000"
    ;;

  stop)
    docker-compose -f docker/docker-compose.yml down
    ;;

  test)
    echo ">>> Running tests..."
    cd app
    python3 -m venv venv 2>/dev/null || true
    source venv/bin/activate
    pip install -r requirements.txt -q
    pytest tests/ -v
    deactivate
    cd ..
    ;;

  tf-init)
    echo ">>> Initialising Terraform..."
    cd terraform
    terraform init
    cd ..
    ;;

  tf-plan)
    echo ">>> Terraform plan..."
    cd terraform
    terraform plan
    cd ..
    ;;

  tf-apply)
    echo ">>> Terraform apply..."
    cd terraform
    terraform apply
    cd ..
    ;;

  tf-destroy)
    echo ">>> Destroying all AWS resources..."
    cd terraform
    terraform destroy
    cd ..
    ;;

  k8s-deploy)
    echo ">>> Deploying to local Kubernetes (Minikube)..."
    kubectl apply -f kubernetes/manifests/
    kubectl rollout status deployment/devops-demo-app
    ;;

  k8s-status)
    kubectl get pods,svc,deployments -n default
    ;;

  k8s-logs)
    kubectl logs -l app=devops-demo-app --tail=50
    ;;

  help|*)
    echo "Usage: ./scripts/local-run.sh [command]"
    echo ""
    echo "Commands:"
    echo "  build        Build Docker image locally"
    echo "  run          Start with Docker Compose"
    echo "  stop         Stop Docker Compose"
    echo "  test         Run pytest"
    echo "  tf-init      Terraform init"
    echo "  tf-plan      Terraform plan"
    echo "  tf-apply     Terraform apply (creates AWS resources)"
    echo "  tf-destroy   Destroy AWS resources"
    echo "  k8s-deploy   Apply all k8s manifests"
    echo "  k8s-status   Show pods/services"
    echo "  k8s-logs     Tail app logs"
    ;;
esac
