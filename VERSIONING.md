# Automated Versioning System

This project uses an automated semantic versioning system with automatic build number tracking.

## Version Format

**Format:** `MAJOR.MINOR.PATCH.BUILD`

Example: `1.2.3.45`

- **MAJOR** - Incompatible API changes (breaking changes)
- **MINOR** - New functionality (backwards compatible)
- **PATCH** - Bug fixes (backwards compatible)
- **BUILD** - Automatic build number (auto-incremented on every commit to main)

## How It Works

### Automatic Build Number Increment

**Every commit to the `main` branch automatically increments the build number.**

Example flow:
```
Initial: 0.1.0.1
Commit to main → 0.1.0.2
Commit to main → 0.1.0.3
Commit to main → 0.1.0.4
```

The CI pipeline automatically:
1. Increments the build number
2. Commits the updated `VERSION` file back to the repository
3. Tags the Docker image with the new version
4. Deploys to staging with the new version

### Production Releases

Production releases are triggered manually and allow you to select the type of version bump:

#### Major Release (Breaking Changes)
- **When to use:** Incompatible API changes, major refactoring
- **Example:** `1.5.3.42 → 2.0.0.1`
- **What happens:** Major increments, minor/patch/build reset to 0/0/1

#### Minor Release (New Features)
- **When to use:** New features, backwards-compatible functionality
- **Example:** `1.5.3.42 → 1.6.0.1`
- **What happens:** Minor increments, patch/build reset to 0/1

#### Patch Release (Bug Fixes)
- **When to use:** Bug fixes, small improvements
- **Example:** `1.5.3.42 → 1.5.4.1`
- **What happens:** Patch increments, build resets to 1

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
3. ✅ VERSION file updated and committed
4. ✅ Docker image built and tagged with version
5. ✅ Deployed to staging automatically

### Production Deployment Workflow

#### Option 1: Via GitHub UI (Recommended)

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
3. ✅ Staging health validated
4. ✅ Production deployment executed
5. ✅ GitHub Release created with release notes
6. ✅ 15-minute monitoring period
7. ✅ Auto-rollback on any failure

#### Option 2: Via Command Line (Manual)

If you prefer manual version management:

```bash
# Show current version
./scripts/version-manager.sh show

# Increment for patch release
./scripts/version-manager.sh patch

# Commit and push
git add VERSION
git commit -m "chore: bump version for patch release"
git push origin main

# Then trigger production deployment via GitHub UI
```

## Version Manager Script

The `scripts/version-manager.sh` script provides manual version control:

### Commands

```bash
# Display current version info
./scripts/version-manager.sh show

# Increment build number
./scripts/version-manager.sh build

# Increment patch version (bugfix)
./scripts/version-manager.sh patch
# or
./scripts/version-manager.sh bugfix

# Increment minor version (feature)
./scripts/version-manager.sh minor
# or
./scripts/version-manager.sh feature

# Increment major version (breaking)
./scripts/version-manager.sh major
# or
./scripts/version-manager.sh breaking

# Get current version (output only)
./scripts/version-manager.sh get

# Create git tag for current version
./scripts/version-manager.sh tag "Optional release notes"
```

### Examples

```bash
# Show version information
$ ./scripts/version-manager.sh show
========================================
Current Version Information
========================================
Full Version: 1.2.3.45
Major:        1
Minor:        2
Patch:        3
Build:        45
========================================

# Increment build number
$ ./scripts/version-manager.sh build
[SUCCESS] Build number incremented
1.2.3.46

# Create a patch release
$ ./scripts/version-manager.sh patch
[SUCCESS] Patch version incremented (bugfix)
1.2.4.1

# Create a minor release
$ ./scripts/version-manager.sh minor
[SUCCESS] Minor version incremented (new feature)
1.3.0.1

# Create a major release
$ ./scripts/version-manager.sh major
[SUCCESS] Major version incremented (breaking change)
2.0.0.1
```

## Version Tracking

The current version is stored in the `VERSION` file at the project root:

```bash
# Check current version
cat VERSION

# Example output
1.2.3.45
```

