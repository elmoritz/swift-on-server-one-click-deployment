# CI/CD Pipeline Setup Checklist

Use this checklist to set up your complete CI/CD pipeline for the Hummingbird Todos application.

## Prerequisites Checklist

- [ ] GitHub account created
- [ ] Two servers available (staging and production)
- [ ] SSH access to both servers configured
- [ ] Docker installed on both servers
- [ ] Port 8080 available on both servers

---

## Step 1: GitHub Repository Setup

- [ ] Create a new GitHub repository
- [ ] Clone this repository locally
- [ ] Add GitHub remote:
  ```bash
  git remote add origin https://github.com/YOUR_USERNAME/HummingbirdPlublication.git
  ```
- [ ] Push code to GitHub:
  ```bash
  git add .
  git commit -m "Initial commit with CI/CD pipeline"
  git push -u origin main
  ```

---

## Step 2: Server Preparation

### Staging Server

- [ ] SSH into staging server
- [ ] Install Docker:
  ```bash
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
  sudo usermod -aG docker $USER
  ```
- [ ] Create deployment directories:
  ```bash
  sudo mkdir -p /opt/todos-app/data
  sudo mkdir -p /opt/todos-app/backups
  sudo chown -R $USER:$USER /opt/todos-app
  ```
- [ ] Test SSH connection from local machine
- [ ] Note down: Server IP, SSH username, SSH port (if not 22)

### Production Server

- [ ] SSH into production server
- [ ] Install Docker (same as staging)
- [ ] Create deployment directories (same as staging)
- [ ] Test SSH connection from local machine
- [ ] Note down: Server IP, SSH username, SSH port (if not 22)

---

## Step 3: SSH Key Generation

