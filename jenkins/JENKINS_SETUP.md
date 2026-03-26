# Jenkins Setup Guide

## Run Jenkins Locally (Docker)

```bash
docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts
```

The `-v /var/run/docker.sock` mount lets Jenkins build Docker images using the host daemon.

## First-time Setup

1. Get the initial admin password:
   ```bash
   docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
   ```
2. Open `http://localhost:8080`, paste the password
3. Install suggested plugins + add: **Pipeline**, **Git**, **Docker Pipeline**, **Credentials Binding**

## Required Credentials (Jenkins > Manage Jenkins > Credentials)

| ID                     | Kind               | Value                        |
|------------------------|--------------------|------------------------------|
| `dockerhub-credentials`| Username/Password  | Docker Hub login             |
| `kubeconfig`           | Secret File        | Your `~/.kube/config` file   |

## Create the Pipeline Job

1. New Item → Pipeline → name it `devops-demo-pipeline`
2. Under **Pipeline**, choose **Pipeline script from SCM**
3. SCM: Git, enter your repo URL
4. Script Path: `jenkins/Jenkinsfile`
5. Save

## GitHub Webhook (auto-trigger on push)

In your GitHub repo: Settings → Webhooks → Add webhook
- Payload URL: `http://<your-jenkins-ip>:8080/github-webhook/`
- Content type: `application/json`
- Events: Just the push event
