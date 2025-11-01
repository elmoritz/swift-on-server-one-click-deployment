---
layout: default
title: First Deployment
nav_order: 3
description: "Step-by-step tutorial for your first deployment"
permalink: /first-deployment
---

# Your First Deployment: From Code to Production

This tutorial will walk you through making your first deployment with this pipeline. You'll make a small code change, commit it, and watch it automatically deploy through staging to production.

**Time Required:** 30-45 minutes

**What You'll Learn:**
- How to trigger the CI pipeline
- What happens during automated testing
- How staging deployment works
- How to deploy to production
- How to verify your deployment

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Tutorial Overview](#tutorial-overview)
- [Step 1: Fork and Clone](#step-1-fork-and-clone)
- [Step 2: Run Locally](#step-2-run-locally)
- [Step 3: Make a Code Change](#step-3-make-a-code-change)
- [Step 4: Create a Pull Request](#step-4-create-a-pull-request)
- [Step 5: Watch the CI Pipeline](#step-5-watch-the-ci-pipeline)
- [Step 6: Merge to Main](#step-6-merge-to-main)
- [Step 7: Staging Deployment](#step-7-staging-deployment)
- [Step 8: Production Deployment](#step-8-production-deployment)
- [Step 9: Verify Your Deployment](#step-9-verify-your-deployment)
- [What Just Happened?](#what-just-happened)
- [Next Steps](#next-steps)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before starting, ensure you have:

- ✅ GitHub account
- ✅ Docker installed and running locally
- ✅ Git installed
- ✅ Terminal/command line access
- ✅ Text editor (VS Code, Vim, etc.)
- ✅ Basic familiarity with Git commands

**Optional (for actual deployment):**
- 🔹 A server with SSH access (for staging/production)
- 🔹 Docker installed on the server
- 🔹 GitHub secrets configured (see [SETUP_CHECKLIST.md](SETUP_CHECKLIST.md))

**Note:** This tutorial can be completed without a deployment server - you'll see the CI/CD pipeline run and understand the process, but the actual deployment steps will be simulated.

---

## Tutorial Overview

Here's what we'll do:

```
1. Fork the repo → 2. Run locally → 3. Make a change
                                            ↓
9. Verify ← 8. Production ← 7. Staging ← 6. Merge ← 5. Watch CI ← 4. Pull Request
```

**The Big Picture:**
1. You'll make a small change to add a new API endpoint
2. Create a pull request to trigger CI checks
3. Merge to main, which triggers staging deployment
4. Manually trigger production deployment
5. Verify everything works

Let's get started!

---

## Step 1: Fork and Clone

### 1.1 Fork the Repository

1. Go to the repository on GitHub
2. Click the **Fork** button in the top right
3. This creates your own copy of the repository

### 1.2 Clone Your Fork

```bash
# Replace YOUR_USERNAME with your GitHub username
git clone https://github.com/YOUR_USERNAME/swift-on-server-one-click-deployment.git

# Navigate into the directory
cd swift-on-server-one-click-deployment
```

### 1.3 Verify the Repository

```bash
# Check the files
ls -la

# You should see:
# - .github/          (CI/CD workflows)
# - todos-fluent/     (Swift application)
# - scripts/          (Deployment scripts)
# - Dockerfile        (Container definition)
# - README.md         (Documentation)
# ... and more
```

**Checkpoint:** You now have a local copy of the repository.

---

## Step 2: Run Locally

Before making changes, let's run the application locally to understand what it does.

### 2.1 Start the Application with Docker Compose

```bash
# Start the application (this may take a few minutes on first run)
docker-compose up
```

**What's happening:**
- Docker builds the Swift application
- Starts the server on port 8080
- Creates a SQLite database
- Runs health checks

### 2.2 Test the Application

Open a new terminal window (keep docker-compose running in the first) and test:

```bash
# Health check
curl http://localhost:8080/health

# Expected response:
# {"status":"ok"}

# List todos (empty initially)
curl http://localhost:8080/api/todos

# Expected response:
# {"todos":[]}

# Create a todo
curl -X POST http://localhost:8080/api/todos \
  -H "Content-Type: application/json" \
  -d '{"title":"My first todo","completed":false}'

# Expected response:
# {"id":"<uuid>","title":"My first todo","completed":false}

# List todos again
curl http://localhost:8080/api/todos

# Expected response:
# {"todos":[{"id":"<uuid>","title":"My first todo","completed":false}]}
```

### 2.3 Stop the Application

In the terminal running docker-compose, press `Ctrl+C` to stop.

```bash
# Clean up (optional)
docker-compose down
```

**Checkpoint:** You've successfully run the application locally and understand its API.

---

## Step 3: Make a Code Change

Now let's add a new endpoint that returns the version of the application.

### 3.1 Create a Feature Branch

```bash
# Create and switch to a new branch
git checkout -b feature/add-version-endpoint
```

### 3.2 Add the Version Endpoint

Open `todos-fluent/Sources/App/Controllers/StatusController.swift` in your text editor.

**Before** (around line 10-15):
```swift
import Hummingbird

struct StatusController {
    func addRoutes(to group: RouterGroup<some RequestContext>) {
        group.get("health", use: health)
    }

    @Sendable
    func health(request: Request, context: some RequestContext) async throws -> HTTPResponse.Status {
        return .ok
    }
}
```

**After** (add the version method):
```swift
import Hummingbird
import Foundation

struct StatusController {
    func addRoutes(to group: RouterGroup<some RequestContext>) {
        group.get("health", use: health)
        group.get("version", use: version)  // Add this line
    }

    @Sendable
    func health(request: Request, context: some RequestContext) async throws -> HTTPResponse.Status {
        return .ok
    }

    // Add this new method
    @Sendable
    func version(request: Request, context: some RequestContext) async throws -> VersionResponse {
        // Read version from VERSION file or use default
        let versionString = (try? String(contentsOfFile: "../VERSION"))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "0.1.0.1"
        return VersionResponse(version: versionString)
    }
}

// Add this response struct
struct VersionResponse: ResponseCodable {
    let version: String
}
```

### 3.3 Test Your Change Locally

```bash
# Start the application again
docker-compose up --build

# In another terminal, test the new endpoint
curl http://localhost:8080/version

# Expected response:
# {"version":"0.1.0.1"}
```

If it works, stop docker-compose with `Ctrl+C`.

### 3.4 Commit Your Change

```bash
# Stage the changed file
git add todos-fluent/Sources/App/Controllers/StatusController.swift

# Commit with a descriptive message
git commit -m "Add version endpoint to status controller"

# Push to your fork
git push origin feature/add-version-endpoint
```

**Checkpoint:** You've made a code change and pushed it to your fork.

---

## Step 4: Create a Pull Request

### 4.1 Open a Pull Request on GitHub

1. Go to your fork on GitHub
2. You'll see a banner: "feature/add-version-endpoint had recent pushes"
3. Click **Compare & pull request**
4. Fill in the PR details:
   - **Title:** "Add version endpoint to status controller"
   - **Description:** "This adds a new /version endpoint that returns the current application version."
5. Click **Create pull request**

### 4.2 What Happens Next

GitHub Actions will automatically trigger the CI pipeline. You'll see:

- ✅ A "Checks" section appears on your PR
- ✅ Several jobs start running (SwiftLint, Tests, Build, etc.)
- ✅ You can click "Details" to watch the progress

**This typically takes 5-8 minutes** on the first run (cold build) or **30-90 seconds** on subsequent runs (cached build).

**Checkpoint:** Your pull request is open and CI checks are running.

---

## Step 5: Watch the CI Pipeline

Let's understand what's happening in the CI pipeline.

### 5.1 View the Workflow Run

1. On your PR page, click **Details** next to any check
2. You'll see the workflow run with multiple jobs

### 5.2 Understanding the Jobs

The CI workflow runs these jobs **in parallel**:

#### Job 1: SwiftLint
```
Purpose: Code quality and style checking
What it does:
- Installs SwiftLint
- Runs linting on all Swift files
- Fails if code doesn't meet style guidelines
Time: ~30 seconds
```

#### Job 2: Unit Tests
```
Purpose: Run Swift unit tests
What it does:
- Checks out code
- Resolves Swift package dependencies
- Runs `swift test` with code coverage
- Uploads coverage to Codecov (if configured)
Time: ~2-3 minutes
```

#### Job 3: Build Docker Image
```
Purpose: Build and optionally push Docker image
What it does:
- Sets up Docker Buildx
- Logs into container registry
- Builds Docker image with caching
- Pushes to registry (only on main branch)
Time: ~30 seconds (cached) or ~5-8 minutes (cold)
```

#### Job 4: Integration Tests
```
Purpose: Test the application in a container
What it does:
- Starts the Docker container
- Waits for health check
- Runs API test suite (12+ tests)
- Verifies CRUD operations work
Time: ~1-2 minutes
```

#### Job 5: Security Scan
```
Purpose: Check for vulnerabilities
What it does:
- Scans Docker image with Trivy
- Checks for CVEs in dependencies
- Reports HIGH and CRITICAL vulnerabilities
Time: ~1 minute
```

### 5.3 Watch the Logs

Click on any job to see detailed logs. For example, in **Integration Tests**:

```
Running API Test Suite
✓ Health check endpoint
✓ Create todo
✓ List todos
✓ Get specific todo
✓ Update todo
✓ Delete todo
... (and more)

All tests passed!
```

### 5.4 Wait for All Checks to Pass

All jobs must pass (green checkmarks) before you can merge.

**If a check fails:**
- Click "Details" to see what went wrong
- Fix the issue locally
- Commit and push again
- The CI pipeline will automatically re-run

**Checkpoint:** All CI checks are passing.

---

## Step 6: Merge to Main

### 6.1 Merge the Pull Request

Once all checks are green:

1. Click **Merge pull request**
2. Confirm the merge
3. Optionally delete the feature branch

### 6.2 What Happens After Merge

When you merge to `main`, **two things trigger automatically**:

1. **CI Workflow Runs Again** (on main branch)
   - Same checks as before
   - **Plus:** Automatic version increment (build number +1)
   - **Plus:** Docker image is pushed to registry

2. **Staging Deployment Workflow Triggers** (automatic)
   - Deploys to staging environment
   - Runs health checks
   - Runs API tests against staging
   - Monitors for 5 minutes
   - Auto-rolls back if anything fails

### 6.3 Watch the Workflows

Go to the **Actions** tab in your repository:

1. You'll see two workflows running:
   - `CI` (runs on every push to main)
   - `Deploy to Staging` (runs after CI completes)

2. Click on `Deploy to Staging` to watch the deployment

**Checkpoint:** Your code is merged and staging deployment is running.

---

## Step 7: Staging Deployment

Let's understand what happens during staging deployment.

### 7.1 View the Deployment Workflow

In the **Deploy to Staging** workflow, you'll see these steps:

#### Step 1: Pre-Deployment Checks
```
- Checkout code
- Read current version
- Verify Docker image exists in registry
```

#### Step 2: Database Backup
```
- SSH to staging server
- Create database backup
- Store with timestamp: todos_backup_YYYYMMDD_HHMMSS.db
```

#### Step 3: Deploy New Version
```
- SSH to staging server
- Pull latest Docker image
- Stop old container (blue-green pattern)
- Start new container with new version
- Old container kept running until health checks pass
```

#### Step 4: Health Check
```
- Wait for container to be ready
- Test /health endpoint
- Retry up to 10 times with 5s intervals
- If fails: automatic rollback to previous version
```

#### Step 5: API Tests
```
- Run full API test suite against staging
- Verify all endpoints work correctly
- If fails: automatic rollback
```

#### Step 6: Extended Monitoring
```
- Monitor for 5 minutes
- Continuous health checks
- Watch for errors in logs
- If issues detected: automatic rollback
```

#### Step 7: Finalize
```
- Stop old container
- Clean up old Docker images
- Update deployment metadata
- Send success notification
```

### 7.2 Simulated Deployment (No Server)

**If you don't have a staging server configured:**

The workflow will fail at the SSH step, which is expected. In a real setup, you'd have:

- A server with Docker installed
- SSH access configured
- GitHub secrets set up with server credentials

See [SETUP_CHECKLIST.md](SETUP_CHECKLIST.md) for how to configure this.

### 7.3 Automatic Rollback Example

**What if something goes wrong?**

The pipeline has automatic rollback for:
- ❌ Health check fails
- ❌ API tests fail
- ❌ Service becomes unhealthy during monitoring

**Example scenario:**
```
1. New version deploys
2. Health check fails
3. Automatic rollback triggered:
   - Stop new container
   - Start old container
   - Restore database from backup
   - Verify old version is healthy
4. Deployment marked as failed
5. Notification sent
```

**Checkpoint:** You understand the staging deployment process.

---

## Step 8: Production Deployment

Production deployments are **always manual** for safety. Let's trigger one.

### 8.1 Navigate to Actions

1. Go to your repository on GitHub
2. Click the **Actions** tab
3. Select **Deploy to Production** workflow from the left sidebar

### 8.2 Trigger the Workflow

1. Click **Run workflow** (top right)
2. You'll see options:
   - **Branch:** main (usually)
   - **Version type:** patch, minor, or major
   - **Environment:** production

3. Choose:
   - **Version type:** `patch` (for this tutorial)
   - Leave other defaults
4. Click **Run workflow**

### 8.3 What Happens in Production Deployment

The production workflow is similar to staging but with extra safety:

#### Phase 1: Pre-Deployment Validation
```
- Verify staging is healthy
- Check version matches expected
- Validate GitHub release doesn't exist yet
- Verify all tests passed in staging
```

#### Phase 2: Version Bump
```
- Increment version (e.g., 0.1.0.1 → 0.1.1.0 for patch)
- Commit new version to git
- Create git tag (e.g., v0.1.1)
- Push tag to repository
```

#### Phase 3: Build Release
```
- Build Docker image with new version tag
- Push to registry with version tag
- Also tag as "latest" and "production"
```

#### Phase 4: Create GitHub Release
```
- Create GitHub release from tag
- Generate release notes from commits
- Attach build artifacts
```

#### Phase 5: Deploy to Production
```
- Database backup (critical data!)
- Blue-green deployment
- Health checks (stricter than staging)
- API smoke tests
- 15-minute extended monitoring (longer than staging)
- Auto-rollback on any issues
```

#### Phase 6: Post-Deployment
```
- Verify deployment metadata
- Send success notification
- Update monitoring dashboards
- Clean up old versions
```

### 8.4 Monitor the Deployment

Watch the workflow run. The entire process takes **15-20 minutes** due to extended monitoring.

**Key differences from staging:**
- ✅ Version is bumped and tagged
- ✅ GitHub release is created
- ✅ Longer monitoring period (15 min vs 5 min)
- ✅ More stringent health checks
- ✅ Manual trigger required (no automatic deployment)

**Checkpoint:** Production deployment is running or completed.

---

## Step 9: Verify Your Deployment

Let's verify everything worked correctly.

### 9.1 Check the GitHub Release

1. Go to your repository on GitHub
2. Click **Releases** (right sidebar)
3. You should see a new release: **v0.1.1**
4. It includes:
   - Release notes (generated from commits)
   - Associated git tag
   - Timestamp

### 9.2 Check the Version File

```bash
# Pull the latest changes
git pull origin main

# View the VERSION file
cat VERSION

# Should show: 0.1.1.0
```

### 9.3 Test Your New Endpoint (If Deployed)

If you have a production server:

```bash
# Test the new version endpoint
curl https://your-production-domain.com/version

# Expected response:
# {"version":"0.1.1.0"}

# Test the health endpoint
curl https://your-production-domain.com/health

# Expected response:
# {"status":"ok"}
```

### 9.4 Check the Docker Image

Your Docker image should be tagged in the registry:

```
yourregistry/todos-app:0.1.1
yourregistry/todos-app:latest
yourregistry/todos-app:production
```

**Checkpoint:** Your code is live in production!

---

## What Just Happened?

Let's recap the entire flow:

### Code Change → Production

```
1. Feature Branch
   ↓
2. Pull Request → CI Checks Run
   ├─ SwiftLint
   ├─ Unit Tests
   ├─ Docker Build
   ├─ Integration Tests
   └─ Security Scan
   ↓ (all pass)
3. Merge to Main
   ↓
4. CI Runs Again
   ├─ All checks
   ├─ Version increment (build +1)
   └─ Push Docker image
   ↓
5. Staging Deployment (Automatic)
   ├─ Database backup
   ├─ Deploy new version
   ├─ Health checks
   ├─ API tests
   ├─ 5-minute monitoring
   └─ Success!
   ↓
6. Manual Production Trigger
   ↓
7. Production Deployment
   ├─ Pre-flight checks
   ├─ Version bump (0.1.0.1 → 0.1.1.0)
   ├─ Git tag (v0.1.1)
   ├─ GitHub release
   ├─ Database backup
   ├─ Blue-green deploy
   ├─ Health checks
   ├─ 15-minute monitoring
   └─ Success!
   ↓
8. Live in Production! 🎉
```

### Key Takeaways

**Automation:**
- ✅ Every commit is tested automatically
- ✅ Staging deploys automatically on merge to main
- ✅ Version numbers increment automatically
- ✅ Docker images are built and cached efficiently

**Safety:**
- ✅ Production requires manual approval
- ✅ Database backups before every deployment
- ✅ Automatic rollback on failures
- ✅ Extended monitoring periods
- ✅ Health checks at every step

**Speed:**
- ✅ CI completes in 30-90 seconds (with caching)
- ✅ Parallel jobs for faster feedback
- ✅ Registry-based caching (5-10x faster builds)

**Visibility:**
- ✅ Every step is logged in GitHub Actions
- ✅ Git tags for every release
- ✅ GitHub releases with notes
- ✅ Version tracking in code

---

## Next Steps

Congratulations! You've completed your first deployment. Here's what to explore next:

### 1. Understand the Architecture
Read [PIPELINE_ARCHITECTURE.md](PIPELINE_ARCHITECTURE.md) to understand **why** the pipeline is designed this way.

### 2. Learn GitHub Actions Deeply
Read [GITHUB_ACTIONS_PRIMER.md](GITHUB_ACTIONS_PRIMER.md) to understand how to customize workflows.

### 3. Explore Versioning
Read [VERSIONING.md](VERSIONING.md) to learn about semantic versioning and manual version management.

### 4. Optimize Builds
Read [BUILD_OPTIMIZATION.md](BUILD_OPTIMIZATION.md) to understand the Docker caching strategy.

### 5. Study the Reusable Actions
Read [REUSABLE_ACTIONS.md](REUSABLE_ACTIONS.md) and explore [.github/actions/](.github/actions/) to see how to create modular workflows.

### 6. Set Up Your Own Pipeline
Follow [SETUP_CHECKLIST.md](SETUP_CHECKLIST.md) to adapt this pipeline to your own project.

### 7. Practice Troubleshooting
Try breaking things intentionally:
- Make tests fail
- Introduce a linting error
- Deploy a version that fails health checks
- Then use [TROUBLESHOOTING.md](TROUBLESHOOTING.md) to fix them

---

## Troubleshooting

### CI Checks Failing

**Problem:** SwiftLint fails

**Solution:**
```bash
# Install SwiftLint locally
brew install swiftlint  # macOS
# or check .github/actions/setup-swiftlint/

# Run locally to see issues
cd todos-fluent
swiftlint

# Fix issues and commit
```

---

**Problem:** Unit tests fail

**Solution:**
```bash
# Run tests locally
cd todos-fluent
swift test

# Fix failing tests
# Commit and push
```

---

**Problem:** Docker build fails

**Solution:**
```bash
# Build locally to see the error
docker build -t todos-test .

# Common issues:
# - Missing dependency in Package.swift
# - Syntax error in Swift code
# - Invalid Dockerfile syntax
```

---

### Deployment Failing

**Problem:** Health check times out

**Solution:**
- Check if the server is running: `curl http://your-server:8080/health`
- Look at container logs: `docker logs <container-id>`
- Verify port 8080 is exposed
- Check if the old container is still holding the port

---

**Problem:** SSH connection fails

**Solution:**
- Verify SSH credentials in GitHub secrets
- Test SSH manually: `ssh user@your-server`
- Check if SSH key is correct
- Verify server firewall rules

---

**Problem:** Docker image not found

**Solution:**
- Check if CI workflow pushed the image
- Verify registry credentials
- Look for "Push Docker Image" step in CI logs
- Ensure you're on main branch (images only push from main)

---

### Version Issues

**Problem:** Version didn't increment

**Solution:**
- Check if `version-increment` job ran in CI
- Verify VERSION file was committed
- Look for version commit in git history: `git log --oneline --grep="version"`

---

**Problem:** Production deployment fails due to version mismatch

**Solution:**
- Pull latest changes: `git pull origin main`
- Check current version: `cat VERSION`
- Verify the tag doesn't exist: `git tag -l`
- Re-run production workflow

---

### Need More Help?

- Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for comprehensive debugging guide
- Review [DEPLOYMENT.md](DEPLOYMENT.md) for deployment details
- Check workflow logs in GitHub Actions
- Verify your setup with [SETUP_CHECKLIST.md](SETUP_CHECKLIST.md)

---

**Congratulations on completing your first deployment!** 🚀

You now understand how a production-grade CI/CD pipeline works for Swift server applications.
