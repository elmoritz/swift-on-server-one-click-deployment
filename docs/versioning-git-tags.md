---
layout: default
title: Git Tag-Based Versioning System
nav_order: 9
description: "Automated semantic versioning using git tags"
permalink: /versioning
---

# Git Tag-Based Versioning System

This project uses an automated semantic versioning system based on **git tags** as the source of truth.

## Version Format

**Format:** `MAJOR.MINOR.PATCH.BUILD`

Example: `1.2.3.45`

- **MAJOR** - Incompatible API changes (breaking changes)
- **MINOR** - New functionality (backwards compatible)
- **PATCH** - Bug fixes (backwards compatible)
- **BUILD** - Automatic build number (auto-incremented on every commit to main)

## How It Works

### Automatic Build Number Increment

**Every commit to the `main` branch automatically increments the build number and creates a git tag.**

Example flow:
```
Initial: 0.1.0.1
Commit to main → 0.1.0.2 (creates git tag 0.1.0.2)
Commit to main → 0.1.0.3 (creates git tag 0.1.0.3)
Commit to main → 0.1.0.4 (creates git tag 0.1.0.4)
```

The CI pipeline automatically:
1. Reads the latest version from git tags
2. Increments the build number
3. Creates and pushes a new git tag
4. Tags the Docker image with the new version
5. Deploys to staging with the new version

### Production Releases

Production releases are triggered manually and allow you to select the type of version bump:

#### Major Release (Breaking Changes)
- **When to use:** Incompatible API changes, major refactoring
- **Example:** `1.5.3.42 → 2.0.0.1`
- **What happens:** Major increments, minor/patch/build reset to 0/0/1
- **Git tag created:** `v2.0.0.1`

#### Minor Release (New Features)
- **When to use:** New features, backwards-compatible functionality
- **Example:** `1.5.3.42 → 1.6.0.1`
- **What happens:** Minor increments, patch/build reset to 0/1
- **Git tag created:** `v1.6.0.1`

#### Patch Release (Bug Fixes)
- **When to use:** Bug fixes, small improvements
- **Example:** `1.5.3.42 → 1.5.4.1`
- **What happens:** Patch increments, build resets to 1
- **Git tag created:** `v1.5.4.1`

## Workflow Examples

### Daily Development Workflow

```bash
# Make your changes
git add .
git commit -m "feat: add new feature"
git push origin main
```

**What happens automatically:**
1. ✅ CI runs tests
2. ✅ Build number auto-increments (e.g., 0.1.0.5 → 0.1.0.6)
3. ✅ Git tag created and pushed (e.g., `0.1.0.6`)
4. ✅ Docker image built and tagged with version
5. ✅ Deployed to staging automatically

### Production Deployment Workflow

#### Via GitHub UI (Recommended)

1. Go to your GitHub repository
2. Click **Actions** tab
3. Select **Deploy to Production** workflow
4. Click **Run workflow** button
5. Select the version type:
   - **major** - Breaking changes (1.0.0 → 2.0.0)
   - **minor** - New features (1.0.0 → 1.1.0)
   - **patch** - Bug fixes (1.0.0 → 1.0.1)
6. Optionally add release notes
7. Click **Run workflow**

**What happens automatically:**
1. ✅ Version is bumped according to type selected
2. ✅ Git tag created (e.g., `v1.2.0.1`)
3. ✅ Git tag pushed to repository
4. ✅ Staging health validated
5. ✅ Production deployment executed
6. ✅ GitHub Release created with release notes
7. ✅ 15-minute monitoring period
8. ✅ Auto-rollback on any failure

## Version Manager Script

The `scripts/version-manager.swift` script provides manual version control:

### Commands

```bash
# Display current version info from git tags
./scripts/version-manager.swift show

# Calculate next build number (doesn't create tag)
./scripts/version-manager.swift build

# Calculate next patch version (doesn't create tag)
./scripts/version-manager.swift patch

# Calculate next minor version (doesn't create tag)
./scripts/version-manager.swift minor

# Calculate next major version (doesn't create tag)
./scripts/version-manager.swift major

# Get current version from git tags (output only)
./scripts/version-manager.swift get

# Create git tag for a specific version
./scripts/version-manager.swift tag 1.2.3.4 "Release notes here"
```

### Examples

```bash
# Show version information
$ ./scripts/version-manager.swift show
========================================
Current Version Information
========================================
Full Version: 1.2.3.45
Major:        1
Minor:        2
Patch:        3
Build:        45
========================================

Version source: Git tags
========================================

# Calculate next build number
$ ./scripts/version-manager.swift build
✅ [SUCCESS] Next build version calculated
1.2.3.46

# Calculate next patch version
$ ./scripts/version-manager.swift patch
✅ [SUCCESS] Next patch version calculated
1.2.4.1

# Create a specific git tag
$ ./scripts/version-manager.swift tag 1.2.4.1 "Bug fix release"
✅ [SUCCESS] Created tag: 1.2.4.1
ℹ️  [INFO] To push the tag, run: git push origin 1.2.4.1
```

## Version Tracking

The current version is stored as **git tags** in the repository:

```bash
# Check current version from git tags
./scripts/version-manager.swift get

# Example output
1.2.3.45

# View all version tags
git tag --sort=-creatordate | head -10

# View version tags matching pattern
git tag -l "[0-9]*.[0-9]*.[0-9]*.[0-9]*"
```

