---
layout: default
title: Deployment Guide
nav_order: 8
description: "Comprehensive guide for deploying the application using the CI/CD pipeline"
permalink: /deployment-guide
---

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

- **Smart Triggers** - Deployments only run when source code or configuration changes
- **Automated Testing** - Unit tests, integration tests, API tests
- **Code Quality Checks** - SwiftLint enforces coding standards
- **Security Scanning** - Trivy vulnerability detection
- **Docker Image Building** - Multi-stage builds with layer caching
- **Release Management** - Automatic versioning, tagging, and GitHub Releases
- **Release Branches** - Persistent branches for each deployment
- **Staged Deployment** - Staging validation before production
- **Health Monitoring** - Continuous health checks during and after deployment
- **Automated Rollback** - Instant rollback on failure

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

## Smart Deployment Triggers

To optimize resource usage and reduce unnecessary deployments, the pipeline uses path-based triggers that only run when relevant files change.

### What Triggers Deployments

Deployments are triggered when changes are pushed to files in these directories:

- **Source Code**: `todos-fluent/**` (Swift code, tests, Package.swift)
- **Docker Config**: `Dockerfile`, `docker-compose.yml`
- **Deployment Scripts**: `scripts/**`
- **Linting Rules**: `.swiftlint.yml`
- **Pipeline Config**: `.github/workflows/**`, `.github/actions/**`

### What Does NOT Trigger Deployments

Changes to documentation and other non-code files will NOT trigger deployments:

- `docs/**` - Documentation files
- `*.md` - Markdown files (README, guides, etc.)
- `LICENSE`, `.gitignore`, etc.

**Example Scenarios:**

```bash
# ✅ WILL trigger deployment
git add todos-fluent/Sources/App/routes.swift
git commit -m "Add new API endpoint"
git push origin main

# ✅ WILL trigger deployment
git add Dockerfile
git commit -m "Update Swift version"
git push origin main

# ❌ Will NOT trigger deployment
git add README.md
git commit -m "Update documentation"
git push origin main

# ❌ Will NOT trigger deployment
git add docs/deployment-guide.md
git commit -m "Improve deployment guide"
git push origin main
```

This ensures that documentation updates, README changes, and other non-code modifications don't unnecessarily consume CI/CD resources or trigger production deployments.

---

## Deployment Workflows

### Automatic Staging Deployment

Staging deployment happens automatically when source code changes are pushed to the `main` branch.

**Triggers:**

The deployment only runs when changes are made to:
- Swift source code (`todos-fluent/**`)
- Docker configuration (`Dockerfile`, `docker-compose.yml`)
- Deployment scripts (`scripts/**`)
- Linting configuration (`.swiftlint.yml`)
- Workflow or action files (`.github/**`)

Documentation-only changes (`.md` files) will NOT trigger a deployment.

**Process:**

1. Push source code changes to `main` branch
2. CI pipeline runs (tests, build, security scan)
3. If CI passes, staging deployment begins:
   - Version number is read
   - Docker image is built and pushed to GHCR with `staging` tag
   - Image is deployed to staging server
4. Health checks and API tests run
5. 5-minute monitoring period

**Monitoring:**

```bash
# Watch the deployment in GitHub Actions
# Repository > Actions > Deploy to Staging
```

### Manual Production Deployment

Production deployment requires manual triggering via GitHub Actions.

**Process:**

1. Go to GitHub Actions > Deploy to Production > Run workflow
2. Select the version increment type:
   - **major** - Breaking changes (X.0.0)
   - **minor** - New features (0.X.0)
   - **patch** - Bug fixes (0.0.X)
3. Optionally add release notes
4. Approve the deployment (if reviewers are configured)
5. Deployment proceeds with:
   - Version number is automatically incremented
   - Version is committed to main branch
   - Release branch `release/vX.Y.Z` is created
   - Git tag `vX.Y.Z` is created and pushed
   - Pre-deployment validation checks on staging
   - Docker image build and push with production tags
   - GitHub Release is created with release notes
   - Production server deployment
   - Health checks and smoke tests
   - 15-minute monitoring period

**GitHub Release:**

Each production deployment automatically creates a GitHub Release with:
- Auto-generated changelog based on commits
- Version information and deployment details
- Custom release notes (if provided)
- Links to Docker images

**Example Workflow:**

```bash
# No manual git commands needed!
# Simply trigger via GitHub UI:
# Actions > Deploy to Production > Run workflow
# Select: patch (or minor/major)
# Optional: Add release notes
# Click "Run workflow"
```

**Release Branches:**

Every successful production deployment creates a permanent release branch:
- Format: `release/vX.Y.Z`
- Created only after successful deployment
- Serves as a snapshot of deployed code

These branches can be used for:
- Emergency hotfixes
- Rollback reference
- Audit trail of production releases

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
- Check Swift version compatibility in Dockerfile
- Verify all dependencies in Package.swift
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
