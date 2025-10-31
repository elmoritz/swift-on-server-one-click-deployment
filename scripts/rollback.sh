#!/bin/bash
# Rollback script for Hummingbird Todos Application
# Usage: ./rollback.sh [staging|production]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
ENVIRONMENT=${1:-staging}

if [ "$ENVIRONMENT" != "staging" ] && [ "$ENVIRONMENT" != "production" ]; then
    echo -e "${RED}Error: Environment must be 'staging' or 'production'${NC}"
    echo "Usage: $0 [staging|production]"
    exit 1
fi

echo "========================================"
echo "Hummingbird Todos Rollback Script"
echo "========================================"
echo "Environment: $ENVIRONMENT"
echo ""

DEPLOY_DIR="/opt/todos-app"
DATA_DIR="$DEPLOY_DIR/data"
BACKUP_DIR="$DEPLOY_DIR/backups"
CONTAINER_NAME="todos-$ENVIRONMENT"
PREVIOUS_CONTAINER="$CONTAINER_NAME-previous"

cd "$DEPLOY_DIR"

# Check if previous container exists
if ! docker ps -a | grep -q "$PREVIOUS_CONTAINER"; then
    echo -e "${RED}Error: No previous container found for rollback${NC}"
    echo "Available containers:"
    docker ps -a --filter "name=todos" --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
    exit 1
fi

echo -e "${YELLOW}[1/4]${NC} Stopping current container..."
docker stop "$CONTAINER_NAME" || true
docker rm "$CONTAINER_NAME" || true

echo -e "${YELLOW}[2/4]${NC} Restoring database backup..."
LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/db.sqlite.backup.* 2>/dev/null | head -n1)
if [ -n "$LATEST_BACKUP" ]; then
    cp "$LATEST_BACKUP" "$DATA_DIR/db.sqlite"
    echo -e "${GREEN}Database restored from: $LATEST_BACKUP${NC}"
else
    echo -e "${YELLOW}Warning: No database backup found${NC}"
fi

echo -e "${YELLOW}[3/4]${NC} Starting previous container..."
docker rename "$PREVIOUS_CONTAINER" "$CONTAINER_NAME"
docker start "$CONTAINER_NAME"

echo -e "${YELLOW}[4/4]${NC} Verifying rollback..."
sleep 5

MAX_RETRIES=20
retry_count=0
while [ $retry_count -lt $MAX_RETRIES ]; do
    if curl -s -f http://localhost:8080/health > /dev/null 2>&1; then
        echo -e "${GREEN}Rollback successful - application is healthy!${NC}"
        break
    fi
    retry_count=$((retry_count + 1))
    sleep 2
done

if [ $retry_count -eq $MAX_RETRIES ]; then
    echo -e "${RED}CRITICAL: Rollback failed - health check unsuccessful${NC}"
    echo "Manual intervention required!"
    docker logs "$CONTAINER_NAME"
    exit 1
fi

# Update metadata
PREVIOUS_VERSION=$(docker inspect "$CONTAINER_NAME" --format='{{.Config.Image}}' | cut -d':' -f2)
echo "$PREVIOUS_VERSION" > "$DEPLOY_DIR/current-version.txt"
echo "$(date -Iseconds) - ROLLBACK" > "$DEPLOY_DIR/last-deployment.txt"

echo ""
echo "========================================"
echo -e "${GREEN}Rollback Complete!${NC}"
echo "========================================"
echo "Environment: $ENVIRONMENT"
echo "Container: $CONTAINER_NAME"
echo "Version: $PREVIOUS_VERSION"
echo "========================================"
