# Remote Server Scripts

This directory contains Swift scripts designed to run on remote deployment servers. These scripts handle Docker container deployment, rollback, and cleanup operations.

## Prerequisites

### On the Remote Server

1. **Swift Installation**
   - Swift must be installed on the remote server
   - Recommended: Swift 5.9 or later
   - Installation guide: https://swift.org/install/

2. **Docker Installation**
   - Docker must be installed and running
   - Docker Compose (if using compose deployments)

3. **Required Permissions**
   - User must have permissions to run Docker commands
   - Write access to deployment directory (default: `/opt/todos-app`)

### Script Installation

**The script is automatically uploaded and updated before each use.**

The GitHub Actions workflows automatically:
1. Upload the latest `server-manager.swift` to the user's home directory (`~/server-manager.swift`)
2. Make it executable with `chmod +x`
3. Run the appropriate command

This ensures you always use the latest version from your repository without needing write permissions to the deployment directory.

## Available Scripts

### server-manager.swift

Main deployment management tool with three commands:

#### 1. Deploy Command

Deploys a Docker container to the server. Supports both Docker run and Docker Compose modes.

**Environment Variables:**
- `IMAGE_TAG` - Full Docker image tag (e.g., `ghcr.io/user/app:1.0.0`)
- `VERSION` - Version number
- `CONTAINER_NAME` - Name for the container
- `PORT_MAPPING` - Port mapping (e.g., `8080:8080`)
- `DEPLOY_PATH` - Deployment directory path
- `COMPOSE_FOLDER` - (Optional) Docker Compose folder path
- `GITHUB_TOKEN` - GitHub token for registry authentication
- `GITHUB_ACTOR` - GitHub username
- `REGISTRY` - Container registry URL

**Example (Docker run):**
```bash
IMAGE_TAG=ghcr.io/user/app:1.0.0 \
VERSION=1.0.0 \
CONTAINER_NAME=todos-app \
PORT_MAPPING=8080:8080 \
DEPLOY_PATH=/opt/todos-app \
GITHUB_TOKEN=ghp_xxx \
GITHUB_ACTOR=username \
REGISTRY=ghcr.io \
./server-manager.swift deploy
```

**Example (Docker Compose):**
```bash
COMPOSE_FOLDER=/opt/todos-app/compose \
DEPLOY_PATH=/opt/todos-app \
GITHUB_TOKEN=ghp_xxx \
GITHUB_ACTOR=username \
REGISTRY=ghcr.io \
./server-manager.swift deploy
```

**What it does:**
1. Creates deployment directory if needed
2. Logs into container registry
3. For Docker run mode:
   - Pulls the new image
   - Backs up current container (renames to `{name}-previous`)
   - Backs up database (keeps last 10 backups)
   - Starts new container with specified configuration
4. For Docker Compose mode:
   - Changes to compose directory
   - Backs up database
   - Pulls images defined in docker-compose.yml
   - Stops existing services
   - Starts services with new configuration
5. Stores deployment metadata (version, timestamp)
6. Cleans up old Docker images

#### 2. Rollback Command

Rolls back to the previous container version.

**Environment Variables:**
- `CONTAINER_NAME` - Name of the container
- `DEPLOY_PATH` - Deployment directory path

**Example:**
```bash
CONTAINER_NAME=todos-app \
DEPLOY_PATH=/opt/todos-app \
./server-manager.swift rollback
```

**What it does:**
1. Stops and removes the failed container
2. Restores database from latest backup
3. Renames previous container back to original name
4. Starts the previous container

#### 3. Cleanup Command

Cleans up old backup containers and unused images.

**Environment Variables:**
- `CONTAINER_NAME` - Name of the container
- `PRUNE_IMAGES` - Whether to prune unused images (`true`/`false`, default: `true`)

**Example:**
```bash
CONTAINER_NAME=todos-app \
PRUNE_IMAGES=true \
./server-manager.swift cleanup
```

