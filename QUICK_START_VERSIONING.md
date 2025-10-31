# Quick Start: Automated Versioning System

## Overview

Your pipeline now features **fully automated semantic versioning** with build number tracking.

**Version Format:** `MAJOR.MINOR.PATCH.BUILD`

Example: `1.2.3.45`

---

## How It Works

### Every Commit to Main = Build Number Increment

```
You commit → CI runs → Build number auto-increments → Deploys to staging
```

**Example:**
```
Before: 0.1.0.5
Commit to main
After:  0.1.0.6 (automatically)
```

### Production Deployment = Select Version Type

When you're ready for production, you select the type of release:

- **Major** - Breaking changes (1.0.0 → 2.0.0)
- **Minor** - New features (1.0.0 → 1.1.0)
- **Patch** - Bug fixes (1.0.0 → 1.0.1)

---

## Daily Workflow

### 1. Develop and Commit

```bash
# Make your changes
git add .
git commit -m "feat: add new todo filter"
git push origin main
```

**What happens automatically:**
- ✅ Tests run
- ✅ Build number increments (e.g., 0.1.0.5 → 0.1.0.6)
- ✅ Docker image tagged with version
- ✅ Deployed to staging
- ✅ API tests run on staging

**You don't need to do anything with versioning!**

---

### 2. Deploy to Production (When Ready)

**Steps:**

1. Go to your GitHub repository
2. Click **Actions** tab
3. Select **Deploy to Production** workflow
4. Click **Run workflow**
5. Select version type:
   - **patch** - For bug fixes (most common)
   - **minor** - For new features
   - **major** - For breaking changes
6. Optional: Add release notes
7. Click **Run workflow** (green button)

**What happens automatically:**
- ✅ Version bumped based on your selection
- ✅ Git tag created (e.g., `v1.2.3.1`)
- ✅ Staging validated
- ✅ Production deployment
- ✅ GitHub Release created
- ✅ 15-minute monitoring
- ✅ Auto-rollback if anything fails

---

## Examples

### Scenario 1: Bug Fix

You fixed a critical bug:

```bash
git commit -m "fix: resolve login issue"
git push origin main
```

**Result:** Build increments `0.1.0.5 → 0.1.0.6`, deploys to staging

**When ready for production:**
- Select **patch** in GitHub Actions
- Version becomes `0.1.1.1`
- Deployed to production

---

### Scenario 2: New Feature

You added a new feature:

```bash
git commit -m "feat: add todo sorting"
git push origin main
```

**Result:** Build increments `1.2.3.10 → 1.2.3.11`, deploys to staging

**When ready for production:**
- Select **minor** in GitHub Actions
- Version becomes `1.3.0.1`
- Deployed to production

---

### Scenario 3: Breaking Change

You redesigned the API:

```bash
git commit -m "feat!: redesign API structure"
git push origin main
```

**Result:** Build increments `1.5.2.8 → 1.5.2.9`, deploys to staging

**When ready for production:**
- Select **major** in GitHub Actions
- Version becomes `2.0.0.1`
- Deployed to production

---

## Multiple Commits Before Production

You can make multiple commits to main before deploying to production:

```bash
# First commit
git commit -m "feat: add feature A"
git push origin main
# → Version: 0.1.0.5

# Second commit
git commit -m "fix: bug in feature A"
git push origin main
# → Version: 0.1.0.6

# Third commit
git commit -m "docs: update README"
git push origin main
# → Version: 0.1.0.7
```

All three versions (0.1.0.5, 0.1.0.6, 0.1.0.7) are deployed to staging.

**When ready for production:**
- Select version type (e.g., **minor** for the new feature)
- Version becomes `0.2.0.1`
- Production gets version `0.2.0.1`

---

## Checking Current Version

### Local
```bash
cat VERSION
```

### Staging
```bash
ssh user@staging-server
cat /opt/todos-app/current-version.txt
```

### Production
```bash
ssh user@production-server
cat /opt/todos-app/current-version.txt
```

### GitHub
- Check the `VERSION` file in your repository
- Check GitHub Releases for production versions
- Check GitHub Actions logs

---

## Version History

View all releases:
```bash
git tag -l "v*"
```

View specific release:
```bash
git show v1.2.3.1
```

GitHub Releases page shows all production deployments with release notes.

---

## Important Notes

### Build Number Always Increments
Every commit to `main` increments the build number. This is automatic and cannot be disabled.

### Production Versions Reset Build Number
When you bump patch/minor/major for production, the build number resets to 1:

```
Staging: 1.2.3.42
Production (patch): 1.2.4.1  ← Build resets to 1
```

### Commit Messages with [skip ci]
If you want to commit without triggering CI:

```bash
git commit -m "docs: update README [skip ci]"
```

This skips the entire pipeline (no build increment, no deployment).

---

## Troubleshooting

**Q: Version didn't increment after commit**

A: Check GitHub Actions logs. Ensure the commit wasn't marked with `[skip ci]`.

---

**Q: I want to deploy to production but forgot what version we're on**

A:
```bash
cat VERSION  # Shows current version
git tag -l "v*" | tail -5  # Shows last 5 production releases
```

---

**Q: Can I manually set a version?**

A: Yes, but not recommended. Edit the `VERSION` file:
```bash
echo "1.0.0.1" > VERSION
git add VERSION
git commit -m "chore: set version to 1.0.0.1"
git push origin main
```

---

## Summary

| Action | How | Result |
|--------|-----|--------|
| Commit to main | `git push origin main` | Build +1, auto-deploy to staging |
| Deploy patch | GitHub UI → patch | Patch +1, build reset to 1 |
| Deploy minor | GitHub UI → minor | Minor +1, patch/build reset |
| Deploy major | GitHub UI → major | Major +1, others reset |
| Check version | `cat VERSION` | Shows current version |

---

## Complete Example Flow

```
Day 1: Initial development
├─ Commit 1 → 0.1.0.1 (staging)
├─ Commit 2 → 0.1.0.2 (staging)
└─ Commit 3 → 0.1.0.3 (staging)
   └─ Deploy "minor" → 0.2.0.1 (production) ✨

Day 2: Bug fix
├─ Commit 4 → 0.2.0.2 (staging)
└─ Deploy "patch" → 0.2.1.1 (production) 🐛

Day 3: New feature
├─ Commit 5 → 0.2.1.2 (staging)
├─ Commit 6 → 0.2.1.3 (staging)
└─ Deploy "minor" → 0.3.0.1 (production) ✨

Day 4: Breaking change
├─ Commit 7 → 0.3.0.2 (staging)
└─ Deploy "major" → 1.0.0.1 (production) 💥
```

---

**You're all set! Focus on coding, versioning is automatic.** 🚀

For more details, see [VERSIONING.md](VERSIONING.md)
