#!/bin/bash
# Deployment script for Hummingbird Todos Application
# Usage: ./deploy.sh [staging|production] [version]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
ENVIRONMENT=${1:-staging}
VERSION=${2:-latest}
REGISTRY="ghcr.io"
IMAGE_NAME="hummingbird-todos"

if [ "$ENVIRONMENT" != "staging" ] && [ "$ENVIRONMENT" != "production" ]; then
    echo -e "${RED}Error: Environment must be 'staging' or 'production'${NC}"
    echo "Usage: $0 [staging|production] [version]"
    exit 1
fi

echo "========================================"
echo "Hummingbird Todos Deployment Script"
echo "========================================"
echo "Environment: $ENVIRONMENT"
echo "Version: $VERSION"
echo ""

# Create deployment directory
DEPLOY_DIR="/opt/todos-app"
DATA_DIR="$DEPLOY_DIR/data"
BACKUP_DIR="$DEPLOY_DIR/backups"

mkdir -p "$DEPLOY_DIR"
mkdir -p "$DATA_DIR"
mkdir -p "$BACKUP_DIR"

cd "$DEPLOY_DIR"

echo -e "${YELLOW}[1/6]${NC} Backing up database..."
if [ -f "$DATA_DIR/db.sqlite" ]; then
    BACKUP_FILE="$BACKUP_DIR/db.sqlite.backup.$(date +%Y%m%d-%H%M%S)"
    cp "$DATA_DIR/db.sqlite" "$BACKUP_FILE"
    echo -e "${GREEN}Database backed up to: $BACKUP_FILE${NC}"

    # Keep only last 10 backups
    ls -t "$BACKUP_DIR"/db.sqlite.backup.* 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null || true
else
    echo "No existing database to backup"
fi

echo -e "${YELLOW}[2/6]${NC} Pulling Docker image..."
IMAGE_TAG="$REGISTRY/$IMAGE_NAME:$VERSION"
docker pull "$IMAGE_TAG"

echo -e "${YELLOW}[3/6]${NC} Stopping current container..."
CONTAINER_NAME="todos-$ENVIRONMENT"
PREVIOUS_CONTAINER="$CONTAINER_NAME-previous"

if docker ps -a | grep -q "$CONTAINER_NAME"; then
    echo "Renaming current container for rollback purposes..."
    docker rename "$CONTAINER_NAME" "$PREVIOUS_CONTAINER" || true
    docker stop "$PREVIOUS_CONTAINER" || true
fi

echo -e "${YELLOW}[4/6]${NC} Starting new container..."
docker run -d \
    --name "$CONTAINER_NAME" \
    --restart unless-stopped \
    -p 8080:8080 \
    -v "$DATA_DIR:/app/data" \
    -e HOSTNAME=0.0.0.0 \
    -e PORT=8080 \
    "$IMAGE_TAG"

echo -e "${YELLOW}[5/6]${NC} Waiting for application to be healthy..."
sleep 5

MAX_RETRIES=30
retry_count=0
while [ $retry_count -lt $MAX_RETRIES ]; do
    if curl -s -f http://localhost:8080/health > /dev/null 2>&1; then
        echo -e "${GREEN}Application is healthy!${NC}"
        break
    fi
    retry_count=$((retry_count + 1))
    sleep 2
done

if [ $retry_count -eq $MAX_RETRIES ]; then
    echo -e "${RED}Health check failed!${NC}"
    echo "Rolling back..."

    docker stop "$CONTAINER_NAME" || true
    docker rm "$CONTAINER_NAME" || true

    if docker ps -a | grep -q "$PREVIOUS_CONTAINER"; then
        docker rename "$PREVIOUS_CONTAINER" "$CONTAINER_NAME"
        docker start "$CONTAINER_NAME"
        echo -e "${YELLOW}Rolled back to previous version${NC}"
    fi

    exit 1
fi

echo -e "${YELLOW}[6/6]${NC} Cleaning up..."
# Remove previous container if health check passed
docker rm "$PREVIOUS_CONTAINER" 2>/dev/null || true

# Clean up old images
docker image prune -f

# Save deployment metadata
echo "$VERSION" > "$DEPLOY_DIR/current-version.txt"
echo "$(date -Iseconds)" > "$DEPLOY_DIR/last-deployment.txt"

echo ""
echo "========================================"
echo -e "${GREEN}Deployment Successful!${NC}"
echo "========================================"
echo "Environment: $ENVIRONMENT"
echo "Version: $VERSION"
echo "Container: $CONTAINER_NAME"
echo "Health: http://localhost:8080/health"
echo "========================================"