This file is:
- ✅ Automatically updated by CI on every commit to main
- ✅ Automatically committed back to the repository
- ✅ Used to tag Docker images
- ✅ Displayed in deployment logs
- ✅ Stored on servers in `/opt/todos-app/current-version.txt`

## Docker Image Tags

Every build creates Docker images with multiple tags:

### Staging Builds
```
ghcr.io/yourname/hummingbirdpublication:0.1.0.5
ghcr.io/yourname/hummingbirdpublication:staging
ghcr.io/yourname/hummingbirdpublication:staging-abc123  (git SHA)
```

### Production Releases
```
ghcr.io/yourname/hummingbirdpublication:1.2.3.1
ghcr.io/yourname/hummingbirdpublication:production
ghcr.io/yourname/hummingbirdpublication:latest
```

## Version History

All version changes are tracked through:

1. **Git commits** - Version file changes are committed
2. **Git tags** - Production releases are tagged (e.g., `v1.2.3.1`)
3. **GitHub Releases** - Production deployments create releases
4. **Docker image tags** - All builds are tagged with version numbers

### View Version History

```bash
# View all version-related commits
git log --oneline --grep="version"

# View all release tags
git tag -l "v*"

# View specific release
git show v1.2.3.1
```

## CI/CD Integration

### CI Pipeline (Automatic on Push to Main)

```yaml
1. Run tests
2. Increment build number (0.1.0.5 → 0.1.0.6)
3. Commit VERSION file
4. Build Docker image with version tag
5. Push to container registry
6. Deploy to staging
```

### Staging Deployment (Automatic on Main)

```yaml
1. Read current version from VERSION file
2. Use that version for deployment
3. Tag Docker image with version
4. Deploy to staging server
5. Run health checks and API tests
```

### Production Deployment (Manual Trigger)

```yaml
1. User selects version type (major/minor/patch)
2. Version bumped and committed
3. Git tag created (e.g., v1.2.3.1)
4. Validate staging health
5. Build and deploy to production
6. Create GitHub Release
7. Monitor for 15 minutes
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

**Problem:** VERSION file not updated after commit to main

**Solution:**
- Check GitHub Actions workflow logs
- Ensure GITHUB_TOKEN has write permissions
- Verify workflow has `[skip ci]` in commit message to prevent loops

### Version Conflicts

**Problem:** VERSION file has merge conflicts

**Solution:**
```bash
# Accept the higher version number
git checkout --theirs VERSION
git add VERSION
git commit -m "chore: resolve version conflict"
```

### Manual Version Reset

**Problem:** Need to reset version for testing

**Solution:**
```bash
# Edit VERSION file manually
echo "0.1.0.1" > VERSION
git add VERSION
git commit -m "chore: reset version for testing"
git push origin main
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

## FAQ

**Q: What if I push multiple commits at once?**
A: The build number increments once per push to main, not per commit.

**Q: Can I manually set a specific version?**
A: Yes, edit the VERSION file manually, commit, and push. Not recommended for normal workflow.

**Q: What happens if production deployment fails?**
A: Automatic rollback occurs. The version number is already committed, but deployment reverts to previous container.

**Q: How do I see what version is in each environment?**
A:
- Staging: Check GitHub Actions logs or `curl http://staging-url/health`
- Production: Check GitHub Releases or `curl http://production-url/health`
- Server: `cat /opt/todos-app/current-version.txt`

**Q: Can I skip the build number increment?**
A: Add `[skip ci]` to your commit message to skip the entire CI pipeline.

**Q: What version should I start with?**
A: The project starts at `0.1.0.1`. First production release could be `1.0.0.1`.

---

## Quick Reference

| Action | Command | Result |
|--------|---------|--------|
| Commit to main | `git push origin main` | Build number auto-increments |
| Deploy patch to prod | GitHub UI → patch | `1.0.0.5 → 1.0.1.1` |
| Deploy minor to prod | GitHub UI → minor | `1.0.5.3 → 1.1.0.1` |
| Deploy major to prod | GitHub UI → major | `1.5.3.2 → 2.0.0.1` |
| Check version | `cat VERSION` | Shows current version |
| Manual increment | `./scripts/version-manager.sh [type]` | Updates VERSION file |

---

**Version tracking simplified. Focus on building, not versioning.** 🚀
