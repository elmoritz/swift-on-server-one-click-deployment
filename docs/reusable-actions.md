---
layout: default
title: Reusable Actions
nav_order: 7
description: "Modular GitHub Actions for better maintainability and code reuse"
permalink: /reusable-actions
---

# Reusable GitHub Actions

The CI/CD pipeline has been modularized into reusable composite actions for better maintainability and code reuse.

## Overview

All reusable actions are located in `.github/actions/` directory. Each action is a composite action that can be used across multiple workflows.

### Benefits

- **DRY Principle**: No code duplication across workflows
- **Easy Maintenance**: Update logic in one place
- **Consistency**: Same behavior across all workflows
- **Testability**: Actions can be tested independently
- **Reusability**: Use the same actions in different workflows

---

## Available Actions

### 1. Version Increment

**Location**: `.github/actions/version-increment/`

**Purpose**: Increment semantic version based on type (build, patch, minor, major)

**Inputs**:
- `version_type` (required): Type of increment - `build`, `patch`, `minor`, `major`
- `github_token` (required): GitHub token for committing changes

**Outputs**:
- `version`: The new version number
- `previous_version`: The previous version number

**Example Usage**:
```yaml
- name: Increment build number
  id: bump
  uses: ./.github/actions/version-increment
  with:
    version_type: 'build'
    github_token: ${{ secrets.GITHUB_TOKEN }}

- name: Use new version
  run: echo "New version is ${{ steps.bump.outputs.version }}"
```

---

### 2. Docker Build and Push

**Location**: `.github/actions/docker-build-push/`

**Purpose**: Build Docker image and push to container registry

**Inputs**:
- `registry` (required): Container registry URL (default: `ghcr.io`)
- `image_name` (required): Docker image name
- `version` (required): Version tag for the image
- `tags` (optional): Additional comma-separated tags
- `push` (optional): Whether to push the image (default: `true`)
- `github_token` (required): GitHub token for registry authentication

**Outputs**:
- `image_tag`: Full image tag that was built
- `digest`: Image digest

**Example Usage**:
```yaml
- name: Build and push Docker image
  uses: ./.github/actions/docker-build-push
  with:
    registry: 'ghcr.io'
    image_name: ${{ github.repository }}
    version: '1.2.3.4'
    tags: 'latest,production'
    push: 'true'
    github_token: ${{ secrets.GITHUB_TOKEN }}
```

---

### 3. Health Check

**Location**: `.github/actions/health-check/`

**Purpose**: Perform health check on application endpoint with retries

**Inputs**:
- `url` (required): Base URL of the application
- `max_retries` (optional): Maximum retry attempts (default: `30`)
- `retry_interval` (optional): Interval between retries in seconds (default: `2`)
- `endpoint` (optional): Health check endpoint path (default: `/health`)

**Outputs**:
- `status`: Health check status (`success`/`failure`)

**Example Usage**:
```yaml
- name: Health check
  uses: ./.github/actions/health-check
  with:
    url: 'https://api.example.com'
    max_retries: '30'
    retry_interval: '3'
```

---

### 4. API Tests

**Location**: `./.github/actions/api-tests/`

**Purpose**: Execute API integration test suite against application

**Inputs**:
- `base_url` (required): Base URL of the application to test
- `test_script` (optional): Path to test script (default: `tests/api/api-tests.sh`)

**Outputs**:
- `result`: Test result (`success`/`failure`)

**Example Usage**:
```yaml
- name: Run API tests
  uses: ./.github/actions/api-tests
  with:
    base_url: 'https://staging.example.com'
```

---

### 5. Deploy to Server

**Location**: `.github/actions/deploy-server/`

**Purpose**: Deploy Docker container to remote server via SSH

**Inputs**:
- `ssh_host` (required): SSH host address
- `ssh_user` (required): SSH username
- `ssh_key` (required): SSH private key
- `ssh_port` (optional): SSH port (default: `22`)
- `registry` (required): Container registry URL
- `image_name` (required): Docker image name
- `version` (required): Version tag to deploy
- `container_name` (required): Name for the container
- `port` (optional): Port mapping host:container (default: `8080:8080`)
- `github_token` (required): GitHub token for registry authentication
- `deploy_path` (optional): Deployment directory (default: `/opt/todos-app`)

**Outputs**:
- `deployed_version`: The version that was deployed

**Example Usage**:
```yaml
- name: Deploy to staging
  uses: ./.github/actions/deploy-server
  with:
    ssh_host: ${{ secrets.STAGING_HOST }}
    ssh_user: ${{ secrets.STAGING_USER }}
    ssh_key: ${{ secrets.STAGING_SSH_KEY }}
    registry: 'ghcr.io'
    image_name: ${{ github.repository }}
    version: '1.2.3.4'
    container_name: 'todos-staging'
    github_token: ${{ secrets.GITHUB_TOKEN }}
```

