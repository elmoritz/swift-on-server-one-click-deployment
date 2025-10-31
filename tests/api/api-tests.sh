#!/bin/bash
# API Test Suite for Hummingbird Todos Application
# This script tests all API endpoints and validates responses

set -e  # Exit on first error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
BASE_URL="${API_BASE_URL:-http://localhost:8080}"
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Helper functions
print_test() {
    echo -e "${YELLOW}[TEST]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASSED_TESTS++))
    ((TOTAL_TESTS++))
}

print_error() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAILED_TESTS++))
    ((TOTAL_TESTS++))
}

print_info() {
    echo -e "[INFO] $1"
}

# Test helper - makes HTTP request and validates response
test_endpoint() {
    local method=$1
    local endpoint=$2
    local expected_status=$3
    local data=$4
    local description=$5

    print_test "$description"

    if [ -z "$data" ]; then
        response=$(curl -s -w "\n%{http_code}" -X "$method" "${BASE_URL}${endpoint}")
    else
        response=$(curl -s -w "\n%{http_code}" -X "$method" \
            -H "Content-Type: application/json" \
            -d "$data" \
            "${BASE_URL}${endpoint}")
    fi

    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')

    if [ "$http_code" == "$expected_status" ]; then
        print_success "Status: $http_code (expected $expected_status)"
        echo "$body"
        return 0
    else
        print_error "Status: $http_code (expected $expected_status)"
        echo "$body"
        return 1
    fi
}

# Validate JSON response contains field
validate_json_field() {
    local json=$1
    local field=$2
    local description=$3

    if echo "$json" | grep -q "\"$field\""; then
        print_success "$description - Field '$field' exists"
        return 0
    else
        print_error "$description - Field '$field' missing"
        return 1
    fi
}

echo "========================================"
echo "Hummingbird Todos API Test Suite"
echo "========================================"
echo "Base URL: $BASE_URL"
echo ""

# Wait for server to be ready
print_info "Waiting for server to be ready..."
max_retries=30
retry_count=0
while [ $retry_count -lt $max_retries ]; do
    if curl -s -f "${BASE_URL}/health" > /dev/null 2>&1; then
        print_success "Server is ready!"
        break
    fi
    retry_count=$((retry_count + 1))
    sleep 1
done

if [ $retry_count -eq $max_retries ]; then
    print_error "Server did not start in time"
    exit 1
fi

echo ""
echo "========================================="
echo "TEST SUITE: Health Check"
echo "========================================="

# Test 1: Health check
response=$(test_endpoint "GET" "/health" "200" "" "Health check endpoint")

echo ""
echo "========================================="
echo "TEST SUITE: Todo CRUD Operations"
echo "========================================="

# Test 2: List todos (initially empty)
print_test "List all todos (should be empty initially)"
response=$(curl -s -w "\n%{http_code}" "${BASE_URL}/api/todos")
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')

if [ "$http_code" == "200" ]; then
    print_success "Successfully retrieved todo list"
else
    print_error "Failed to retrieve todo list (status: $http_code)"
fi

# Test 3: Create a new todo
print_test "Create a new todo"
create_response=$(curl -s -w "\n%{http_code}" -X POST \
    -H "Content-Type: application/json" \
    -d '{"title": "Test Todo 1", "completed": false}' \
    "${BASE_URL}/api/todos")

http_code=$(echo "$create_response" | tail -n1)
body=$(echo "$create_response" | sed '$d')

