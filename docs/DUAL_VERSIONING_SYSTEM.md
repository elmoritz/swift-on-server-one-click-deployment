# Dual Versioning System

This repository implements a sophisticated dual versioning system that separates staging and production releases.

## Version Formats

### Staging Versions (4-part)
**Format:** `MAJOR.MINOR.PATCH.BUILD`

Example: `0.1.2.45`

- **MAJOR** - Incompatible API changes
- **MINOR** - New functionality (backwards compatible)
- **PATCH** - Bug fixes (backwards compatible)
- **BUILD** - Auto-incremented on every commit to main

**Git Tag:** No prefix (e.g., `0.1.2.45`)

### Production Versions (3-part)
**Format:** `MAJOR.MINOR.PATCH`

Example: `1.2.3`

- **MAJOR** - Incompatible API changes
- **MINOR** - New functionality (backwards compatible)
- **PATCH** - Bug fixes (backwards compatible)

**Git Tag:** `v` prefix (e.g., `v1.2.3`)

## How It Works

### Staging Flow (Automatic)

Every commit to `main` triggers:

```
1. CI runs tests
2. Build number increments (0.1.0.1 → 0.1.0.2)
3. Git tag created without prefix (0.1.0.2)
4. Version hardcoded into app (AppVersion.swift)
5. Docker image built and tagged
6. Deployed to staging automatically
```

**Example:**
```bash
# Developer workflow
git commit -m "feat: add new feature"
git push origin main

# CI automatically creates tag: 0.1.0.42
# App version endpoint returns: {"version": "0.1.0.42", "environment": "staging"}
```

### Production Flow (Manual)

Production deployments are triggered manually via GitHub Actions:

```
1. Select version type (major/minor/patch)
2. Version calculated from latest 3-part tag
3. Release branches created:
   - releases/staging/{version}
   - releases/production/{version}
4. Git tag created with 'v' prefix (v1.2.3)
5. Version hardcoded into app (AppVersion.swift)
6. Docker image built and tagged
7. Pre-deployment validation runs
8. Deployed to production
9. GitHub Release created
```

**Example:**
```bash
# Via GitHub UI:
# Actions → Deploy to Production → Run workflow
# Select: "minor"

# CI automatically:
# - Calculates: 1.1.0 (from previous 1.0.5)
# - Creates tag: v1.1.0
# - Creates branches: releases/staging/1.1.0, releases/production/1.1.0
# - App version endpoint returns: {"version": "1.1.0", "environment": "production"}
```

## Git Tag Structure

```
# Staging tags (4-part, no prefix)
0.1.0.1
0.1.0.2
0.1.0.3
...
0.1.0.100

# Production tags (3-part, v prefix)
v0.1.0
v0.2.0
v1.0.0
v1.1.0
v1.2.0
```

## Release Branches

When a production release is created, two branches are automatically generated:

### Staging Release Branch
**Format:** `releases/staging/{version}`

Example: `releases/staging/1.2.3`

- Used for staging deployments of this specific release
- Can receive hotfixes for this release version
- Tracks the production-ready state

### Production Release Branch
**Format:** `releases/production/{version}`

Example: `releases/production/1.2.3`

- Used for production deployments
- Locked to the exact production release state
- Enables rollback to specific versions

## Version in Application Code

The version is hardcoded during the build process in [`todos-fluent/Sources/App/AppVersion.swift`](../todos-fluent/Sources/App/AppVersion.swift):

```swift
enum AppVersion {
    static let current = "1.2.3"           // Set by CI
    static let buildDate = "2025-01-15..."  // ISO8601 timestamp
    static let environment = "production"    // staging or production
}
```

### Version Endpoint

The app exposes a `/version` endpoint:

**Staging response:**
```json
{
  "version": "0.1.0.42",
  "buildDate": "2025-01-15T14:30:00Z",
  "environment": "staging"
}
```