**What it does**:
1. Logs in to container registry
2. Pulls the specified image version
3. Backs up current container (renames to `*-previous`)
4. Backs up database (keeps last 10 backups)
5. Starts new container
6. Stores deployment metadata
7. Cleans up old images

---

### 6. Rollback Deployment

**Location**: `.github/actions/rollback-deployment/`

**Purpose**: Rollback to previous container version on server

**Inputs**:
- `ssh_host` (required): SSH host address
- `ssh_user` (required): SSH username
- `ssh_key` (required): SSH private key
- `ssh_port` (optional): SSH port (default: `22`)
- `container_name` (required): Name of the container
- `deploy_path` (optional): Deployment directory (default: `/opt/todos-app`)

**Example Usage**:
```yaml
- name: Rollback on failure
  if: failure()
  uses: ./.github/actions/rollback-deployment
  with:
    ssh_host: ${{ secrets.PRODUCTION_HOST }}
    ssh_user: ${{ secrets.PRODUCTION_USER }}
    ssh_key: ${{ secrets.PRODUCTION_SSH_KEY }}
    container_name: 'todos-production'
```

**What it does**:
1. Stops and removes failed container
2. Restores database from latest backup
3. Renames previous container back to original name
4. Starts previous container

---

## Comparison: Before and After

### Before (Monolithic)

**deploy-staging.yml** - 180 lines with duplicated logic

```yaml
- name: Deploy to staging server
  uses: appleboy/ssh-action@v1.2.4
  with:
    host: ${{ secrets.STAGING_HOST }}
    username: ${{ secrets.STAGING_USER }}
    # ... 50+ lines of deployment script
```

### After (Modular)

**deploy-staging.yml** - 100 lines, cleaner

```yaml
- name: Deploy to staging server
  uses: ./.github/actions/deploy-server
  with:
    ssh_host: ${{ secrets.STAGING_HOST }}
    ssh_user: ${{ secrets.STAGING_USER }}
    # ... just configuration
```

---

## Benefits Demonstrated

### Code Reduction

| Workflow | Original | Refactored | Reduction |
|----------|----------|------------|-----------|
| CI | 190 lines | 150 lines | 21% |
| Staging | 180 lines | 100 lines | 44% |
| Production | 367 lines | 200 lines | 45% |
| **Total** | **737 lines** | **450 lines** | **39%** |

### Maintainability

**Updating deployment logic**:
- **Before**: Edit 3 workflow files (staging, production, rollback sections)
- **After**: Edit 1 action file (`.github/actions/deploy-server/action.yml`)

**Adding new environment**:
- **Before**: Copy 150+ lines, modify host/secrets
- **After**: Use existing actions, just change inputs

---

## Best Practices

### 1. Input Validation
Always provide sensible defaults and clear descriptions:
```yaml
inputs:
  max_retries:
    description: 'Maximum number of retry attempts'
    required: false
    default: '30'  # Provide default
```

### 2. Output Everything Important
Make outputs available for downstream steps:
```yaml
outputs:
  version:
    description: 'The new version number'
    value: ${{ steps.bump.outputs.version }}
```

### 3. Clear Error Messages
Provide helpful error messages:
```bash
if [ "${{ inputs.version_type }}" == "invalid" ]; then
  echo "ERROR: Invalid version type: ${{ inputs.version_type }}"
  echo "Valid types: build, patch, minor, major"
  exit 1
fi
```

### 4. Idempotency
Actions should be safe to run multiple times:
```bash
# Remove container if exists
docker rm container-name || true

# Instead of:
docker rm container-name  # Fails if not exists
```

---

## Troubleshooting

### Common Issues

**Problem**: Action not found
```
Error: Unable to resolve action `./.github/actions/my-action`
```

**Solution**:
- Ensure you've checked out the code: `uses: actions/checkout@v4`
- Verify the action path is correct
- Check that `action.yml` exists in the directory

---

**Problem**: Inputs not working
```
Error: Input 'my_input' is required
```

**Solution**:
- Check input names match exactly (case-sensitive)
- Ensure required inputs are provided
- Verify the `with:` block syntax

---

**Problem**: Outputs not available
```
Error: Unable to process file command 'output' successfully
```

**Solution**:
- Use `$GITHUB_OUTPUT` instead of deprecated `set-output`
- Format: `echo "name=value" >> $GITHUB_OUTPUT`

---

## Summary

| Action | Purpose | Lines Saved |
|--------|---------|-------------|
| version-increment | Version management | ~30 per workflow |
| docker-build-push | Docker build/push | ~40 per workflow |
| health-check | Health verification | ~25 per workflow |
| api-tests | API testing | ~15 per workflow |
| deploy-server | Server deployment | ~70 per workflow |
| rollback-deployment | Rollback logic | ~40 per workflow |

**Total**: 6 reusable actions saving ~287 lines of duplicated code across workflows.

---

**Modular actions = Cleaner workflows = Easier maintenance!**