**What it does:**
1. Removes the old backup container (`{name}-previous`)
2. Optionally prunes unused Docker images

## Usage from GitHub Actions

The GitHub Actions workflows automatically:
1. Upload the latest script to `~/server-manager.swift`
2. Make it executable
3. Execute the appropriate command

See these actions:
- [.github/actions/deploy-server/action.yml](/.github/actions/deploy-server/action.yml)
- [.github/actions/rollback-deployment/action.yml](/.github/actions/rollback-deployment/action.yml)
- [.github/actions/docker-cleanup/action.yml](/.github/actions/docker-cleanup/action.yml)

**The script is always up-to-date** because it's uploaded fresh from the repository before each use.

**Note:** The script is placed in the home directory to avoid permission issues, while the actual deployment operations happen in the directories specified by environment variables (`DEPLOY_PATH`, `COMPOSE_FOLDER`).

## Database Backups

The script automatically manages database backups:
- Created before each deployment
- Stored in `{DEPLOY_PATH}/data/db.sqlite.backup.YYYYMMDD-HHMMSS`
- Keeps only the last 10 backups
- Automatically restored during rollback

## Deployment Metadata

The script stores deployment information:
- `current-version.txt` - Currently deployed version
- `last-deployment.txt` - ISO 8601 timestamp of last deployment

## Script Location

The script is uploaded to:
```
~/server-manager.swift
```

This avoids permission issues when uploading to system directories. The script itself will work with the deployment directories specified in the environment variables:
- `DEPLOY_PATH` - Where deployment files are located (default: `/opt/todos-app`)
- `COMPOSE_FOLDER` - Where docker-compose.yml is located (for Compose deployments)

The deployment directory contains:
- `docker-compose.yml` (if using Docker Compose mode)
- Database files (`data/db.sqlite`)
- Deployment metadata files

## Troubleshooting

### Script not executable
This is handled automatically by the actions, but if needed:
```bash
chmod +x ~/server-manager.swift
```

### Swift not found
Ensure Swift is in your PATH:
```bash
which swift
# Should output: /usr/bin/swift or similar
```

### Docker permission denied
Add your user to the docker group:
```bash
sudo usermod -aG docker $USER
# Log out and back in for changes to take effect
```

### Container not starting
Check Docker logs:
```bash
docker logs {CONTAINER_NAME}
```

Check container status:
```bash
docker ps -a | grep {CONTAINER_NAME}
```

## Security Considerations

1. **Secrets Management**
   - GitHub tokens are passed via environment variables
   - Tokens are only used for registry authentication
   - Not stored on disk

2. **File Permissions**
   - Ensure deployment directory has appropriate permissions
   - Database backups inherit directory permissions

3. **Container Isolation**
   - Containers run with `--restart unless-stopped`
   - Volume mounts are explicitly defined
   - No privileged mode required

## Maintenance

### Updating the Script

The script is automatically updated on each workflow run. To manually update:
```bash
scp .github/remote-scripts/server-manager.swift user@server:~/
chmod +x ~/server-manager.swift
```

### Manually Running the Script

You can also run the script manually on the server:

```bash
# Deploy
IMAGE_TAG=ghcr.io/user/app:1.0.0 \
VERSION=1.0.0 \
CONTAINER_NAME=todos-app \
PORT_MAPPING=8080:8080 \
DEPLOY_PATH=/opt/todos-app \
~/server-manager.swift deploy

# Rollback
CONTAINER_NAME=todos-app \
DEPLOY_PATH=/opt/todos-app \
~/server-manager.swift rollback

# Cleanup
CONTAINER_NAME=todos-app \
~/server-manager.swift cleanup
```

### Checking Disk Space

Database backups can accumulate:
```bash
du -sh /opt/todos-app/data/
```

Manually clean old backups if needed:
```bash
ls -lht /opt/todos-app/data/db.sqlite.backup.*
```
