---
layout: default
title: Build Optimization
nav_order: 6
description: "Docker build optimization strategy for faster incremental builds"
permalink: /build-optimization
---

# Docker Build Optimization Guide

This document explains the build optimization strategy implemented for faster incremental Docker builds.

## Problem Statement

The previous setup used GitHub Actions cache (`type=gha`) which had limitations:
- Cache only accessible from the main branch
- Limited to 10GB per repository
- Not efficient for Swift package dependencies which can be large
- Slow incremental builds when only source code changed

## Solution: Registry-Based Multi-Stage Build Cache

We've implemented a sophisticated caching strategy using Docker registry cache combined with multi-stage builds.

### Architecture

#### Multi-Stage Dockerfile

The Dockerfile now has 3 stages:

1. **Dependencies Stage** - Resolves Swift package dependencies
   - Caches based on `Package.resolved` hash
   - Only rebuilds when dependencies change

2. **Builder Stage** - Compiles the application
   - Reuses cached dependencies from stage 1
   - Only recompiles when source code changes

3. **Runtime Stage** - Final minimal image
   - Contains only the compiled binary
   - Smallest possible image size

### Cache Key Strategy

We use a multi-layered cache key approach:

```bash
# Primary cache key - based on Package.resolved hash
builder-cache-<deps-hash>    # e.g., builder-cache-a1b2c3d4e5f6

# Fallback cache key - always available
builder-cache-latest
```

#### How Cache Keys Work

1. **Dependencies Hash** (`deps-hash`):
   - SHA-256 hash of `Package.resolved` (first 12 characters)
   - Changes only when package dependencies are updated
   - Provides perfect cache hit for unchanged dependencies

2. **Fallback to Latest**:
   - If exact dependency match not found, uses `builder-cache-latest`
   - Provides partial cache benefit even with dependency changes
   - Docker layer caching still helps significantly

### Cache Flow

#### First Build (Cold Cache)
```
1. No cache found
2. Downloads all dependencies (~2-5 minutes)
3. Compiles source code (~1-3 minutes)
4. Pushes cache to registry with both tags:
   - builder-cache-<deps-hash>
   - builder-cache-latest
```

#### Incremental Build (Source Code Change)
```
1. Finds exact cache: builder-cache-<deps-hash>
2. Reuses all dependency layers (instant!)
3. Only recompiles changed source files (~30-60 seconds)
4. Updates cache
```

#### Incremental Build (Dependency Change)
```
1. Exact cache miss (deps-hash changed)
2. Falls back to builder-cache-latest
3. Reuses base Swift image layers
4. Downloads only new/changed dependencies (~1-2 minutes)
5. Compiles source code
6. Pushes new cache with new deps-hash
```

## Benefits

### Speed Improvements

| Scenario | Before | After | Improvement |
|----------|--------|-------|-------------|
| Cold build | 5-8 min | 5-8 min | Same |
| Source change only | 5-8 min | 30-90 sec | **~5-10x faster** |
| Dependency change | 5-8 min | 2-3 min | **~2-3x faster** |

### Additional Benefits

1. **Cross-Branch Caching**: All branches can reuse cache from any other branch
2. **No Storage Limits**: Registry storage is unlimited
3. **Faster CI/CD**: Dramatically reduced pipeline execution time
4. **Cost Savings**: Reduced compute time = lower CI/CD costs

## Implementation Details

### Files Updated

The optimization is implemented in the reusable composite action and all workflows:

