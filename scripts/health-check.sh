#!/bin/bash
# Health Check Script for Hummingbird Todos Application
# Usage: ./health-check.sh [BASE_URL] [MAX_RETRIES] [RETRY_INTERVAL]

set -e

# Configuration
BASE_URL="${1:-http://localhost:8080}"
MAX_RETRIES="${2:-30}"
RETRY_INTERVAL="${3:-2}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "========================================"
echo "Health Check for Hummingbird Todos"
echo "========================================"
echo "URL: $BASE_URL/health"
echo "Max retries: $MAX_RETRIES"
echo "Retry interval: ${RETRY_INTERVAL}s"
echo ""

retry_count=0

while [ $retry_count -lt $MAX_RETRIES ]; do
    retry_count=$((retry_count + 1))

    echo -n "Attempt $retry_count/$MAX_RETRIES... "

    if response=$(curl -s -f -w "\n%{http_code}" "${BASE_URL}/health" 2>/dev/null); then
        http_code=$(echo "$response" | tail -n1)

        if [ "$http_code" == "200" ]; then
            echo -e "${GREEN}SUCCESS${NC}"
            echo ""
            echo -e "${GREEN}Service is healthy!${NC}"
            echo "Response code: $http_code"
            exit 0
        else
            echo -e "${YELLOW}Unexpected status: $http_code${NC}"
        fi
    else
        echo -e "${RED}Failed${NC}"
    fi

    if [ $retry_count -lt $MAX_RETRIES ]; then
        sleep $RETRY_INTERVAL
    fi
done

echo ""
echo -e "${RED}Health check failed after $MAX_RETRIES attempts${NC}"
exit 1