Git tags provide:
- ✅ Automatically created by CI on every commit to main
- ✅ Pushed to the remote repository
- ✅ Used to tag Docker images
- ✅ Displayed in deployment logs
- ✅ Immutable and traceable in git history
- ✅ No merge conflicts (unlike VERSION files)
- ✅ Integrated with GitHub Releases

## Docker Image Tags

Every build creates Docker images with multiple tags:

### Staging Builds
```
ghcr.io/yourname/hummingbirdpublication:0.1.0.5
ghcr.io/yourname/hummingbirdpublication:latest
```

### Production Releases
```
ghcr.io/yourname/hummingbirdpublication:1.2.3.1
ghcr.io/yourname/hummingbirdpublication:production
ghcr.io/yourname/hummingbirdpublication:latest
```

## Best Practices

### When to Use Each Version Type

**MAJOR (Breaking Changes)**
- API changes that break backwards compatibility
- Major refactoring or redesign
- Removal of deprecated features
- Changes to database schema that require migration

**MINOR (New Features)**
- New API endpoints
- New features that don't break existing functionality
- Significant enhancements
- New optional parameters

**PATCH (Bug Fixes)**
- Bug fixes
- Performance improvements
- Security patches
- Documentation updates
- Minor tweaks

**BUILD (Automatic)**
- Every commit to main
- Development builds
- Continuous integration builds

### Recommended Workflow

1. **Develop on feature branches**
   ```bash
   git checkout -b feature/new-feature
   # Make changes
   git commit -m "feat: add new feature"
   git push origin feature/new-feature
   ```

2. **Merge to main via PR**
   - CI runs tests
   - Build number auto-increments
   - Git tag created
   - Deploys to staging

3. **Test on staging**
   - Verify functionality
   - Run manual tests
   - Check logs

4. **Deploy to production**
   - GitHub Actions → Deploy to Production
   - Select appropriate version type
   - Add release notes
   - Approve deployment

## Troubleshooting

### Build Number Not Incrementing

**Problem:** Git tag not created after commit to main

**Solution:**
- Check GitHub Actions workflow logs
- Ensure GITHUB_TOKEN has write permissions
- Verify workflow has proper permissions to create and push tags
- Check that `fetch-depth: 0` is set in checkout action to get full git history

### Version Tag Conflicts

**Problem:** Tag already exists with the same version

**Solution:**
```bash
# View existing tags
git tag --sort=-creatordate | head -10

# Delete local tag if needed (use with caution)
git tag -d 1.2.3.4

# Delete remote tag if needed (use with extreme caution)
git push origin :refs/tags/1.2.3.4
```

### Check Deployed Version

**On Staging:**
```bash
ssh user@staging-server
cat /opt/todos-app/current-version.txt
```

**On Production:**
```bash
ssh user@production-server
cat /opt/todos-app/current-version.txt
```

**From Git:**
```bash
# Check latest version tag
git tag --sort=-creatordate | head -1

# Check all production releases (with v prefix)
git tag -l "v*" --sort=-creatordate | head -10
```

## FAQ

**Q: What if I push multiple commits at once?**
A: The build number increments once per push to main, not per commit.

**Q: Can I manually set a specific version?**
A: Yes, create a git tag manually:
```bash
git tag -a 1.2.3.4 -m "Release 1.2.3.4"
git push origin 1.2.3.4
```
Not recommended for normal workflow - use the production deployment workflow instead.

**Q: What happens if production deployment fails?**
A: Automatic rollback occurs. The git tag is already created, but deployment reverts to previous container.

**Q: How do I see what version is in each environment?**
A:
- Staging: Check GitHub Actions logs or `curl http://staging-url/health`
- Production: Check GitHub Releases or `curl http://production-url/health`
- Server: `cat /opt/todos-app/current-version.txt`
- Git: `git tag --sort=-creatordate | head -1`

**Q: Can I skip the build number increment?**
A: Add `[skip ci]` to your commit message to skip the entire CI pipeline.

**Q: What version should I start with?**
A: The project starts at `0.1.0.1`. First production release could be `1.0.0.1`.

**Q: Why use git tags instead of a VERSION file?**
A: Git tags provide:
- No merge conflicts
- Immutable version history
- Better integration with GitHub Releases
- No need to commit version changes
- Works with monorepos and multiple projects

---

## Quick Reference

| Action | Command | Result |
|--------|---------|--------|
| Commit to main | `git push origin main` | Build number auto-increments, creates git tag |
| Deploy patch to prod | GitHub UI → patch | `1.0.0.5 → 1.0.1.1`, creates git tag `v1.0.1.1` |
| Deploy minor to prod | GitHub UI → minor | `1.0.5.3 → 1.1.0.1`, creates git tag `v1.1.0.1` |
| Deploy major to prod | GitHub UI → major | `1.5.3.2 → 2.0.0.1`, creates git tag `v2.0.0.1` |
| Check version | `./scripts/version-manager.swift get` | Shows current version from git tags |
| Calculate next version | `./scripts/version-manager.swift [type]` | Calculates next version (doesn't create tag) |
| View version history | `git tag --sort=-creatordate \| head -10` | Shows last 10 version tags |

---

**Git tag-based versioning: Simple, reliable, and conflict-free.**