**Composite Action:**
- [.github/actions/docker-build-push/action.yml](https://github.com/elmoritz/swift-on-server-one-click-deployment/blob/main/.github/actions/docker-build-push/action.yml) - Reusable Docker build action with optimized caching

**Workflows (using the composite action):**
- [ci.yml](https://github.com/elmoritz/swift-on-server-one-click-deployment/blob/main/.github/workflows/ci.yml) - Main CI pipeline
- [deploy-staging.yml](https://github.com/elmoritz/swift-on-server-one-click-deployment/blob/main/.github/workflows/deploy-staging.yml) - Staging deployments
- [deploy-production.yml](https://github.com/elmoritz/swift-on-server-one-click-deployment/blob/main/.github/workflows/deploy-production.yml) - Production deployments

{: .note }
> The workflows use composite actions for better maintainability. The caching strategy is centralized in the docker-build-push action.

### Cache Configuration

Each workflow now includes:

```yaml
- name: Generate cache keys
  id: cache-keys
  run: |
    DEPS_HASH=$(sha256sum todos-fluent/Package.resolved | cut -d' ' -f1 | cut -c1-12)
    echo "deps-hash=${DEPS_HASH}" >> $GITHUB_OUTPUT

- name: Build and push
  uses: docker/build-push-action@v5
  with:
    cache-from: |
      type=registry,ref=ghcr.io/${{ github.repository }}:builder-cache-${{ steps.cache-keys.outputs.deps-hash }}
      type=registry,ref=ghcr.io/${{ github.repository }}:builder-cache-latest
      type=gha
    cache-to: |
      type=registry,ref=ghcr.io/${{ github.repository }}:builder-cache-${{ steps.cache-keys.outputs.deps-hash }},mode=max
      type=registry,ref=ghcr.io/${{ github.repository }}:builder-cache-latest,mode=max
      type=gha,mode=max
```

## Cache Management

### Viewing Cached Images

Check your cached builder images:

```bash
gh api \
  -H "Accept: application/vnd.github+json" \
  /user/packages/container/hummingbirdplublication/versions \
  | jq '.[] | select(.metadata.container.tags[] | contains("builder-cache")) | .metadata.container.tags'
```

### Cache Cleanup

GitHub Container Registry automatically manages old versions, but you can manually clean up:

```bash
# List all builder cache tags
gh api /user/packages/container/hummingbirdplublication/versions \
  | jq -r '.[] | select(.metadata.container.tags[] | contains("builder-cache")) | .id' \
  | head -n -5  # Keep last 5 versions

# Delete old cache versions (be careful!)
# gh api --method DELETE /user/packages/container/hummingbirdplublication/versions/{version-id}
```

### Storage Considerations

- Each builder cache is approximately 500MB-1GB (compressed)
- Multiple cache versions can coexist (different dependency combinations)
- Registry cleanup policies can be configured in GitHub settings

## Monitoring Build Performance

### CI Pipeline Duration

Monitor your pipeline performance in GitHub Actions:

1. Go to Actions tab
2. Select a workflow run
3. Compare "Build Docker Image" step duration

Expected times:
- **With cache hit**: 30-90 seconds
- **With partial cache**: 2-3 minutes
- **Cold cache**: 5-8 minutes

### Cache Hit Rate

Check logs for cache effectiveness:

```
Look for lines like:
✓ Cache hit on builder-cache-a1b2c3d4e5f6
✓ Imported cache from registry
```

## Troubleshooting

### Cache Not Being Used

If builds are slow despite cache:

1. **Check registry authentication**:
   ```yaml
   - name: Log in to GitHub Container Registry
     uses: docker/login-action@v3
   ```

2. **Verify cache keys are generated**:
   ```bash
   # Should see deps-hash in logs
   Dependencies hash: a1b2c3d4e5f6
   ```

3. **Check cache-from order** (tries each in sequence):
   - Exact deps match first
   - Latest fallback second
   - GHA cache last

### Build Failures

If builds fail with cache:

1. **Clear cache and rebuild**:
   - Delete builder-cache-latest tag
   - Force cold build

2. **Check Dockerfile syntax**:
   - Verify multi-stage build is correct
   - Test locally: `docker build .`

## Local Development

To benefit from similar caching locally:

```bash
# Pull latest cache from registry
docker pull ghcr.io/YOUR_USERNAME/hummingbirdplublication:builder-cache-latest

# Build with cache
docker build \
  --cache-from ghcr.io/YOUR_USERNAME/hummingbirdplublication:builder-cache-latest \
  -t todos-app:local \
  .
```

## Future Improvements

Potential enhancements:

1. **Source code hash in cache key**: Add source code hash for even more granular caching
2. **Build cache retention policy**: Implement automatic cleanup of old caches
3. **Cache warming**: Pre-build cache on dependency updates
4. **Multi-architecture caching**: Separate caches for ARM64 and AMD64

## References

- [Docker Build Cache Documentation](https://docs.docker.com/build/cache/)
- [BuildKit Cache Backends](https://docs.docker.com/build/cache/backends/)
- [GitHub Actions Docker Build](https://github.com/docker/build-push-action)
