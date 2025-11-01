---
layout: default
title: Troubleshooting
nav_order: 6
description: "Common issues and solutions"
permalink: /troubleshooting
---

# Troubleshooting Guide

This guide covers common issues you might encounter and how to resolve them. Issues are organized by category for easy navigation.

---

## Table of Contents

- [GitHub Actions / CI Issues](#github-actions--ci-issues)
- [Docker Build Issues](#docker-build-issues)
- [Deployment Issues](#deployment-issues)
- [Health Check Failures](#health-check-failures)
- [Version Management Issues](#version-management-issues)
- [SSH and Connectivity Issues](#ssh-and-connectivity-issues)
- [Database Issues](#database-issues)
- [Application Runtime Issues](#application-runtime-issues)
- [Rollback Issues](#rollback-issues)
- [General Debugging Tips](#general-debugging-tips)

---

## GitHub Actions / CI Issues

### Issue: "SwiftLint job failed"

**Symptoms:**
```
Error: SwiftLint found 3 violations with severity 'error'
todos-fluent/Sources/App/Controllers/TodoController.swift:45: error: Line Length
```

**Cause:** Code doesn't meet SwiftLint style guidelines

**Solution:**

```bash
# 1. Install SwiftLint locally (macOS)
brew install swiftlint

# 2. Run SwiftLint to see all issues
cd todos-fluent
swiftlint

# 3. Auto-fix what's possible
swiftlint --fix

# 4. Manually fix remaining issues

# 5. Verify
swiftlint
```

**Alternative:** Disable specific rules in [.swiftlint.yml](.swiftlint.yml) if you disagree with them:

```yaml
disabled_rules:
  - line_length  # If you want longer lines
```

---

### Issue: "Unit tests failing in CI but pass locally"

**Symptoms:**
```
❌ Test failed: testTodoCreation
Expected: 201, Got: 500
```

**Causes:**
1. **Environment differences** (different Swift version)
2. **Missing environment variables**
3. **File path issues**
4. **Timing/race conditions**

**Solution:**

```bash
# 1. Check Swift version in CI (from ci.yml)
grep SWIFT_VERSION .github/workflows/ci.yml
# Output: SWIFT_VERSION: '5.9'

# 2. Use the same version locally
swift --version

# 3. If different, install matching version
# (for macOS with Xcode)
# Download from https://swift.org/download/

# 4. Run tests in same way CI does
cd todos-fluent
swift test --enable-code-coverage

# 5. Check for environment-specific code
# Look for: ProcessInfo.processInfo.environment["..."]
```

---

### Issue: "Docker build fails in CI with 'No space left on device'"

**Symptoms:**
```
Error: failed to copy: write /var/lib/docker/...: no space left on device
```

**Cause:** GitHub Actions runner disk is full (10GB limit)

**Solution:**

Add cleanup step before building:

```yaml
# In your workflow, before docker build
- name: Free disk space
  run: |
    docker system prune -af
    docker volume prune -f
    sudo rm -rf /usr/share/dotnet
    sudo rm -rf /opt/ghc
```

**Or:** Use registry caching more aggressively (we already do this)

---

### Issue: "Workflow not triggering"

**Symptoms:** Push code, but no workflow runs

**Possible Causes:**

**1. Branch filter doesn't match**
```yaml
# Workflow says:
on:
  push:
    branches: [main, develop]

# But you pushed to: feature/add-endpoint
```

**Solution:** Either push to `main`/`develop`, or add your branch to the filter

**2. [skip ci] in commit message**
```bash
git commit -m "chore: update docs [skip ci]"
```

**Solution:** Remove `[skip ci]` if you want CI to run

**3. Workflow file has syntax errors**

**Solution:**
```bash
# Validate YAML syntax
cat .github/workflows/ci.yml | python3 -c 'import sys, yaml; yaml.safe_load(sys.stdin)'
```

---

### Issue: "Workflow permission denied errors"

**Symptoms:**
```
Error: Resource not accessible by integration
```

**Cause:** GitHub token doesn't have required permissions

**Solution:**

Add to workflow file:

```yaml
permissions:
  contents: write        # For pushing commits/tags
  packages: write        # For pushing Docker images
  security-events: write # For uploading security scan results
```

---

## Docker Build Issues

### Issue: "Docker build extremely slow (5-10 minutes every time)"

**Symptoms:** Every build takes 5+ minutes even for small code changes

**Cause:** Docker cache not working

**Diagnosis:**

```bash
# Check if cache is being used
# Look in workflow logs for:
"cache-from: type=registry,ref=..."

# Should see:
#cached [builder 3/8] COPY Package.* ./
```

**Solutions:**

**1. Verify Package.resolved exists and is committed**
```bash
git status todos-fluent/Package.resolved
# Should NOT say "Untracked" or "Deleted"

# If missing:
cd todos-fluent
swift package resolve
git add Package.resolved
git commit -m "Add Package.resolved for caching"
```

**2. Check registry permissions**
```yaml
# Ensure you're logged into the registry
- name: Log in to GitHub Container Registry
  uses: docker/login-action@v3
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}
```

**3. Verify cache images exist**
```bash
# Check if cache images are in registry
docker manifest inspect ghcr.io/YOUR_USERNAME/repo:builder-cache-latest
```

---

### Issue: "Multi-stage Docker build fails at dependencies stage"

**Symptoms:**
```
Error: Package.swift:5: error: no such module 'Hummingbird'
```

**Cause:** Package dependencies not resolved correctly

**Solution:**

**1. Check Package.swift syntax**
```bash
cd todos-fluent
swift package describe
```

**2. Update dependencies**
```bash
swift package update
swift package resolve
```

**3. Verify Dockerfile copies Package.* correctly**
```dockerfile
# Should be:
COPY todos-fluent/Package.* ./

# NOT:
COPY Package.* ./  # Wrong path!
```

**4. Check Swift version in Dockerfile matches Package.swift**
```dockerfile
# Dockerfile
FROM swift:5.9 as dependencies

# Package.swift
// swift-tools-version:5.9
```

---

### Issue: "Docker build fails with 'could not read username'"

**Symptoms:**
```
Error response from daemon: Get "https://ghcr.io/v2/": could not read Username
```

**Cause:** Not logged into container registry

**Solution:**

```yaml
# Add BEFORE docker build step
- name: Log in to GitHub Container Registry
  uses: docker/login-action@v3
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}
```

---

## Deployment Issues

### Issue: "Deployment fails with 'Permission denied (publickey)'"

**Symptoms:**
```
Permission denied (publickey).
fatal: Could not read from remote repository.
```

**Cause:** SSH key not configured or incorrect

**Solution:**

**1. Verify SSH key is added to GitHub secrets**
- Go to repository Settings → Secrets → Actions
- Check that `STAGING_SSH_KEY` or `PRODUCTION_SSH_KEY` exists

**2. Test SSH connection manually**
```bash
# Add your key
ssh-add ~/.ssh/your_key

# Test connection
ssh user@your-server-ip

# Should connect without password
```

**3. Ensure secret contains the PRIVATE key**
```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAA...
-----END OPENSSH PRIVATE KEY-----
```

**NOT** the public key (*.pub)

**4. Check key format**
```bash
# If you have an RSA key in old format, convert it
ssh-keygen -p -f ~/.ssh/id_rsa -m PEM
```

**5. Verify server has the PUBLIC key**
```bash
# On the server
cat ~/.ssh/authorized_keys
# Should contain the public key corresponding to your private key
```

---

### Issue: "Deployment hangs at 'Waiting for container to start'"

**Symptoms:** Deployment step runs for 10+ minutes and times out

**Cause:** Container not starting or health check failing

**Diagnosis:**

```bash
# SSH to server
ssh user@your-server

# Check container status
docker ps -a

# Check container logs
docker logs todos-staging  # or todos-production

# Common issues in logs:
# - Port already in use
# - Database file not accessible
# - Environment variable missing
# - Application crash on startup
```

**Solutions:**

**For "port already in use":**
```bash
# Find process using port 8080
lsof -i :8080

# Stop old container
docker stop todos-staging
docker rm todos-staging
```

**For database permission issues:**
```bash
# Check file permissions
ls -la /path/to/data/

# Fix permissions
chown -R 1000:1000 /path/to/data/
```

**For missing environment variables:**
```yaml
# In deploy-server action, ensure env vars are passed
- name: Deploy
  uses: ./.github/actions/deploy-server
  with:
    # Add any required env vars
    environment: |
      DB_PATH=/data/todos.db
      HOSTNAME=0.0.0.0
```

---

### Issue: "Deployment succeeds but application returns 502"

**Symptoms:** Deployment completes, but accessing the URL returns 502 Bad Gateway

**Causes:**
1. Application crashed after deployment
2. Application listening on wrong interface
3. Reverse proxy misconfigured

**Diagnosis:**

```bash
# 1. Check if container is running
docker ps
# Should see your container

# 2. Check container logs
docker logs todos-production

# 3. Check if app is listening
docker exec todos-production netstat -tlnp
# Should show:
# 0.0.0.0:8080  or  *:8080

# 4. Test from inside container
docker exec todos-production curl http://localhost:8080/health
# Should return: {"status":"ok"}

# 5. Test from host
curl http://localhost:8080/health
# Should also work
```

**Solutions:**

**If app listening on 127.0.0.1 only:**
```swift
// Application+build.swift
// Change from:
.bind(to: .hostname("127.0.0.1", port: 8080))

// To:
.bind(to: .hostname("0.0.0.0", port: 8080))
```

**If reverse proxy issue:**
```nginx
# Check nginx config (example)
location / {
    proxy_pass http://localhost:8080;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}
```

---

## Health Check Failures

### Issue: "Health check endpoint returns 404"

**Symptoms:**
```
✗ Health check failed: HTTP 404 Not Found
URL: https://staging.example.com/health
```

**Cause:** Health check route not registered correctly

**Diagnosis:**

```bash
# Test locally
docker-compose up
curl http://localhost:8080/health

# Should return 200 OK
# If 404, route is missing
```

**Solution:**

Check [todos-fluent/Sources/App/Application+build.swift](todos-fluent/Sources/App/Application+build.swift):

```swift
// Ensure routes are registered
let router = Router()
StatusController().addRoutes(to: router)
TodoController().addRoutes(to: router.group("api"))
```

Check [todos-fluent/Sources/App/Controllers/StatusController.swift](todos-fluent/Sources/App/Controllers/StatusController.swift):

```swift
func addRoutes(to group: RouterGroup<some RequestContext>) {
    group.get("health", use: health)  // Make sure this line exists
}
```

---

### Issue: "Health check times out"

**Symptoms:**
```
✗ Health check failed: Connection timeout
Retrying... (1/30)
Retrying... (2/30)
...
```

**Causes:**
1. Application not running
2. Firewall blocking connection
3. Application crashed
4. Wrong URL

**Diagnosis:**

```bash
# 1. Is container running?
docker ps

# 2. Can you reach it from the server itself?
curl http://localhost:8080/health

# 3. Check firewall
sudo ufw status
# Port 8080 should be allowed (or your proxy port like 80/443)

# 4. Check application logs
docker logs todos-staging --tail 50
```

**Solutions:**

**Container not running:**
```bash
# Start it manually
docker start todos-staging

# Check logs for crash reason
docker logs todos-staging
```

**Firewall issue:**
```bash
# Allow port (if not using reverse proxy)
sudo ufw allow 8080

# Or allow Nginx/Apache
sudo ufw allow 'Nginx Full'
```

---

## Version Management Issues

### Issue: "Version increment job fails with 'rejected non-fast-forward'"

**Symptoms:**
```
! [rejected] main -> main (non-fast-forward)
error: failed to push some refs to 'https://github.com/...'
```

**Cause:** Another workflow committed while this one was running

**Solution:**

This is a race condition. Two workflows tried to commit at the same time.

**Quick fix:**
```bash
# Re-run the workflow from GitHub Actions UI
# Usually succeeds on second try
```

**Long-term solution:**

Add pull before push in version-increment job:

```yaml
- name: Commit version file
  run: |
    git pull --rebase origin main
    git add VERSION
    git commit -m "chore: increment build number [skip ci]"
    git push
```

---

### Issue: "VERSION file shows wrong version"

**Symptoms:** VERSION file says `0.1.0.5` but Docker image is tagged `0.1.0.3`

**Cause:** Build used old version before commit was pushed

**Solution:**

Ensure build job depends on version increment:

```yaml
build-docker:
  needs: [lint, test, version-increment]
  steps:
    - name: Checkout code
      uses: actions/checkout@v4
      with:
        ref: main  # Important: use main, not PR branch
```

---

### Issue: "Git tag already exists"

**Symptoms:**
```
fatal: tag 'v0.1.1' already exists
```

**Cause:** Trying to create duplicate tag (usually from re-running production workflow)

**Solution:**

**Option 1: Delete and recreate tag (if not pushed)**
```bash
git tag -d v0.1.1
git push origin :refs/tags/v0.1.1
```

**Option 2: Increment version again**
```bash
# Use version-manager script
./scripts/version-manager.sh patch
# This creates v0.1.2 instead
```

**Option 3: Skip tag creation** (if you just want to redeploy)
```bash
# Manually deploy the existing version
./scripts/deploy.sh production
```

---

## SSH and Connectivity Issues

### Issue: "SSH connection times out"

**Symptoms:**
```
ssh: connect to host 203.0.113.10 port 22: Connection timed out
```

**Causes:**
1. Firewall blocking SSH
2. Wrong IP address
3. Server is down

**Diagnosis:**

```bash
# 1. Test SSH locally
ssh user@your-server-ip

# 2. Check if SSH port is open
nc -zv your-server-ip 22

# 3. Try with verbose logging
ssh -vvv user@your-server-ip
```

**Solutions:**

**Firewall issue:**
```bash
# On server, allow SSH
sudo ufw allow 22
```

**Wrong IP:**
```bash
# Verify IP in GitHub secrets
# Settings → Secrets → STAGING_HOST or PRODUCTION_HOST
```

**Custom SSH port:**
```yaml
# If using non-standard port (e.g., 2222)
- uses: ./.github/actions/deploy-server
  with:
    ssh_port: 2222  # Add this
```

---

### Issue: "Host key verification failed"

**Symptoms:**
```
Host key verification failed.
fatal: Could not read from remote repository.
```

**Cause:** Server's SSH host key not recognized

**Solution:**

Add server to known_hosts:

```yaml
# In workflow, before SSH step
- name: Add server to known hosts
  run: |
    mkdir -p ~/.ssh
    ssh-keyscan -H ${{ secrets.STAGING_HOST }} >> ~/.ssh/known_hosts
```

**Or:** Disable strict host key checking (less secure):

```yaml
- name: Deploy
  env:
    SSH_OPTIONS: "-o StrictHostKeyChecking=no"
  run: |
    ssh $SSH_OPTIONS user@host "docker pull..."
```

---

## Database Issues

### Issue: "Database file not found"

**Symptoms:**
```
Error: Failed to open database: /data/todos.db: no such file or directory
```

**Cause:** Database path doesn't exist or wrong permissions

**Solution:**

```bash
# 1. Create data directory on server
ssh user@server
mkdir -p /path/to/data
chmod 755 /path/to/data

# 2. Verify Docker volume mount
docker run -d \
  -v /path/to/data:/data \  # Make sure this matches
  -e DB_PATH=/data/todos.db \
  myimage:latest

# 3. Run migrations
docker exec todos-staging /app/.build/release/App migrate
```

---

### Issue: "Database backup fails"

**Symptoms:**
```
Error: cp: cannot stat '/data/todos.db': No such file or directory
```

**Cause:** Database doesn't exist yet (first deployment)

**Solution:**

Make backup optional for first deployment:

```bash
# In deploy script
if [ -f "/data/todos.db" ]; then
  echo "Creating backup..."
  cp /data/todos.db /data/backup_$(date +%Y%m%d_%H%M%S).db
else
  echo "No existing database to backup (first deployment)"
fi
```

---

### Issue: "Migration fails: table already exists"

**Symptoms:**
```
Error: table 'todos' already exists
Migration failed
```

**Cause:** Migration already ran, trying to run again

**Solution:**

Check migration status:

```bash
# Fluent tracks which migrations ran
# Don't re-run migrations manually unless you know what you're doing

# To reset (DANGER: deletes all data):
docker exec todos-staging /app/.build/release/App migrate --revert
```

**Correct approach:**
- Migrations should be idempotent
- Create new migration for new changes
- Don't modify existing migrations

---

## Application Runtime Issues

### Issue: "Application crashes with 'signal: killed'"

**Symptoms:**
```
docker logs todos-production
# Output:
signal: killed
```

**Cause:** Out of memory (OOM killer terminated the process)

**Solution:**

**1. Check memory usage:**
```bash
docker stats todos-production
# Look at MEM USAGE %
```

**2. Increase container memory limit:**
```bash
docker run -d \
  --memory="512m" \  # Add memory limit
  --name todos-production \
  myimage:latest
```

**3. Find memory leaks:**
```bash
# Monitor over time
watch -n 5 'docker stats --no-stream todos-production'
```

---

### Issue: "Application slow after deployment"

**Symptoms:** Requests take 5+ seconds instead of <100ms

**Possible Causes:**
1. Debug mode instead of release mode
2. Database not indexed
3. N+1 query problem
4. Resource contention

**Diagnosis:**

```bash
# 1. Check build mode
docker exec todos-production /app/.build/release/App --version
# Should be "release", not "debug"

# 2. Check logs for slow queries
docker logs todos-production | grep "Query"

# 3. Monitor CPU/memory
docker stats todos-production
```

**Solutions:**

**Ensure release build:**
```dockerfile
# In Dockerfile
RUN swift build -c release  # Not debug!
```

**Add database indexes:**
```swift
// In migration
struct CreateTodo: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("todos")
            .id()
            .field("title", .string, .required)
            .field("completed", .bool, .required)
            .create()

        // Add index on frequently queried field
        try await database.schema("todos")
            .index(on: "completed")
            .create()
    }
}
```

---

## Rollback Issues

### Issue: "Automatic rollback fails"

**Symptoms:**
```
Error: Rollback failed - old container not found
```

**Cause:** Old container was removed before rollback needed it

**Solution:**

Ensure blue-green deployment keeps old container:

```bash
# In deploy script
# DON'T do this until after health checks pass:
# docker rm old-container

# Instead:
# 1. Start new container
# 2. Health check new container
# 3. If success, then remove old
# 4. If failure, remove new and keep old
```

---

### Issue: "Rolled back but database is still new version"

**Symptoms:** App rolled back but can't read database

**Cause:** Database migration ran but wasn't reverted

**Solution:**

Include database rollback in rollback procedure:

```bash
# Rollback script should:
# 1. Stop new container
# 2. Restore database backup
# 3. Start old container

# See scripts/rollback.sh for full implementation
```

---

## General Debugging Tips

### Enable Debug Logging in GitHub Actions

Add secrets to your repository:

1. Go to Settings → Secrets → Actions
2. Add secret: `ACTIONS_STEP_DEBUG` = `true`
3. Add secret: `ACTIONS_RUNNER_DEBUG` = `true`
4. Re-run workflow

You'll see much more detailed logs.

---

### Check Workflow Run Logs

1. Go to GitHub Actions tab
2. Click on the workflow run
3. Click on the failed job
4. Expand the failing step
5. Look for red error messages

---

### Test Locally Before Pushing

```bash
# Run SwiftLint
cd todos-fluent && swiftlint

# Run tests
swift test

# Build Docker image
docker build -t test .

# Run container
docker run -p 8080:8080 test

# Test health endpoint
curl http://localhost:8080/health
```

---

### Use GitHub Actions `act` for Local Testing

```bash
# Install act (https://github.com/nektos/act)
brew install act

# Run workflows locally
act push  # Simulates push event

# Run specific workflow
act -W .github/workflows/ci.yml
```

---

### Common Commands for Debugging

```bash
# View running containers
docker ps

# View all containers (including stopped)
docker ps -a

# View container logs
docker logs container-name

# Follow logs in real-time
docker logs -f container-name

# Execute command in container
docker exec container-name ls /app

# Shell into container
docker exec -it container-name /bin/bash

# Inspect container
docker inspect container-name

# Check container resource usage
docker stats container-name

# View Docker images
docker images

# Clean up everything (DANGER: removes all containers/images)
docker system prune -a
```

---

## Still Stuck?

If you can't find your issue here:

1. **Check the specific documentation:**
   - [DEPLOYMENT.md](DEPLOYMENT.md) - Deployment details
   - [VERSIONING.md](VERSIONING.md) - Version management
   - [BUILD_OPTIMIZATION.md](BUILD_OPTIMIZATION.md) - Docker caching

2. **Review workflow logs carefully:**
   - GitHub Actions tab → Click workflow run → Expand failed step
   - Look for the **first** error message (not subsequent failures)

3. **Test individual components:**
   - Test SSH connection
   - Test Docker build locally
   - Test health endpoint
   - Test database connection

4. **Check GitHub Actions documentation:**
   - [GitHub Actions Docs](https://docs.github.com/en/actions)
   - [Workflow Syntax](https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions)

5. **Ask for help:**
   - Create an issue in this repository
   - Include: error message, logs, what you tried

---

**Remember:** Most issues are caused by:
- Configuration mistakes (typos in secrets, wrong paths)
- Permission problems (SSH keys, file permissions)
- Networking issues (firewall, wrong IP/port)
- Environment differences (local works, CI doesn't)

Carefully read error messages - they usually tell you exactly what's wrong!
