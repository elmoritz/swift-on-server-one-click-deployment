# Deployment Guide - Hummingbird Todos Application

This document provides comprehensive instructions for deploying the Hummingbird Todos application using the CI/CD pipeline.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Initial Setup](#initial-setup)
4. [Pipeline Architecture](#pipeline-architecture)
5. [Deployment Workflows](#deployment-workflows)
6. [Local Testing](#local-testing)
7. [Rollback Procedures](#rollback-procedures)
8. [Troubleshooting](#troubleshooting)

---

## Overview

The CI/CD pipeline automates the entire deployment process from code commit to production deployment, including:

- Automated testing (unit tests, integration tests, API tests)
- Code quality checks (SwiftLint)
- Security scanning (Trivy)
- Docker image building and publishing
- Automated deployment to staging and production
- Health checks and monitoring
- Automated rollback on failure

---

## Prerequisites

### Required Tools

- Git
- Docker and Docker Compose
- GitHub account with access to GitHub Container Registry
- Two servers (staging and production) with:
  - Docker installed
  - SSH access configured
  - Port 8080 available

### GitHub Repository Setup

1. Create a new repository on GitHub
2. Push your code to the repository

```bash
git remote add origin https://github.com/YOUR_USERNAME/HummingbirdPlublication.git
git add .
git commit -m "Initial commit with CI/CD pipeline"
git push -u origin main
```

---

## Initial Setup

### 1. Configure GitHub Secrets

Navigate to your GitHub repository settings and add the following secrets:

#### Staging Environment Secrets

- `STAGING_HOST` - Staging server IP or hostname
- `STAGING_USER` - SSH username for staging server
- `STAGING_SSH_KEY` - Private SSH key for staging server authentication
- `STAGING_PORT` - SSH port (default: 22, optional)

#### Production Environment Secrets

- `PRODUCTION_HOST` - Production server IP or hostname
- `PRODUCTION_USER` - SSH username for production server
- `PRODUCTION_SSH_KEY` - Private SSH key for production server authentication
- `PRODUCTION_PORT` - SSH port (default: 22, optional)

### 2. Configure GitHub Variables

Add these variables in your repository settings under Variables:

- `STAGING_URL` - Full URL to staging server (e.g., `http://staging.example.com:8080`)
- `PRODUCTION_URL` - Full URL to production server (e.g., `https://api.example.com`)

### 3. Set Up GitHub Environments

Create two environments in your repository settings:

1. **staging** - Configure with staging URL
2. **production** - Configure with:
   - Production URL
   - Required reviewers (recommended)
   - Deployment branch restriction to `main` only

### 4. Enable GitHub Container Registry

The pipeline automatically publishes Docker images to GitHub Container Registry (GHCR). Ensure your repository has the necessary permissions:

1. Go to your repository Settings > Actions > General
2. Under "Workflow permissions", select "Read and write permissions"
3. Enable "Allow GitHub Actions to create and approve pull requests"

### 5. Prepare Servers

On both staging and production servers, run:

```bash
# Create deployment directory
sudo mkdir -p /opt/todos-app/data
sudo mkdir -p /opt/todos-app/backups

# Set ownership (replace 'username' with your SSH user)
sudo chown -R username:username /opt/todos-app

# Install Docker if not already installed
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER
```

Log out and back in for group changes to take effect.

---

## Pipeline Architecture

### Workflow Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Push to main/develop                    │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    CI Pipeline (ci.yml)                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────────┐  ┌────────┐ │
│  │ SwiftLint│  │Unit Tests│  │Build & Push  │  │Security│ │
│  │          │→ │          │→ │Docker Image  │  │ Scan   │ │
│  └──────────┘  └──────────┘  └──────────────┘  └────────┘ │
│                                      │                      │
│                                      ▼                      │
│                        ┌──────────────────────┐            │
│                        │Integration API Tests │            │
│                        └──────────────────────┘            │
└─────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────┐
│            Staging Deployment (deploy-staging.yml)          │
│  ┌────────────────┐  ┌──────────┐  ┌────────────────────┐  │
│  │Deploy to Server│→ │Health    │→ │Run API Tests on   │  │
│  │                │  │Check     │  │Staging            │  │
│  └────────────────┘  └──────────┘  └────────────────────┘  │
│                                      │                      │
│                                      ▼                      │
│                        ┌──────────────────────┐            │
│                        │5-min Monitoring      │            │
│                        └──────────────────────┘            │
└─────────────────────────────────────────────────────────────┘
                                      │
                            Manual Approval Required
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────┐
│         Production Deployment (deploy-production.yml)       │
│  ┌────────────────┐  ┌──────────┐  ┌────────────────────┐  │
│  │Pre-checks      │→ │Deploy to │→ │Health Check +     │  │
│  │                │  │Production│  │Smoke Tests        │  │
│  └────────────────┘  └──────────┘  └────────────────────┘  │
│                                      │                      │
│                                      ▼                      │
│                        ┌──────────────────────┐            │
│                        │15-min Monitoring     │            │
│                        └──────────────────────┘            │
└─────────────────────────────────────────────────────────────┘
```

### Key Features

1. **Automated Testing**: Every commit triggers unit tests, integration tests, and API tests
2. **Quality Gates**: SwiftLint enforces code quality standards
3. **Security Scanning**: Trivy scans for vulnerabilities
4. **Staged Deployment**: Changes flow through staging before production
5. **Automated Rollback**: Failed deployments automatically rollback
6. **Health Monitoring**: Continuous health checks during and after deployment

---

## Deployment Workflows

### Automatic Staging Deployment

Staging deployment happens automatically when code is pushed to the `main` branch.

**Process:**

1. Push to `main` branch
2. CI pipeline runs (tests, build, security scan)
3. If CI passes, staging deployment begins
4. Docker image is built and pushed to GHCR
5. Image is deployed to staging server
6. Health checks and API tests run
7. 5-minute monitoring period

**Monitoring:**

```bash
# Watch the deployment in GitHub Actions
# Repository > Actions > Deploy to Staging
```

### Manual Production Deployment

Production deployment requires manual triggering with a version tag.

**Process:**

1. Create a git tag for the release:

```bash
git tag v1.0.0
git push origin v1.0.0
```

2. Go to GitHub Actions > Deploy to Production > Run workflow
3. Enter the version tag (e.g., `v1.0.0`)
4. Approve the deployment (if reviewers are configured)
5. Deployment proceeds with:
   - Pre-deployment validation checks
   - Docker image build and push
   - Production server deployment
   - Health checks and smoke tests
   - 15-minute monitoring period

**Example:**

```bash
# Tag a release
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0

# Then trigger via GitHub UI:
# Actions > Deploy to Production > Run workflow
# Input: v1.0.0
```

---

## Local Testing

### Test Locally with Docker Compose

Before pushing to production, test locally:

```bash
# Build and start the application
docker-compose up --build

# In another terminal, run health check
./scripts/health-check.sh http://localhost:8080

# Run API tests
./tests/api/api-tests.sh
```

### Run Unit Tests Locally

```bash
cd todos-fluent
swift test
```

### Run Linting Locally

```bash
# Install SwiftLint (macOS)
brew install swiftlint

# Run linting
swiftlint lint
```

### Manual Deployment Scripts

You can also deploy manually to your servers using the provided scripts:

```bash
# SSH into your server, then:
./scripts/deploy.sh staging v1.0.0
./scripts/deploy.sh production v1.0.0
```

---

## Rollback Procedures

### Automatic Rollback

The pipeline automatically rolls back if:

- Health checks fail after deployment
- API tests fail on the new version
- Container fails to start

### Manual Rollback

If you need to manually rollback:

**Via GitHub Actions:**

The rollback happens automatically in the deployment workflow if failures are detected.

**Via Server Script:**

SSH into the affected server and run:

```bash
cd /opt/todos-app
./scripts/rollback.sh staging    # or production
```

**Manual Docker Rollback:**

```bash
# Stop current container
docker stop todos-production
docker rm todos-production

# Rename previous container back
docker rename todos-production-previous todos-production
docker start todos-production

# Restore database backup
cp /opt/todos-app/backups/db.sqlite.backup.YYYYMMDD-HHMMSS \
   /opt/todos-app/data/db.sqlite
```

---

## Troubleshooting

### Common Issues

#### 1. Docker Image Build Fails

**Symptom:** CI pipeline fails during Docker build

**Solutions:**
- Check Swift version compatibility in [Dockerfile](Dockerfile)
- Verify all dependencies in [Package.swift](todos-fluent/Package.swift)
- Check Docker build logs in GitHub Actions

#### 2. Health Checks Fail

**Symptom:** Deployment fails with health check timeout

**Solutions:**
- Verify the `/health` endpoint is working
- Check container logs: `docker logs todos-staging`
- Increase health check timeout in workflows
- Verify port 8080 is accessible

#### 3. SSH Connection Issues

**Symptom:** Deployment fails to connect to server

**Solutions:**
- Verify SSH key is correct in GitHub Secrets
- Check server firewall allows SSH (port 22)
- Test SSH connection manually: `ssh -i key.pem user@host`
- Ensure SSH key has proper permissions (600)

#### 4. API Tests Fail

**Symptom:** Integration tests fail in pipeline

**Solutions:**
- Run tests locally: `./tests/api/api-tests.sh`
- Check if database migrations are applied
- Verify test data expectations
- Review application logs

#### 5. Database Migration Issues

**Symptom:** Application starts but database queries fail

**Solutions:**
- Run migrations manually:
  ```bash
  docker exec todos-production /app/todos-server --migrate
  ```
- Check migration logs
- Restore from backup if needed

### Viewing Logs

**Container Logs:**
```bash
# On server
docker logs todos-staging -f
docker logs todos-production -f
```

**GitHub Actions Logs:**
- Navigate to Actions tab in your repository
- Click on the workflow run
- View detailed logs for each step

### Emergency Contacts

In case of critical production issues:

1. Check monitoring dashboards (if configured)
2. Review GitHub Actions logs
3. SSH into production server and check logs
4. Execute manual rollback if necessary
5. Contact the development team

---

## Performance Optimization

### Database Backups

Backups are created automatically before each deployment and stored in `/opt/todos-app/backups/`.

**Retention:** Last 10 backups are kept automatically.

**Manual Backup:**
```bash
cp /opt/todos-app/data/db.sqlite \
   /opt/todos-app/backups/db.sqlite.backup.$(date +%Y%m%d-%H%M%S)
```

### Monitoring Recommendations

Consider adding:

- **Application Monitoring**: Prometheus + Grafana
- **Log Aggregation**: ELK Stack or Loki
- **Alerting**: PagerDuty, Opsgenie, or similar
- **Uptime Monitoring**: UptimeRobot, Pingdom

### Resource Limits

For production, consider setting Docker resource limits:

```bash
docker run -d \
  --name todos-production \
  --memory="512m" \
  --cpus="1.0" \
  ...
```

---

## Security Best Practices

1. **Secrets Management**: Never commit secrets to git
2. **SSH Keys**: Use dedicated deployment keys with minimal permissions
3. **Container Registry**: Keep images private or use image scanning
4. **Database**: Regular backups and encryption at rest
5. **HTTPS**: Use reverse proxy (nginx) with SSL certificates
6. **Firewall**: Restrict access to necessary ports only

---

## Next Steps

After successful deployment:

1. Configure monitoring and alerting
2. Set up SSL certificates for production
3. Implement database backup automation
4. Configure log aggregation
5. Set up custom domain names
6. Plan disaster recovery procedures

---

## Support

For issues or questions:

- Check GitHub Actions logs
- Review this documentation
- Check application logs on servers
- Contact the development team

---

**Version:** 1.0.0
**Last Updated:** 2025-10-31