- [ ] Generate SSH key pair for deployments (if you don't have one):
  ```bash
  ssh-keygen -t ed25519 -C "deployment-key" -f ~/.ssh/deployment_key
  ```
- [ ] Add public key to both servers:
  ```bash
  # Copy public key
  cat ~/.ssh/deployment_key.pub

  # On each server, add to authorized_keys
  echo "PUBLIC_KEY_CONTENT" >> ~/.ssh/authorized_keys
  chmod 600 ~/.ssh/authorized_keys
  ```
- [ ] Test SSH access with the key:
  ```bash
  ssh -i ~/.ssh/deployment_key user@staging-server
  ssh -i ~/.ssh/deployment_key user@production-server
  ```

---

## Step 4: GitHub Secrets Configuration

Go to your repository: Settings > Secrets and variables > Actions > New repository secret

### Add these secrets:

#### Staging Secrets
- [ ] `STAGING_HOST` - Staging server IP or hostname
- [ ] `STAGING_USER` - SSH username for staging
- [ ] `STAGING_SSH_KEY` - Private SSH key content (paste contents of ~/.ssh/deployment_key)
- [ ] `STAGING_PORT` - SSH port (only if not 22)

#### Production Secrets
- [ ] `PRODUCTION_HOST` - Production server IP or hostname
- [ ] `PRODUCTION_USER` - SSH username for production
- [ ] `PRODUCTION_SSH_KEY` - Private SSH key content (paste contents of ~/.ssh/deployment_key)
- [ ] `PRODUCTION_PORT` - SSH port (only if not 22)

**Note:** The `GITHUB_TOKEN` secret is automatically provided by GitHub Actions.

---

## Step 5: GitHub Variables Configuration

Go to your repository: Settings > Secrets and variables > Actions > Variables tab > New repository variable

- [ ] `STAGING_URL` - Full URL to staging (e.g., `http://staging.example.com:8080`)
- [ ] `PRODUCTION_URL` - Full URL to production (e.g., `https://api.example.com`)

---

## Step 6: GitHub Environments Setup

Go to your repository: Settings > Environments

### Create Staging Environment
- [ ] Click "New environment"
- [ ] Name: `staging`
- [ ] Add environment URL: (same as STAGING_URL variable)
- [ ] Save

### Create Production Environment
- [ ] Click "New environment"
- [ ] Name: `production`
- [ ] Add environment URL: (same as PRODUCTION_URL variable)
- [ ] **Recommended:** Enable "Required reviewers" and add yourself
- [ ] **Recommended:** Set deployment branches to "Selected branches" and choose `main` only
- [ ] Save

---

## Step 7: Enable GitHub Actions

- [ ] Go to repository Settings > Actions > General
- [ ] Under "Actions permissions", select "Allow all actions and reusable workflows"
- [ ] Under "Workflow permissions", select "Read and write permissions"
- [ ] Enable "Allow GitHub Actions to create and approve pull requests"
- [ ] Save

---

## Step 8: Enable GitHub Container Registry

- [ ] Go to your GitHub profile > Settings > Developer settings > Personal access tokens > Tokens (classic)
- [ ] Generate new token (classic) with scopes: `write:packages`, `read:packages`, `delete:packages`
- [ ] Save the token (you won't need to add it as a secret - GitHub Actions uses GITHUB_TOKEN)

Or verify package permissions in your repository:
- [ ] Settings > Actions > General > Workflow permissions
- [ ] Ensure "Read and write permissions" is selected

---

## Step 9: Test Local Build

Before pushing, test everything works locally:

- [ ] Test Docker build:
  ```bash
  docker build -t hummingbird-todos:test .
  ```
- [ ] Test with Docker Compose:
  ```bash
  docker-compose up --build
  ```
- [ ] Run unit tests:
  ```bash
  cd todos-fluent && swift test
  ```
- [ ] Run API tests:
  ```bash
  ./tests/api/api-tests.sh
  ```
- [ ] Run health check:
  ```bash
  ./scripts/health-check.sh http://localhost:8080
  ```
- [ ] Clean up:
  ```bash
  docker-compose down
  ```

---

## Step 10: Initial Deployment

### Push to GitHub
- [ ] Commit any remaining changes:
  ```bash
  git add .
  git commit -m "Ready for deployment"
  git push origin main
  ```

### Watch CI Pipeline
- [ ] Go to GitHub repository > Actions tab
- [ ] Watch the "CI - Test and Build" workflow
- [ ] Ensure all jobs pass (lint, test, build-docker, integration-test, security-scan)

### Monitor Staging Deployment
- [ ] After CI passes, "Deploy to Staging" workflow should start automatically
- [ ] Monitor the deployment progress
- [ ] Check that all steps complete successfully
- [ ] Verify staging URL is accessible: `curl http://STAGING_URL/health`

### First Production Deployment
- [ ] Create a version tag:
  ```bash
  git tag -a v1.0.0 -m "First production release"
  git push origin v1.0.0
  ```
- [ ] Go to Actions > Deploy to Production > Run workflow
- [ ] Enter version: `v1.0.0`
- [ ] Approve the deployment (if required reviewers are set)
- [ ] Monitor deployment progress
- [ ] Verify production URL: `curl http://PRODUCTION_URL/health`

---

## Step 11: Post-Deployment Verification

### Staging
- [ ] Access staging health endpoint: `http://STAGING_URL/health`
- [ ] Test API endpoints:
  ```bash
  # List todos
  curl http://STAGING_URL/api/todos

  # Create a todo
  curl -X POST http://STAGING_URL/api/todos \
    -H "Content-Type: application/json" \
    -d '{"title": "Test", "completed": false}'
  ```
- [ ] Check server logs:
  ```bash
  ssh user@staging-server
  docker logs todos-staging
  ```

### Production
- [ ] Access production health endpoint: `http://PRODUCTION_URL/health`
- [ ] Test API endpoints (same as staging)
- [ ] Check server logs:
  ```bash
  ssh user@production-server
  docker logs todos-production
  ```

---

## Step 12: Optional Enhancements

- [ ] Set up custom domain names for staging and production
- [ ] Configure SSL/TLS certificates (Let's Encrypt)
- [ ] Set up reverse proxy (nginx) for HTTPS
- [ ] Configure monitoring (Prometheus + Grafana)
- [ ] Set up log aggregation (ELK stack or Loki)
- [ ] Configure alerting (PagerDuty, Slack, email)
- [ ] Set up uptime monitoring (UptimeRobot, Pingdom)
- [ ] Enable automatic security updates on servers
- [ ] Configure database backups to external storage
- [ ] Set up disaster recovery procedures

---

## Troubleshooting Guide

### Issue: CI pipeline fails on SwiftLint
**Solution:** Install SwiftLint locally and fix issues:
```bash
brew install swiftlint
swiftlint lint --fix
```

### Issue: Docker build fails
**Solution:**
- Check Swift version in Dockerfile matches Package.swift
- Verify all dependencies are available
- Check GitHub Actions logs for specific errors

### Issue: SSH connection fails during deployment
**Solution:**
- Verify SSH key is correct in GitHub Secrets
- Test SSH connection manually: `ssh -i key user@host`
- Check server firewall settings
- Ensure key has no passphrase or use ssh-agent

### Issue: Health checks fail
**Solution:**
- SSH into server and check: `docker logs todos-staging`
- Verify port 8080 is not blocked
- Check if container is running: `docker ps`
- Manually test health endpoint: `curl localhost:8080/health`

### Issue: Database migration errors
**Solution:**
- Run migrations manually: `docker exec todos-staging /app/todos-server --migrate`
- Check migration logs
- Restore from backup if needed

---

## Quick Reference Commands

### Local Development
```bash
# Run locally
cd todos-fluent && swift run

# Run tests
swift test

# Docker Compose
docker-compose up -d
```

### Deployment
```bash
# Create release tag
git tag -a v1.0.0 -m "Release message"
git push origin v1.0.0

# Manual deployment (on server)
./scripts/deploy.sh production v1.0.0

# Manual rollback (on server)
./scripts/rollback.sh production
```

### Server Management
```bash
# View logs
docker logs todos-production -f

# Check health
curl http://localhost:8080/health

# Restart container
docker restart todos-production

# View current version
cat /opt/todos-app/current-version.txt
```

---

## Success Criteria

Your pipeline is successfully set up when:

- [x] All GitHub Actions workflows are green
- [x] Staging deploys automatically on push to main
- [x] Production deploys manually with approval
- [x] Health checks pass on both environments
- [x] API tests pass on both environments
- [x] Rollback works correctly
- [x] Database backups are created

---

## Next Steps After Setup

1. **Monitor first few deployments** closely
2. **Document any environment-specific configurations**
3. **Set up monitoring and alerting**
4. **Plan regular maintenance windows**
5. **Train team on deployment procedures**
6. **Create runbook for common issues**

---

## Support Resources

- [DEPLOYMENT.md](DEPLOYMENT.md) - Detailed deployment guide
- [README.md](README.md) - Project overview and API documentation
- GitHub Actions logs - Detailed pipeline execution logs
- Server logs - `docker logs todos-[staging|production]`

---

**Congratulations!** You now have a production-ready CI/CD pipeline! 🎉
