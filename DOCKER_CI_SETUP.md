# Docker Hub CI/CD Setup Guide

## Prerequisites
1. Docker Hub account
2. GitHub repository with the Dockerfile
3. GitHub repository admin access

## Step 1: Create Docker Hub Access Token

1. **Log in to Docker Hub**
   - Go to [hub.docker.com](https://hub.docker.com)
   - Sign in to your account

2. **Generate Access Token**
   - Click on your username (top right)
   - Select "Account Settings"
   - Go to "Security" tab
   - Click "New Access Token"
   - Give it a name: `GitHub-Actions-CI`
   - Select permissions: `Read, Write, Delete`
   - Click "Generate"
   - **IMPORTANT**: Copy the token immediately (you won't see it again)

## Step 2: Configure GitHub Repository Secrets

1. **Navigate to Repository Settings**
   - Go to your GitHub repository
   - Click "Settings" tab
   - Click "Secrets and variables" → "Actions"

2. **Add Repository Secrets**
   - Click "New repository secret"
   - Add the following secrets:

   | Secret Name | Value | Description |
   |-------------|-------|-------------|
   | `DOCKERHUB_USERNAME` | Your Docker Hub username | Used for login |
   | `DOCKERHUB_TOKEN` | The access token from Step 1 | Used for authentication |

## Step 3: Update Workflow Configuration

### Update Image Name
Edit `.github/workflows/docker-build.yml` and change:
```yaml
env:
  IMAGE_NAME: your-dockerhub-username/erwin-jenkins-agent
```
Replace `your-dockerhub-username` with your actual Docker Hub username.

### Example:
```yaml
env:
  REGISTRY: docker.io
  IMAGE_NAME: udayreddy/erwin-jenkins-agent
```

## Step 4: Create SSH Keys Directory (Optional)

If you want to include SSH keys in your image:

1. **Create SSH directory in repository root:**
   ```bash
   mkdir .ssh
   ```

2. **Add your public key:**
   ```bash
   cp ~/.ssh/id_rsa.pub .ssh/authorized_keys
   ```

3. **Add to .gitignore (for security):**
   ```bash
   echo ".ssh/id_rsa*" >> .gitignore
   ```

## Step 5: Workflow Triggers

The workflow will trigger on:

- **Push to main/master/develop branches** when Dockerfile changes
- **Pull requests** to main/master (build only, no push)
- **Release creation** (tags with version)
- **Manual trigger** via GitHub Actions UI

## Step 6: Multi-Platform Builds

The workflow builds for:
- `linux/amd64` (Intel/AMD processors)
- `linux/arm64` (ARM processors, Apple Silicon)

## Step 7: Testing the Workflow

### Manual Trigger
1. Go to "Actions" tab in your repository
2. Select "Build and Push Docker Image"
3. Click "Run workflow"
4. Choose branch and optionally specify a custom tag
5. Click "Run workflow"

### Automatic Trigger
1. Make a change to the Dockerfile
2. Commit and push to main branch
3. Check "Actions" tab for workflow execution

## Step 8: Using the Built Image

### Pull the Image
```bash
docker pull your-dockerhub-username/erwin-jenkins-agent:latest
```

### Run the Image
```bash
# As SSH agent for Jenkins
docker run -d -p 2222:22 --name jenkins-agent your-dockerhub-username/erwin-jenkins-agent:latest

# Interactive shell for testing
docker run -it --rm your-dockerhub-username/erwin-jenkins-agent:latest /bin/bash
```

### Use in Jenkins Pipeline
```groovy
pipeline {
    agent {
        docker {
            image 'your-dockerhub-username/erwin-jenkins-agent:latest'
            args '-u root:root -v $HOME/.m2:/root/.m2'
        }
    }
    // ... rest of pipeline
}
```

## Step 9: Security Scanning

The workflow includes automatic security scanning with Trivy:
- Scans for vulnerabilities in the built image
- Results appear in GitHub Security tab
- Runs on every successful build

## Step 10: Monitoring and Maintenance

### Check Build Status
- Monitor the "Actions" tab for build status
- Set up notifications for failed builds

### Update Dependencies
The workflow uses build arguments that can be updated:
```yaml
build-args: |
  JDK_VERSION=17
  NODE_VERSION=18
  MAVEN_VERSION=3.9.4
```

### Version Tagging
- Create GitHub releases to automatically tag Docker images
- Use semantic versioning (v1.0.0, v1.1.0, etc.)

## Troubleshooting

### Common Issues:

1. **Authentication Failed**
   - Verify DOCKERHUB_USERNAME and DOCKERHUB_TOKEN secrets
   - Ensure token has write permissions

2. **Build Context Issues**
   - Ensure Dockerfile is in repository root
   - Check .dockerignore for excluded files

3. **SSH Keys Missing**
   - Workflow creates dummy .ssh/authorized_keys if missing
   - Add real keys for SSH access

4. **Platform Build Failures**
   - Some packages may not be available for ARM64
   - Modify Dockerfile to handle platform differences

5. **Java Installation Issues (Ubuntu 24.04)**
   - **Problem**: `E: Unable to locate package temurin-17-jdk`
   - **Cause**: Adoptium repository may not have packages for Ubuntu 24.04 (Noble)
   - **Solutions**:
     
     **Option A**: Use the fixed Dockerfile (changed `jammy` to `noble`)
     ```dockerfile
     echo "deb [signed-by=/usr/share/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb noble main"
     ```
     
     **Option B**: Use OpenJDK instead (more reliable)
     ```dockerfile
     # Replace Temurin installation with:
     RUN apt-get update && \
         apt-get install -y openjdk-${JDK_VERSION}-jdk && \
         rm -rf /var/lib/apt/lists/*
     ```
     
     **Option C**: Use Ubuntu 22.04 base image
     ```dockerfile
     FROM ubuntu:22.04  # Instead of 24.04
     ```

6. **Repository/Package Issues**
   - Check if packages are available for your Ubuntu version
   - Use `apt-cache search` to find available packages
   - Consider using alternative packages or repositories

### Debug Commands:
```bash
# Test locally
docker build -t test-image .

# Check image contents
docker run -it --rm test-image /bin/bash

# View build logs
docker build --progress=plain -t test-image .
```

## Security Best Practices

1. **Use Personal Access Tokens** instead of passwords
2. **Limit token permissions** to minimum required
3. **Regularly rotate tokens** (every 6-12 months)
4. **Monitor security scan results** in GitHub Security tab
5. **Keep base images updated** (Ubuntu 24.04)
6. **Use specific versions** instead of 'latest' for production

## Cost Optimization

1. **Use GitHub Actions efficiently**
   - Avoid unnecessary builds on documentation changes
   - Use conditional triggers

2. **Docker Hub limits**
   - Free accounts have rate limits
   - Consider Docker Hub Pro for higher limits

3. **Image size optimization**
   - Use multi-stage builds if needed
   - Clean up package caches
   - Remove unnecessary files
