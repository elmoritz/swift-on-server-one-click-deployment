---
layout: default
title: Pipeline Architecture
nav_order: 5
description: "Understanding the design decisions behind the CI/CD pipeline"
permalink: /pipeline-architecture
---

# Pipeline Architecture: Design Decisions and Rationale

This document explains **why** the CI/CD pipeline is designed the way it is. Understanding these decisions will help you adapt this approach to your own projects.

**Target Audience:** Developers who want to understand the reasoning behind the pipeline design, not just how to use it.

---

## Table of Contents

- [Philosophy and Goals](#philosophy-and-goals)
- [High-Level Architecture](#high-level-architecture)
- [Design Decision 1: Three Separate Workflows](#design-decision-1-three-separate-workflows)
- [Design Decision 2: Parallel vs Sequential Jobs](#design-decision-2-parallel-vs-sequential-jobs)
- [Design Decision 3: Registry-Based Docker Caching](#design-decision-3-registry-based-docker-caching)
- [Design Decision 4: Composite Actions for Reusability](#design-decision-4-composite-actions-for-reusability)
- [Design Decision 5: Blue-Green Deployment Pattern](#design-decision-5-blue-green-deployment-pattern)
- [Design Decision 6: Automatic Staging, Manual Production](#design-decision-6-automatic-staging-manual-production)
- [Design Decision 7: Semantic Versioning with Build Numbers](#design-decision-7-semantic-versioning-with-build-numbers)
- [Design Decision 8: Health Checks and Automatic Rollback](#design-decision-8-health-checks-and-automatic-rollback)
- [Design Decision 9: Extended Post-Deployment Monitoring](#design-decision-9-extended-post-deployment-monitoring)
- [Design Decision 10: Database Backup Before Deployment](#design-decision-10-database-backup-before-deployment)
- [Trade-offs and Alternatives](#trade-offs-and-alternatives)
- [When to Deviate from This Pattern](#when-to-deviate-from-this-pattern)

---

## Philosophy and Goals

Before diving into specifics, here are the guiding principles:

### Core Principles

1. **Safety First:** It should be hard to break production accidentally
2. **Fast Feedback:** Developers should know if something is wrong within minutes
3. **Automation:** Humans shouldn't do repetitive tasks
4. **Visibility:** Every step should be observable and logged
5. **Recoverability:** Bad deployments should be easy to undo
6. **Progressive Delivery:** Changes flow through environments (CI → Staging → Production)

### Non-Goals

- ❌ **Not optimized for monorepos** (single application focus)
- ❌ **Not zero-downtime for this tutorial** (could be added)
- ❌ **Not multi-region deployment** (single server deployment)
- ❌ **Not microservices** (monolithic application)

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Code Changes                          │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────────┐
│                    CI Workflow (Automatic)                   │
│  ┌──────────┐  ┌─────────┐  ┌───────┐  ┌──────────┐        │
│  │ SwiftLint│  │  Tests  │  │ Build │  │ Security │        │
│  └──────────┘  └─────────┘  └───────┘  └──────────┘        │
│        ↓              ↓           ↓           ↓              │
│        └──────────────┴───────────┴───────────┘              │
│                       ↓                                       │
│            Version Increment (main only)                     │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────────┐
│              Staging Deployment (Automatic)                  │
│                                                              │
│  1. Backup Database                                          │
│  2. Deploy New Version (Blue-Green)                          │
│  3. Health Checks                                            │
│  4. API Tests                                                │
│  5. Extended Monitoring (5 min)                              │
│  6. Auto-Rollback on Failure                                 │
└──────────────────────┬──────────────────────────────────────┘
                       ↓
                  Manual Approval
                       ↓
┌─────────────────────────────────────────────────────────────┐
│            Production Deployment (Manual Trigger)            │
│                                                              │
│  1. Validate Staging Health                                  │
│  2. Version Bump (patch/minor/major)                         │
│  3. Create Git Tag                                           │
│  4. Build & Push Release Image                               │
│  5. Create GitHub Release                                    │
│  6. Backup Database                                          │
│  7. Deploy New Version (Blue-Green)                          │
│  8. Health Checks (stricter)                                 │
│  9. Smoke Tests                                              │
│ 10. Extended Monitoring (15 min)                             │
│ 11. Auto-Rollback on Failure                                 │
└─────────────────────────────────────────────────────────────┘
```

---

## Design Decision 1: Three Separate Workflows

### The Decision

We use **three separate workflow files** instead of one large workflow:

1. [ci.yml](.github/workflows/ci.yml) - Build and test
2. [deploy-staging.yml](.github/workflows/deploy-staging.yml) - Staging deployment
3. [deploy-production.yml](.github/workflows/deploy-production.yml) - Production deployment

### Why?

#### ✅ Advantages

**1. Separation of Concerns**
```yaml
# CI focuses ONLY on validation
- Linting
- Testing
- Building
- Security scanning

# Deployment focuses ONLY on releasing
- Version management
- Database backups
- Health checks
- Rollback
```

**2. Different Trigger Patterns**
- **CI:** Runs on every push and PR
- **Staging:** Runs only on main branch
- **Production:** Manual trigger only

**3. Easier to Understand**
- New team members can understand each workflow independently
- Less cognitive load (each file is ~100-200 lines)

**4. Selective Re-runs**
- Failed staging? Re-run staging workflow only
- Don't need to re-run CI if it already passed

**5. Different Permissions**
- Production workflow can require approvals
- Staging doesn't need approvals

#### ❌ Disadvantages

**1. Duplication**
- Some steps are repeated (checkout, version reading)
- **Mitigation:** Use composite actions

**2. Coordination**
- Workflows must communicate via artifacts/tags
- **Mitigation:** Use git tags and version files

**3. More Files**
- Three files to maintain instead of one
- **Mitigation:** Good documentation and naming

### Alternative Considered: Single Workflow with Jobs

```yaml
# Single workflow (NOT what we chose)
jobs:
  ci:        # Runs always
  staging:   # Runs if: main branch
  production: # Runs if: manual trigger
```

**Why we didn't choose this:**
- Hard to trigger production independently
- Confusing conditional logic throughout
- No way to re-run just staging

---

## Design Decision 2: Parallel vs Sequential Jobs

### The Decision

In the **CI workflow**, most jobs run **in parallel**:

```yaml
jobs:
  lint:           # Parallel
  test:           # Parallel
  security-scan:  # Parallel
  version-increment:  # Sequential (needs: [lint, test])
  build-docker:   # Sequential (needs: version-increment)
```

### Why?

#### Fast Feedback Loop

**Sequential (slow):**
```
Lint (30s) → Test (2m) → Build (5m) → Security (1m) = 8.5 minutes
```

**Parallel (fast):**
```
┌─ Lint (30s)
├─ Test (2m)
├─ Build (5m)
└─ Security (1m)
           ↓
    Max = 5 minutes (not 8.5!)
```

**Result:** ~40% faster feedback

#### Fail Fast

If linting fails (30 seconds), you know immediately. You don't wait for tests (2 minutes) to complete first.

#### Resource Utilization

GitHub Actions provides multiple runners. Use them!

### When Jobs Are Sequential

Some jobs **must** be sequential:

```yaml
version-increment:
  needs: [lint, test]  # Don't increment version if tests fail

build-docker:
  needs: [version-increment]  # Build with new version
```

**Why?**
- No point incrementing version if CI fails
- Docker image needs the updated version file

---

## Design Decision 3: Registry-Based Docker Caching

### The Decision

We use **registry-based caching** instead of GitHub Actions cache:

```yaml
- uses: docker/build-push-action@v5
  with:
    cache-from: |
      type=registry,ref=ghcr.io/repo:builder-cache-${{ deps-hash }}
      type=registry,ref=ghcr.io/repo:builder-cache-latest
```

### Why?

#### Performance Comparison

| Strategy | Cold Build | Dependency Change | Source Change Only |
|----------|------------|-------------------|-------------------|
| No Caching | 5-8 min | 5-8 min | 5-8 min |
| GitHub Actions Cache | 5-8 min | 3-4 min | 2-3 min |
| **Registry Caching** | **5-8 min** | **2-3 min** | **30-90 sec** |

**Why is registry caching faster?**

1. **Persistent across runners:** GitHub Actions cache is tied to the runner. Registry cache is shared globally.

2. **Layer-level caching:** Docker reuses layers that haven't changed.

3. **Parallel pulls:** Multiple layers can be pulled in parallel.

#### How It Works

**1. Cache Key Based on Dependencies**
```bash
# Generate hash of Package.resolved
DEPS_HASH=$(sha256sum Package.resolved | cut -c1-12)
# Example: a3f9d2b8c1e4

# Cache tag: builder-cache-a3f9d2b8c1e4
```

**2. Multi-Stage Dockerfile**
```dockerfile
# Stage 1: Dependencies (rarely changes)
FROM swift:5.9 as dependencies
COPY Package.* ./
RUN swift package resolve

# Stage 2: Build (changes often)
FROM dependencies as builder
COPY Sources ./Sources
RUN swift build -c release
```

**3. Cache Hierarchy**
```yaml
cache-from: |
  # Try exact match (dependencies haven't changed)
  type=registry,ref=...:builder-cache-a3f9d2b8c1e4

  # Fallback to latest (some reuse possible)
  type=registry,ref=...:builder-cache-latest
```

**Result:**
- Change Swift source → 30-90 sec build
- Change dependencies → 2-3 min build
- Cold build → 5-8 min build

### Alternative Considered: GitHub Actions Cache

```yaml
# NOT what we chose
- uses: actions/cache@v4
  with:
    path: /tmp/.buildx-cache
    key: docker-buildx-${{ hashFiles('Dockerfile') }}
```

**Why we didn't choose this:**
- Cache limited to 10GB per repository
- Not shared across workflow runs on different runners
- Slower to restore

---

## Design Decision 4: Composite Actions for Reusability

### The Decision

We created **15 reusable composite actions** in [.github/actions/](.github/actions/):

```
.github/actions/
├── health-check/       # Verify application health
├── api-tests/          # Run API test suite
├── deploy-server/      # SSH deployment
├── rollback-deployment/ # Rollback on failure
├── docker-build-push/  # Build and push images
├── version-increment/  # Semantic versioning
└── ... (9 more)
```

### Why?

#### DRY (Don't Repeat Yourself)

**Without composite actions:**
```yaml
# In ci.yml
- name: Health check
  run: |
    for i in {1..10}; do
      if curl -f $URL/health; then exit 0; fi
      sleep 5
    done
    exit 1

# In deploy-staging.yml (DUPLICATE!)
- name: Health check
  run: |
    for i in {1..10}; do
      if curl -f $URL/health; then exit 0; fi
      sleep 5
    done
    exit 1

# In deploy-production.yml (DUPLICATE!)
- name: Health check
  run: |
    for i in {1..10}; do
      if curl -f $URL/health; then exit 0; fi
      sleep 5
    done
    exit 1
```

**With composite actions:**
```yaml
# In ci.yml
- uses: ./.github/actions/health-check
  with:
    url: http://localhost:8080

# In deploy-staging.yml
- uses: ./.github/actions/health-check
  with:
    url: ${{ vars.STAGING_URL }}

# In deploy-production.yml
- uses: ./.github/actions/health-check
  with:
    url: ${{ vars.PRODUCTION_URL }}
```

**Benefits:**
- ✅ One place to update logic
- ✅ Consistent behavior
- ✅ Easier to test

#### Readability

**Compare:**

**Without actions:**
```yaml
steps:
  - name: Checkout
    uses: actions/checkout@v4
  - name: Setup SSH
    run: |
      mkdir -p ~/.ssh
      echo "$SSH_KEY" > ~/.ssh/id_rsa
      chmod 600 ~/.ssh/id_rsa
  - name: Backup database
    run: ssh user@host "docker exec app cp /data/db /data/backup_$(date +%s).db"
  - name: Pull image
    run: ssh user@host "docker pull myimage:$VERSION"
  - name: Stop old container
    run: ssh user@host "docker stop app || true"
  - name: Start new container
    run: ssh user@host "docker run -d --name app myimage:$VERSION"
  # ... 10 more steps
```

**With actions:**
```yaml
steps:
  - uses: actions/checkout@v4
  - uses: ./.github/actions/deploy-server
    with:
      ssh_host: ${{ secrets.HOST }}
      version: ${{ steps.version.outputs.version }}
```

**Much clearer!**

### Alternative Considered: Inline Everything

**Why we didn't choose this:**
- Too much duplication
- Hard to maintain
- Workflows become 500+ lines

---

## Design Decision 5: Blue-Green Deployment Pattern

### The Decision

We keep the **old container running** until the new one passes health checks:

```
1. Old container (app-v1) is running
2. Start new container (app-v2) on different port temporarily
3. Health check app-v2
4. If healthy:
   - Stop app-v1
   - Rename app-v2 to production name
5. If unhealthy:
   - Stop app-v2
   - Keep app-v1 running
```

### Why?

#### Zero-Downtime Potential

With a load balancer, this enables true zero-downtime deployments:

```
┌─────────────┐
│ Load Balance│
└──────┬──────┘
       │
   ┌───┴────┐
   │        │
┌──▼──┐  ┌──▼──┐
│ v1  │  │ v2  │  ← Both running during transition
└─────┘  └─────┘
   │        │
   │        ↓
   │     Health check passes
   │
   ↓
Removed after v2 is healthy
```

#### Safe Rollback

If the new version fails:
```
1. New version starts
2. Health check fails
3. Stop new version
4. Old version is still running (no downtime!)
```

**Without blue-green:**
```
1. Stop old version (downtime starts)
2. Start new version
3. Health check fails (still down)
4. Scramble to start old version again (extended downtime)
```

#### Implementation in Our Pipeline

```yaml
# deploy-server composite action
- name: Deploy new version
  run: |
    # Start new container with temporary name
    ssh user@host "docker run -d --name app-new myimage:$VERSION"

    # Health check new container
    for i in {1..10}; do
      if ssh user@host "docker exec app-new curl -f localhost:8080/health"; then
        # Success! Swap containers
        ssh user@host "docker stop app"
        ssh user@host "docker rename app-new app"
        exit 0
      fi
      sleep 5
    done

    # Failed! Clean up new container
    ssh user@host "docker stop app-new"
    ssh user@host "docker rm app-new"
    exit 1
```

### Alternative Considered: Stop-Then-Start

```yaml
# NOT what we chose
- Stop old container
- Start new container
- Hope it works
```

**Why we didn't choose this:**
- Guaranteed downtime during deployment
- Harder to rollback
- More stressful deployments

---

## Design Decision 6: Automatic Staging, Manual Production

### The Decision

- **Staging:** Deploys automatically on every push to `main`
- **Production:** Requires manual trigger via GitHub UI

### Why?

#### Staging is for Validation

**Purpose of staging:**
- Catch issues before production
- Test in production-like environment
- Validate every code change

**Why automatic:**
- Every change should be tested in staging
- No reason to deploy to staging manually
- Faster feedback loop

#### Production is Critical

**Purpose of production:**
- Serve real users
- Must be stable
- Requires human judgment

**Why manual:**
- Allows review of staging results
- Time for smoke testing
- Control over deployment timing (not during peak hours)
- Requires conscious decision

#### The Workflow

```
Developer → Push to main → CI runs → Staging deploys (automatic)
                                              ↓
                                     Team reviews staging
                                              ↓
                                     Manual prod trigger
                                              ↓
                                     Production deploys
```

### When to Deviate

**Fully Automatic Production** might be appropriate if:
- You have extensive test coverage (90%+)
- You have feature flags
- You can deploy hundreds of times per day
- You have instant rollback capability
- Your team is very experienced with the pipeline

**Examples:** Netflix, Etsy, Facebook

**For most teams:** Manual production approval is safer.

---

## Design Decision 7: Semantic Versioning with Build Numbers

### The Decision

We use **four-part version numbers:**

```
MAJOR.MINOR.PATCH.BUILD

Example: 0.1.2.15
         │ │ │ └─ Build number (auto-increments every commit)
         │ │ └─── Patch (bug fixes)
         │ └───── Minor (new features, backwards compatible)
         └─────── Major (breaking changes)
```

### Why?

#### Build Numbers for CI

**Problem:** Every commit should have a unique version

**Solution:** Auto-increment build number on every push to `main`

```yaml
# In ci.yml
- name: Increment build number
  if: github.ref == 'refs/heads/main'
  uses: ./.github/actions/version-increment
  with:
    version_type: 'build'
```

**Result:**
- Commit 1 → 0.1.0.1
- Commit 2 → 0.1.0.2
- Commit 3 → 0.1.0.3

**Benefits:**
- Every Docker image has unique tag
- Easy to track which commit is deployed
- Can rollback to any previous build

#### Semantic Versions for Releases

**Problem:** Users need to know if update is breaking

**Solution:** Manual version bumps for releases

```yaml
# In deploy-production.yml
workflow_dispatch:
  inputs:
    version_type:
      type: choice
      options:
        - patch  # 0.1.0.3 → 0.1.1.0
        - minor  # 0.1.0.3 → 0.2.0.0
        - major  # 0.1.0.3 → 1.0.0.0
```

**Benefits:**
- Semantic meaning for releases
- Follows semver standard
- Build number resets to 0 after release

#### Version Tracking

**Stored in multiple places:**
1. **VERSION file** (source of truth)
2. **Git tags** (for GitHub releases)
3. **Docker image tags** (for deployment)
4. **Deployment metadata** (for rollback)

### Alternative Considered: Git SHA Only

```
# NOT what we chose
Version: a3f9d2b (git commit hash)
```

**Why we didn't choose this:**
- No semantic meaning
- Hard for humans to understand
- Can't determine compatibility

### Alternative Considered: Date-Based Versions

```
# NOT what we chose
Version: 2024.11.01.3 (year.month.day.build)
```

**Why we didn't choose this:**
- No semantic meaning (is it breaking?)
- Not industry standard
- Confusing (is 2024.12.01 newer than 2024.11.30?)

---

## Design Decision 8: Health Checks and Automatic Rollback

### The Decision

Every deployment includes:
1. **Health check endpoint:** `/health` returns `{"status":"ok"}`
2. **Automated verification:** 10-30 retries with backoff
3. **Automatic rollback:** If health check fails, revert to previous version

### Why?

#### Catch Deployment Failures Early

**Common failures detected:**
- Application crashes on startup
- Database connection fails
- Configuration error
- Port already in use
- Dependency missing

**Without health checks:**
```
Deploy → App crashes → Users see errors → Panic → Manual rollback
(5-10 minutes of downtime)
```

**With health checks:**
```
Deploy → Health check fails → Auto rollback → Old version still running
(0 downtime)
```

#### Implementation

**Application code:**
```swift
// StatusController.swift
func health(request: Request, context: some RequestContext) async throws -> HTTPResponse.Status {
    return .ok
}
```

**Deployment workflow:**
```yaml
- name: Deploy new version
  uses: ./.github/actions/deploy-server
  # ... deployment steps ...

- name: Health check
  uses: ./.github/actions/health-check
  with:
    url: https://production.com
    max_retries: 30
    retry_interval: 3

- name: Rollback on failure
  if: failure()
  uses: ./.github/actions/rollback-deployment
```

#### Retry Logic

```bash
for i in {1..30}; do
  if curl -f $URL/health; then
    echo "Health check passed"
    exit 0
  fi
  echo "Retry $i/30..."
  sleep 3
done

echo "Health check failed after 30 retries"
exit 1
```

**Why 30 retries × 3 seconds = 90 seconds?**
- Swift application startup: ~10-20 seconds
- Docker container startup: ~5-10 seconds
- Network latency: ~1-5 seconds
- Buffer for slower servers: ~60 seconds
- **Total:** 90 seconds is generous but not excessive

### Alternative Considered: Manual Verification

```
# NOT what we chose
1. Deploy
2. Manually test the app
3. If broken, manually rollback
```

**Why we didn't choose this:**
- Slow (requires human)
- Error-prone (humans forget things)
- Not suitable for automatic staging
- Creates downtime if you're slow to notice

---

## Design Decision 9: Extended Post-Deployment Monitoring

### The Decision

After deployment succeeds, we continue monitoring:

- **Staging:** 5 minutes
- **Production:** 15 minutes

```yaml
- name: Monitor for 15 minutes
  uses: ./.github/actions/extended-monitoring
  with:
    duration_minutes: '15'
    check_interval_seconds: '30'
    max_consecutive_failures: '3'
```

### Why?

#### Catch Delayed Failures

Some failures don't appear immediately:

**Examples:**
- **Memory leak:** App crashes after 10 minutes
- **Database connection pool exhaustion:** Fails after 50 requests
- **Race condition:** Occurs rarely but eventually
- **Timeout issues:** Only under load

**Without extended monitoring:**
```
Deploy → Health check passes → Declare success → App crashes 10 min later
```

**With extended monitoring:**
```
Deploy → Health check passes → Monitor for 15 min → Crash detected → Auto rollback
```

#### Implementation

```yaml
# extended-monitoring composite action
inputs:
  duration_minutes: '15'
  check_interval_seconds: '30'
  max_consecutive_failures: '3'

runs:
  steps:
    - run: |
        END_TIME=$((CURRENT_TIME + DURATION_MINUTES * 60))
        CONSECUTIVE_FAILURES=0

        while [ $CURRENT_TIME -lt $END_TIME ]; do
          if curl -f $URL/health; then
            echo "✓ Health check passed"
            CONSECUTIVE_FAILURES=0
          else
            echo "✗ Health check failed"
            CONSECUTIVE_FAILURES=$((CONSECUTIVE_FAILURES + 1))

            if [ $CONSECUTIVE_FAILURES -ge $MAX_CONSECUTIVE_FAILURES ]; then
              echo "❌ Too many failures. Deployment unstable."
              exit 1
            fi
          fi

          sleep $CHECK_INTERVAL_SECONDS
          CURRENT_TIME=$(date +%s)
        done
```

#### Why Different Durations?

**Staging (5 minutes):**
- Lower risk environment
- Want faster feedback
- Acceptable to have occasional false negatives

**Production (15 minutes):**
- Critical environment
- Worth the extra time
- Better safe than sorry

### Alternative Considered: No Extended Monitoring

```
# NOT what we chose
Deploy → Health check → Done
```

**Why we didn't choose this:**
- Misses delayed failures
- False sense of security
- More incidents reach users

---

## Design Decision 10: Database Backup Before Deployment

### The Decision

**Every deployment** starts with a database backup:

```yaml
- name: Backup database
  run: |
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    ssh user@host "docker exec app cp /data/todos.db /data/backup_${TIMESTAMP}.db"
```

### Why?

#### Data Loss Prevention

**Scenarios where backup is critical:**

1. **Migration goes wrong:**
   ```
   Deploy → Migration adds column → App crashes → Rollback
   Problem: Database has new column, old code doesn't expect it
   Solution: Restore database backup
   ```

2. **Bug corrupts data:**
   ```
   Deploy → Bug deletes records → Noticed 10 minutes later
   Solution: Restore backup from before deployment
   ```

3. **Incompatible schema change:**
   ```
   Deploy → Schema change breaks old code → Rollback app
   Problem: Old code can't read new schema
   Solution: Restore old schema from backup
   ```

#### Backup Strategy

**Location:** Same server, different directory
```
/data/
  todos.db                           # Active database
  backup_20241101_143052.db          # Backup from 2:30 PM
  backup_20241101_091234.db          # Backup from 9:12 AM
  backup_20241031_183421.db          # Backup from yesterday
```

**Retention:**
- Keep last 10 backups (manual cleanup script)
- For production, consider off-server backups

#### Rollback Procedure

**If deployment fails:**

```yaml
- name: Rollback deployment
  if: failure()
  uses: ./.github/actions/rollback-deployment
  # This:
  # 1. Stops new container
  # 2. Starts old container
  # 3. Restores database from backup
  # 4. Verifies health
```

**Manual rollback:**

```bash
# Using the rollback script
./scripts/rollback.sh
# Prompts for:
# 1. Which container to restore
# 2. Which database backup to use
```

### Alternative Considered: No Backups

**Why we didn't choose this:**
- Unacceptable risk of data loss
- No way to undo database migrations
- Stress during incidents

### Alternative Considered: Separate Backup Job

```yaml
# Run backup on schedule, not before deployment
schedule:
  - cron: '0 */6 * * *'  # Every 6 hours
```

**Why we didn't choose this:**
- Backup might be hours old
- Don't know exact state before deployment
- Harder to correlate backup with deployment

---

## Trade-offs and Alternatives

Every design decision involves trade-offs. Here's what we sacrificed:

### Complexity vs Simplicity

**Our Choice:** More complex pipeline with safety features

**Trade-off:** Harder to understand for beginners

**Simpler Alternative:**
```yaml
# Simple deployment
on: push
jobs:
  deploy:
    steps:
      - run: ssh user@host "docker pull myimage && docker restart app"
```

**Why we chose complexity:**
- Safety is more important than simplicity
- Good documentation mitigates complexity
- Modular design makes it manageable

---

### Speed vs Safety

**Our Choice:** Slower deployments with extensive checks

**Trade-off:**
- Staging deployment: ~5-10 minutes
- Production deployment: ~20-30 minutes

**Faster Alternative:**
- Skip health checks
- Skip monitoring
- No backups
- **Result:** 2-3 minutes

**Why we chose safety:**
- Catching bugs in staging saves hours of incident response
- 10 minutes is acceptable for most applications
- Can optimize later if needed

---

### Automatic vs Manual

**Our Choice:** Manual production deployments

**Trade-off:** Can't deploy instantly

**Fully Automatic Alternative:**
```yaml
# Auto-deploy to production
on:
  push:
    branches: [main]
jobs:
  deploy-production: ...
```

**Why we chose manual:**
- Humans provide last line of defense
- Allows review of staging results
- Reduces pressure on CI/CD reliability
- Suitable for most teams

---

## When to Deviate from This Pattern

This pipeline is **not one-size-fits-all**. Deviate when:

### 1. You Have a Microservices Architecture

**This pipeline:** Single application

**Your need:** Deploy multiple services independently

**Adaptation:**
- Use matrix strategy to deploy multiple services
- Separate workflows per service
- Orchestration layer (Kubernetes)

---

### 2. You Need Zero-Downtime Deployments

**This pipeline:** Brief downtime acceptable

**Your need:** Absolutely no downtime

**Adaptation:**
- Add load balancer
- Use proper blue-green with traffic switching
- Implement canary deployments
- Consider Kubernetes for rolling updates

---

### 3. You Deploy Hundreds of Times Per Day

**This pipeline:** Manual production deployments

**Your need:** Fully automated pipeline

**Adaptation:**
- Auto-deploy to production from main
- Implement feature flags
- Add canary/progressive rollout
- Invest heavily in monitoring

---

### 4. You Have Compliance Requirements

**This pipeline:** Basic approval process

**Your need:** Audit trails, multiple approvals

**Adaptation:**
- Add approval gates at multiple stages
- Integrate with ticketing system (Jira)
- Generate deployment reports
- Implement separation of duties

---

### 5. You're Using Platform-as-a-Service

**This pipeline:** Deploys to your own servers

**Your need:** Deploy to Heroku, Railway, Render, etc.

**Adaptation:**
- Replace SSH deployment with platform CLI
- Platform may handle health checks
- Less control over deployment process

---

## Summary

This pipeline balances **safety, speed, and simplicity** for typical Swift server deployments:

| Aspect | Choice | Rationale |
|--------|--------|-----------|
| **Workflow Structure** | 3 separate workflows | Separation of concerns, clarity |
| **Job Execution** | Parallel where possible | Faster feedback (5 min vs 8 min) |
| **Docker Caching** | Registry-based | 5-10× faster incremental builds |
| **Code Reuse** | Composite actions | DRY, maintainability |
| **Deployment Pattern** | Blue-green | Safe rollback, zero-downtime potential |
| **Automation Level** | Auto staging, manual prod | Balance speed and safety |
| **Versioning** | Semantic + build numbers | Unique IDs + meaningful versions |
| **Health Checks** | Automatic with retries | Catch failures early |
| **Monitoring** | Extended (5/15 min) | Catch delayed failures |
| **Backups** | Before every deployment | Data loss prevention |

---

## Next Steps

Now that you understand the **why**, explore the **how**:

1. **See it in action:** [FIRST_DEPLOYMENT.md](FIRST_DEPLOYMENT.md)
2. **Understand GitHub Actions:** [GITHUB_ACTIONS_PRIMER.md](GITHUB_ACTIONS_PRIMER.md)
3. **Read the implementation:** [.github/workflows/](.github/workflows/)
4. **Study the actions:** [.github/actions/](.github/actions/)

**Remember:** These are architectural decisions, not absolute truths. Adapt them to your needs!
