---
layout: default
title: GitHub Actions Primer
nav_order: 4
description: "Introduction to GitHub Actions for Swift developers"
permalink: /github-actions-primer
---

# GitHub Actions Primer for Swift Developers

If you're new to GitHub Actions or CI/CD in general, this guide will teach you everything you need to know to understand and customize this deployment pipeline.

**What You'll Learn:**
- What GitHub Actions is and why it's useful
- Core concepts: workflows, jobs, steps, actions
- How to read and understand workflow files
- Common patterns used in this repository
- How to customize workflows for your needs

---

## Table of Contents

- [What is GitHub Actions?](#what-is-github-actions)
- [Why Use GitHub Actions?](#why-use-github-actions)
- [Core Concepts](#core-concepts)
- [Anatomy of a Workflow](#anatomy-of-a-workflow)
- [Understanding Our Workflows](#understanding-our-workflows)
- [Common Patterns](#common-patterns)
- [Secrets and Environment Variables](#secrets-and-environment-variables)
- [Debugging Workflows](#debugging-workflows)
- [Best Practices](#best-practices)
- [Further Reading](#further-reading)

---

## What is GitHub Actions?

**GitHub Actions** is a CI/CD (Continuous Integration/Continuous Deployment) platform built into GitHub.

### In Simple Terms

Think of it as a robot that:
1. **Watches** your repository for events (like commits, pull requests)
2. **Automatically runs** tasks you define (tests, builds, deployments)
3. **Reports** the results back to you

### Example Scenario

**Without GitHub Actions:**
```
1. You write code
2. You manually run tests locally
3. You manually build the application
4. You manually SSH to server
5. You manually deploy
6. You manually verify it works
```

**With GitHub Actions:**
```
1. You write code and push
2. GitHub Actions automatically:
   - Runs tests
   - Builds the application
   - Deploys to server
   - Verifies it works
   - Notifies you of the result
```

---

## Why Use GitHub Actions?

### 1. **Consistency**
Every build and deployment follows the exact same process. No "works on my machine" problems.

### 2. **Speed**
Automated processes are faster than manual ones. Get feedback in minutes, not hours.

### 3. **Safety**
Catch bugs before they reach production. Automated tests run on every commit.

### 4. **Collaboration**
Team members can see the status of builds and deployments. No guessing if something is broken.

### 5. **Free for Public Repos**
GitHub provides 2,000 free minutes/month for private repos, unlimited for public repos.

---

## Core Concepts

Let's break down the key concepts with analogies:

### 1. Workflow

**What it is:** A workflow is an automated process defined in a YAML file.

**Analogy:** Think of it as a **recipe** that tells GitHub Actions what to do.

**Location:** `.github/workflows/` directory

**Example:**
```yaml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: swift test
```

**Key Points:**
- One repository can have multiple workflows
- Each workflow is a separate YAML file
- Workflows are triggered by events

---

### 2. Events (Triggers)

**What it is:** Events are actions that trigger workflows to run.

**Common Events:**
- `push` - Code is pushed to the repository
- `pull_request` - A PR is opened or updated
- `workflow_dispatch` - Manual trigger via UI
- `schedule` - Run on a schedule (cron)
- `release` - A release is published

**Example:**
```yaml
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]
  workflow_dispatch:
```

**Translation:** Run this workflow when:
- Code is pushed to `main` or `develop` branches
- A pull request is opened targeting `main`
- Someone manually triggers it via the GitHub UI

---

### 3. Jobs

**What it is:** A job is a set of steps that run on the same runner (virtual machine).

**Analogy:** Think of it as a **task** in your recipe.

**Key Points:**
- Multiple jobs can run in parallel (by default)
- Jobs can depend on other jobs
- Each job runs in a fresh environment

**Example:**
```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps: [...]

  build:
    runs-on: ubuntu-latest
    needs: test  # Wait for 'test' job to complete
    steps: [...]
```

**Translation:**
- Job `test` runs first
- Job `build` waits for `test` to succeed
- If `test` fails, `build` doesn't run

---

### 4. Steps

**What it is:** A step is an individual task within a job.

**Analogy:** Think of it as a **line in your recipe** ("mix the flour", "bake for 20 minutes").

**Types of Steps:**

#### Using an Action (with `uses`)
```yaml
- uses: actions/checkout@v4
```
**Translation:** Use the pre-built `checkout` action to download the repository code.

#### Running a Command (with `run`)
```yaml
- run: swift test
```
**Translation:** Execute the `swift test` command in the shell.

#### Using a Custom Action
```yaml
- uses: ./.github/actions/setup-swiftlint
```
**Translation:** Use the custom action defined in this repository.

---

### 5. Runners

**What it is:** A runner is the virtual machine that executes your jobs.

**Available Runners:**
- `ubuntu-latest` - Ubuntu Linux (most common)
- `macos-latest` - macOS (for iOS/Swift development)
- `windows-latest` - Windows

**Example:**
```yaml
jobs:
  test:
    runs-on: ubuntu-latest  # Use Ubuntu Linux
```

**Key Points:**
- Each job gets a fresh runner (clean slate)
- Runners have pre-installed software (git, docker, etc.)
- macOS runners are slower but necessary for iOS builds

---

### 6. Actions

**What it is:** An action is a reusable unit of code that performs a specific task.

**Types:**

#### Official GitHub Actions
```yaml
- uses: actions/checkout@v4       # Checkout code
- uses: actions/setup-node@v3     # Install Node.js
- uses: actions/cache@v3          # Cache dependencies
```

#### Community Actions
```yaml
- uses: docker/build-push-action@v5  # Build Docker images
```

#### Custom Actions (Composite)
```yaml
- uses: ./.github/actions/setup-swiftlint  # Your own action
```

**Analogy:** Actions are like **pre-packaged ingredients** - you don't make them from scratch, you just use them.

---

## Anatomy of a Workflow

Let's dissect a simple workflow file:

```yaml
name: CI                                    # 1. Name shown in GitHub UI

on:                                         # 2. When to run
  push:
    branches: [main]
  pull_request:

jobs:                                       # 3. Jobs to run
  test:                                     # Job ID
    name: Run Tests                         # Job display name
    runs-on: ubuntu-latest                  # Operating system

    steps:                                  # 4. Steps in this job
      - name: Checkout code                 # Step name
        uses: actions/checkout@v4           # Action to use

      - name: Run Swift tests               # Step name
        run: swift test                     # Command to run
        working-directory: ./todos-fluent   # Where to run it

      - name: Upload results                # Conditional step
        if: failure()                       # Only if previous steps failed
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: test-results/
```

### Breaking It Down

**1. Metadata Section**
```yaml
name: CI
```
- This is what you'll see in the GitHub UI

**2. Trigger Section**
```yaml
on:
  push:
    branches: [main]
  pull_request:
```
- Run on push to `main` branch
- Run on any pull request

**3. Jobs Section**
```yaml
jobs:
  test:
    name: Run Tests
    runs-on: ubuntu-latest
```
- Job ID: `test`
- Display name: "Run Tests"
- Runs on Ubuntu Linux

**4. Steps Section**
```yaml
steps:
  - name: Checkout code
    uses: actions/checkout@v4
```
- Each step has a name (optional but recommended)
- Can use actions or run commands

---

## Understanding Our Workflows

This repository has **three main workflows**:

### 1. CI Workflow ([.github/workflows/ci.yml](.github/workflows/ci.yml))

**Purpose:** Validate code quality and functionality

**Triggers:**
- Push to `main` or `develop`
- Any pull request

**Jobs (run in parallel):**

```
┌─────────────┐  ┌──────────────┐  ┌─────────────┐
│  SwiftLint  │  │  Unit Tests  │  │ Build Docker│
│             │  │              │  │   Image     │
└─────────────┘  └──────────────┘  └─────────────┘
      ↓                  ↓                  ↓
      └──────────────────┴──────────────────┘
                         ↓
              ┌──────────────────────┐
              │  Integration Tests   │
              │  (needs: build)      │
              └──────────────────────┘
                         ↓
              ┌──────────────────────┐
              │   Security Scan      │
              │  (needs: build)      │
              └──────────────────────┘
```

**Key Features:**
- Parallel execution for speed
- Caches Swift packages (speeds up subsequent runs)
- Only pushes Docker image from `main` branch
- Increments version on `main` branch

**Workflow Structure:**
```yaml
name: CI
on: [push, pull_request]

jobs:
  swiftlint:        # Runs independently
  unit-tests:       # Runs independently
  build:            # Runs independently
  integration:      # Waits for 'build'
  security:         # Waits for 'build'
```

---

### 2. Deploy to Staging ([.github/workflows/deploy-staging.yml](.github/workflows/deploy-staging.yml))

**Purpose:** Automatically deploy to staging environment

**Triggers:**
- Push to `main` branch (after CI completes)
- Manual trigger via `workflow_dispatch`

**Jobs (sequential):**

```
┌──────────────────────┐
│   Read Version       │
└──────────────────────┘
           ↓
┌──────────────────────┐
│   Deploy to Staging  │
│   - Backup DB        │
│   - Pull image       │
│   - Blue-green       │
└──────────────────────┘
           ↓
┌──────────────────────┐
│   Health Check       │
└──────────────────────┘
           ↓
┌──────────────────────┐
│   API Tests          │
└──────────────────────┐
           ↓
┌──────────────────────┐
│   Extended Monitor   │
│   (5 minutes)        │
└──────────────────────┘
```

**Key Features:**
- Automatic deployment after successful CI
- Database backup before deployment
- Health checks with automatic rollback
- Extended monitoring period

---

### 3. Deploy to Production ([.github/workflows/deploy-production.yml](.github/workflows/deploy-production.yml))

**Purpose:** Manually deploy to production with version tagging

**Triggers:**
- **Manual only** via `workflow_dispatch`

**Jobs (sequential):**

```
┌──────────────────────┐
│  Version Increment   │
│  (patch/minor/major) │
└──────────────────────┘
           ↓
┌──────────────────────┐
│  Build & Push        │
│  with version tag    │
└──────────────────────┘
           ↓
┌──────────────────────┐
│  Create Release      │
│  (GitHub Release)    │
└──────────────────────┘
           ↓
┌──────────────────────┐
│  Deploy to Prod      │
│  - Backup DB         │
│  - Blue-green        │
└──────────────────────┘
           ↓
┌──────────────────────┐
│  Extended Monitor    │
│  (15 minutes)        │
└──────────────────────┘
```

**Key Features:**
- Manual trigger only (safety)
- Semantic version bump
- Git tag creation
- GitHub release with notes
- Longer monitoring (15 minutes)

---

## Common Patterns

### Pattern 1: Checkout Code

**Every job needs to start with this:**

```yaml
steps:
  - name: Checkout code
    uses: actions/checkout@v4
```

**Why?** Runners start with an empty filesystem. This downloads your repository code.

---

### Pattern 2: Caching Dependencies

**Speed up builds by caching dependencies:**

```yaml
- name: Cache Swift packages
  uses: actions/cache@v3
  with:
    path: .build
    key: ${{ runner.os }}-spm-${{ hashFiles('**/Package.resolved') }}
    restore-keys: |
      ${{ runner.os }}-spm-
```

**How it works:**
1. First run: No cache exists, downloads all dependencies (~3 minutes)
2. Subsequent runs: Cache hit, reuses dependencies (~10 seconds)
3. When `Package.resolved` changes: Cache miss, downloads new dependencies

---

### Pattern 3: Conditional Steps

**Run steps only under certain conditions:**

```yaml
- name: Push Docker image
  if: github.ref == 'refs/heads/main'  # Only on main branch
  run: docker push myimage:latest

- name: Upload failure logs
  if: failure()  # Only if previous steps failed
  uses: actions/upload-artifact@v3
  with:
    name: logs
    path: logs/
```

**Common Conditions:**
- `if: success()` - Previous steps succeeded
- `if: failure()` - Previous steps failed
- `if: always()` - Run regardless of previous steps
- `if: github.ref == 'refs/heads/main'` - Only on main branch
- `if: github.event_name == 'pull_request'` - Only on PRs

---

### Pattern 4: Matrix Builds

**Test across multiple versions/platforms:**

```yaml
jobs:
  test:
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]
        swift: ['5.9', '5.10']
    runs-on: ${{ matrix.os }}
    steps:
      - uses: swift-actions/setup-swift@v1
        with:
          swift-version: ${{ matrix.swift }}
      - run: swift test
```

**Result:** This creates **4 jobs** (2 OS × 2 Swift versions) that run in parallel.

---

### Pattern 5: Job Dependencies

**Control execution order:**

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps: [...]

  test:
    needs: build  # Wait for 'build' to succeed
    runs-on: ubuntu-latest
    steps: [...]

  deploy:
    needs: [build, test]  # Wait for both
    runs-on: ubuntu-latest
    steps: [...]
```

**Execution Flow:**
```
build → test → deploy
```

---

### Pattern 6: Reusable Workflows (Composite Actions)

**Create reusable building blocks:**

```yaml
# .github/actions/health-check/action.yml
name: Health Check
description: Verify application health
inputs:
  url:
    description: URL to check
    required: true
runs:
  using: composite
  steps:
    - run: |
        for i in {1..10}; do
          if curl -f ${{ inputs.url }}/health; then
            exit 0
          fi
          sleep 5
        done
        exit 1
      shell: bash
```

**Usage:**
```yaml
- name: Check health
  uses: ./.github/actions/health-check
  with:
    url: https://staging.example.com
```

**Benefits:**
- DRY (Don't Repeat Yourself)
- Easier to maintain
- Consistent behavior across workflows

---

## Secrets and Environment Variables

### What Are Secrets?

**Secrets** are encrypted environment variables for sensitive data (passwords, API keys, SSH keys).

### Setting Up Secrets

1. Go to your repository on GitHub
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add secrets like:
   - `DEPLOY_HOST` - Server hostname
   - `DEPLOY_USER` - SSH username
   - `DEPLOY_KEY` - SSH private key
   - `DOCKER_USERNAME` - Registry username
   - `DOCKER_PASSWORD` - Registry password

### Using Secrets in Workflows

```yaml
- name: SSH Deploy
  env:
    DEPLOY_HOST: ${{ secrets.DEPLOY_HOST }}
    DEPLOY_USER: ${{ secrets.DEPLOY_USER }}
    DEPLOY_KEY: ${{ secrets.DEPLOY_KEY }}
  run: |
    echo "$DEPLOY_KEY" > key.pem
    chmod 600 key.pem
    ssh -i key.pem $DEPLOY_USER@$DEPLOY_HOST "docker pull myimage"
```

### Environment Variables

**Built-in variables:**
- `${{ github.repository }}` - Repository name (e.g., "user/repo")
- `${{ github.ref }}` - Branch/tag ref (e.g., "refs/heads/main")
- `${{ github.sha }}` - Commit SHA
- `${{ github.actor }}` - User who triggered the workflow
- `${{ github.event_name }}` - Event type (push, pull_request, etc.)

**Custom variables:**
```yaml
env:
  NODE_ENV: production
  API_URL: https://api.example.com

jobs:
  deploy:
    runs-on: ubuntu-latest
    env:
      DEPLOY_ENV: staging  # Job-level
    steps:
      - run: echo $NODE_ENV      # "production"
      - run: echo $DEPLOY_ENV    # "staging"
```

---

## Debugging Workflows

### 1. View Workflow Runs

**In GitHub:**
1. Go to **Actions** tab
2. Click on a workflow run
3. Click on a job to see detailed logs

### 2. Enable Debug Logging

**Add secrets to your repository:**
- `ACTIONS_STEP_DEBUG` = `true` (detailed debug logs)
- `ACTIONS_RUNNER_DEBUG` = `true` (runner diagnostic logs)

### 3. Use `echo` for Debugging

```yaml
- name: Debug info
  run: |
    echo "Current directory: $(pwd)"
    echo "Files: $(ls -la)"
    echo "Branch: ${{ github.ref }}"
    echo "Commit: ${{ github.sha }}"
```

### 4. SSH into the Runner (Advanced)

Use `tmate` action to SSH into the runner:

```yaml
- name: Setup tmate session
  if: failure()  # Only on failure
  uses: mxschmitt/action-tmate@v3
```

### 5. Common Issues

**Problem:** `No such file or directory`

**Solution:** Add `actions/checkout@v4` step at the beginning.

---

**Problem:** Step fails but no clear error

**Solution:** Enable debug logging (see above).

---

**Problem:** Secrets not working

**Solution:** Verify secret names match exactly (case-sensitive).

---

**Problem:** Cache not working

**Solution:** Check that the cache key is stable and the path exists.

---

## Best Practices

### 1. **Name Everything Clearly**

**Bad:**
```yaml
jobs:
  job1:
    steps:
      - run: swift test
```

**Good:**
```yaml
jobs:
  unit-tests:
    name: Run Swift Unit Tests
    steps:
      - name: Execute test suite
        run: swift test
```

---

### 2. **Use Specific Action Versions**

**Bad:**
```yaml
- uses: actions/checkout@main  # Could break if action changes
```

**Good:**
```yaml
- uses: actions/checkout@v4  # Stable, pinned version
```

---

### 3. **Fail Fast**

**Catch errors early:**
```yaml
jobs:
  lint:
    # Fast checks first
  test:
    needs: lint  # Don't run slow tests if lint fails
  deploy:
    needs: [lint, test]  # Don't deploy if anything fails
```

---

### 4. **Use Caching**

**Cache everything possible:**
- Swift packages
- Docker layers
- Node modules
- Build artifacts

---

### 5. **Keep Secrets Safe**

**Bad:**
```yaml
- run: echo "Password is ${{ secrets.PASSWORD }}"  # Exposed in logs!
```

**Good:**
```yaml
- run: |
    # Use secrets without echoing them
    echo "${{ secrets.PASSWORD }}" | docker login -u user --password-stdin
```

---

### 6. **Use Composite Actions**

**DRY principle:**
- If you repeat the same steps in multiple workflows, create a composite action
- Easier to maintain
- Consistent behavior

---

### 7. **Add Timeout Limits**

**Prevent runaway jobs:**
```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    timeout-minutes: 10  # Kill job after 10 minutes
    steps: [...]
```

---

### 8. **Use `continue-on-error` Wisely**

**For optional checks:**
```yaml
- name: Optional security scan
  run: trivy scan
  continue-on-error: true  # Don't fail the job if this fails
```

---

## Further Reading

### Official Documentation
- **GitHub Actions Docs:** https://docs.github.com/en/actions
- **Workflow Syntax:** https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions
- **Action Marketplace:** https://github.com/marketplace?type=actions

### Tutorials
- **Quickstart:** https://docs.github.com/en/actions/quickstart
- **Building and Testing Swift:** https://docs.github.com/en/actions/guides/building-and-testing-swift

### Community Actions
- **Awesome Actions:** https://github.com/sdras/awesome-actions
- **Swift Actions:** https://github.com/swift-actions

---

## Next Steps

Now that you understand GitHub Actions:

1. **Explore our workflows:**
   - [.github/workflows/ci.yml](.github/workflows/ci.yml)
   - [.github/workflows/deploy-staging.yml](.github/workflows/deploy-staging.yml)
   - [.github/workflows/deploy-production.yml](.github/workflows/deploy-production.yml)

2. **Study our composite actions:**
   - [.github/actions/](.github/actions/)

3. **Read the architecture guide:**
   - [PIPELINE_ARCHITECTURE.md](pipeline-architecture)

4. **Try the hands-on tutorial:**
   - [FIRST_DEPLOYMENT.md](first-deployment)

---

**You're now ready to understand and customize GitHub Actions workflows!** 🚀