**Production response:**
```json
{
  "version": "1.2.3",
  "buildDate": "2025-01-15T14:30:00Z",
  "environment": "production"
}
```

## CI/CD Integration

### Staging Build Process

1. **Version Calculation** - [.github/actions/get-version](.github/actions/get-version)
   - Reads latest 4-part tag
   - Increments BUILD number

2. **App Version Update** - [.github/actions/set-app-version](.github/actions/set-app-version)
   - Updates `AppVersion.swift` with version
   - Sets environment to "staging"
   - Records build timestamp

3. **Git Tagging** - [.github/actions/git-tag-push](.github/actions/git-tag-push)
   - Creates tag without prefix (e.g., `0.1.0.42`)
   - Pushes to remote

### Production Release Process

1. **Version Calculation** - [.github/actions/get-version](.github/actions/get-version)
   - Reads latest 3-part tag
   - Increments MAJOR/MINOR/PATCH based on type

2. **Branch Creation** - [.github/actions/create-release-branch](.github/actions/create-release-branch)
   - Creates `releases/staging/{version}`
   - Creates `releases/production/{version}`

3. **App Version Update** - [.github/actions/set-app-version](.github/actions/set-app-version)
   - Updates `AppVersion.swift` with version
   - Sets environment to "production"
   - Records build timestamp

4. **Git Tagging** - [.github/actions/git-tag-push](.github/actions/git-tag-push)
   - Creates tag with 'v' prefix (e.g., `v1.2.3`)
   - Pushes to remote

## Version Manager Script

The `scripts/version-manager.swift` script helps with local version management:

```bash
# View current versions
./scripts/version-manager.swift show

# Calculate next staging build
./scripts/version-manager.swift build
# Output: 0.1.0.43

# Calculate next production patch
./scripts/version-manager.swift patch
# Output: 1.2.4

# Create manual tag
./scripts/version-manager.swift tag 1.2.4 "Hotfix release"
```

## Docker Image Tags

### Staging Images
```
ghcr.io/yourorg/yourapp:0.1.0.42
ghcr.io/yourorg/yourapp:latest
```

### Production Images
```
ghcr.io/yourorg/yourapp:1.2.3
ghcr.io/yourorg/yourapp:production
ghcr.io/yourorg/yourapp:latest
```

## Benefits of Dual Versioning

### Clear Separation
- **Staging**: Frequent builds with detailed version tracking
- **Production**: Semantic versioning following industry standards

### Better Traceability
- Every staging build has unique version
- Production versions follow semver conventions
- Release branches preserve exact state

### Simplified Operations
- Staging: Automatic, no manual intervention
- Production: Controlled, requires approval
- Both: No VERSION file conflicts

### Compliance
- Production versions match common release patterns (1.2.3)
- Staging versions provide build-level granularity (0.1.0.42)
- Full audit trail via git tags

## Migration Notes

### From Previous System
The old system used a single VERSION file with 4-part versions for both staging and production. The new system:

✅ Eliminates VERSION file (no merge conflicts)
✅ Uses git tags as source of truth
✅ Separates staging (4-part) from production (3-part)
✅ Creates release branches automatically
✅ Hardcodes version in app for runtime access

### Initial Setup
If you're starting fresh:

```bash
# Create initial staging tag
git tag -a 0.1.0.1 -m "Initial staging version"
git push origin 0.1.0.1

# When ready for first production release
# Use GitHub Actions → Deploy to Production
# Select version type: "minor" (creates v0.1.0)
```

## Quick Reference

| Action | Version Type | Tag Format | Example |
|--------|-------------|------------|---------|
| Commit to main | 4-part (auto) | No prefix | `0.1.0.42` |
| Production patch | 3-part | `v` prefix | `v1.2.4` |
| Production minor | 3-part | `v` prefix | `v1.3.0` |
| Production major | 3-part | `v` prefix | `v2.0.0` |

---

**Dual versioning: The best of both worlds - granular staging builds and clean production releases.**