if [ "$http_code" == "201" ]; then
    print_success "Todo created successfully (status: 201)"
    TODO_ID=$(echo "$body" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
    print_info "Created todo ID: $TODO_ID"

    # Validate response structure
    validate_json_field "$body" "id" "Create todo response validation"
    validate_json_field "$body" "title" "Create todo response validation"
    validate_json_field "$body" "completed" "Create todo response validation"
else
    print_error "Failed to create todo (status: $http_code)"
    TODO_ID=""
fi

# Test 4: Get specific todo
if [ -n "$TODO_ID" ]; then
    print_test "Retrieve specific todo by ID"
    get_response=$(curl -s -w "\n%{http_code}" "${BASE_URL}/api/todos/${TODO_ID}")
    http_code=$(echo "$get_response" | tail -n1)
    body=$(echo "$get_response" | sed '$d')

    if [ "$http_code" == "200" ]; then
        print_success "Todo retrieved successfully"
        if echo "$body" | grep -q "\"Test Todo 1\""; then
            print_success "Todo title matches expected value"
        else
            print_error "Todo title does not match"
        fi
    else
        print_error "Failed to retrieve todo (status: $http_code)"
    fi
fi

# Test 5: Update todo
if [ -n "$TODO_ID" ]; then
    print_test "Update todo (mark as completed)"
    update_response=$(curl -s -w "\n%{http_code}" -X PATCH \
        -H "Content-Type: application/json" \
        -d '{"title": "Updated Test Todo", "completed": true}' \
        "${BASE_URL}/api/todos/${TODO_ID}")

    http_code=$(echo "$update_response" | tail -n1)
    body=$(echo "$update_response" | sed '$d')

    if [ "$http_code" == "200" ]; then
        print_success "Todo updated successfully"
        if echo "$body" | grep -q "\"completed\":true"; then
            print_success "Todo marked as completed"
        else
            print_error "Todo completion status not updated"
        fi
    else
        print_error "Failed to update todo (status: $http_code)"
    fi
fi

# Test 6: Create multiple todos
print_test "Create multiple todos for listing"
for i in {2..5}; do
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "{\"title\": \"Test Todo $i\", \"completed\": false}" \
        "${BASE_URL}/api/todos" > /dev/null
done
print_success "Created 4 additional todos"

# Test 7: List all todos (should have 5 now)
print_test "List all todos (should have 5 total)"
list_response=$(curl -s -w "\n%{http_code}" "${BASE_URL}/api/todos")
http_code=$(echo "$list_response" | tail -n1)
body=$(echo "$list_response" | sed '$d')

if [ "$http_code" == "200" ]; then
    count=$(echo "$body" | grep -o '"id"' | wc -l | tr -d ' ')
    if [ "$count" -ge "5" ]; then
        print_success "Todo list contains $count todos"
    else
        print_error "Expected at least 5 todos, found $count"
    fi
else
    print_error "Failed to list todos (status: $http_code)"
fi

# Test 8: Delete todo
if [ -n "$TODO_ID" ]; then
    print_test "Delete todo by ID"
    delete_response=$(curl -s -w "\n%{http_code}" -X DELETE \
        "${BASE_URL}/api/todos/${TODO_ID}")

    http_code=$(echo "$delete_response" | tail -n1)

    if [ "$http_code" == "200" ] || [ "$http_code" == "204" ]; then
        print_success "Todo deleted successfully (status: $http_code)"
    else
        print_error "Failed to delete todo (status: $http_code)"
    fi

    # Test 9: Verify deletion
    print_test "Verify todo is deleted"
    verify_response=$(curl -s -w "\n%{http_code}" "${BASE_URL}/api/todos/${TODO_ID}")
    http_code=$(echo "$verify_response" | tail -n1)

    if [ "$http_code" == "404" ]; then
        print_success "Todo not found after deletion (expected 404)"
    else
        print_error "Todo still exists after deletion (status: $http_code)"
    fi
fi

echo ""
echo "========================================="
echo "TEST SUITE: Error Handling"
echo "========================================="

# Test 10: Get non-existent todo
print_test "Request non-existent todo"
response=$(curl -s -w "\n%{http_code}" "${BASE_URL}/api/todos/00000000-0000-0000-0000-000000000000")
http_code=$(echo "$response" | tail -n1)

if [ "$http_code" == "404" ]; then
    print_success "Correctly returned 404 for non-existent todo"
else
    print_error "Expected 404, got $http_code"
fi

# Test 11: Invalid todo creation (missing required field)
print_test "Create todo with missing required field"
response=$(curl -s -w "\n%{http_code}" -X POST \
    -H "Content-Type: application/json" \
    -d '{"completed": false}' \
    "${BASE_URL}/api/todos")
http_code=$(echo "$response" | tail -n1)

if [ "$http_code" == "400" ] || [ "$http_code" == "422" ]; then
    print_success "Correctly rejected invalid todo (status: $http_code)"
else
    print_error "Expected 400/422 for invalid data, got $http_code"
fi

# Test 12: Invalid UUID format
print_test "Request todo with invalid UUID format"
response=$(curl -s -w "\n%{http_code}" "${BASE_URL}/api/todos/invalid-uuid")
http_code=$(echo "$response" | tail -n1)

if [ "$http_code" == "400" ] || [ "$http_code" == "404" ]; then
    print_success "Correctly handled invalid UUID (status: $http_code)"
else
    print_error "Expected 400/404 for invalid UUID, got $http_code"
fi

# Final summary
echo ""
echo "========================================="
echo "TEST SUMMARY"
echo "========================================="
echo "Total Tests: $TOTAL_TESTS"
echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
echo -e "${RED}Failed: $FAILED_TESTS${NC}"
echo "========================================="

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi
