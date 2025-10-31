#!/bin/bash
# Version Manager for Hummingbird Todos Application
# Manages semantic versioning with build numbers (MAJOR.MINOR.PATCH.BUILD)

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

VERSION_FILE="VERSION"
ACTION=${1:-""}

# Helper functions
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Initialize version file if it doesn't exist
init_version() {
    if [ ! -f "$VERSION_FILE" ]; then
        echo "0.1.0.1" > "$VERSION_FILE"
        print_success "Initialized version file with 0.1.0.1"
    fi
}

# Read current version
read_version() {
    if [ ! -f "$VERSION_FILE" ]; then
        init_version
    fi
    cat "$VERSION_FILE"
}

# Parse version into components
parse_version() {
    local version=$1
    MAJOR=$(echo "$version" | cut -d. -f1)
    MINOR=$(echo "$version" | cut -d. -f2)
    PATCH=$(echo "$version" | cut -d. -f3)
    BUILD=$(echo "$version" | cut -d. -f4)
}

# Write new version
write_version() {
    local version=$1
    echo "$version" > "$VERSION_FILE"
    print_success "Version updated to: $version"
}

# Increment build number
increment_build() {
    local current_version=$(read_version)
    parse_version "$current_version"

    BUILD=$((BUILD + 1))
    local new_version="${MAJOR}.${MINOR}.${PATCH}.${BUILD}"

    write_version "$new_version"
    echo "$new_version"
}

# Increment patch version (bugfix)
increment_patch() {
    local current_version=$(read_version)
    parse_version "$current_version"

    PATCH=$((PATCH + 1))
    BUILD=1  # Reset build number
    local new_version="${MAJOR}.${MINOR}.${PATCH}.${BUILD}"

    write_version "$new_version"
    echo "$new_version"
}

# Increment minor version (feature)
increment_minor() {
    local current_version=$(read_version)
    parse_version "$current_version"

    MINOR=$((MINOR + 1))
    PATCH=0  # Reset patch
    BUILD=1  # Reset build number
    local new_version="${MAJOR}.${MINOR}.${PATCH}.${BUILD}"

    write_version "$new_version"
    echo "$new_version"
}

# Increment major version (breaking change)
increment_major() {
    local current_version=$(read_version)
    parse_version "$current_version"

    MAJOR=$((MAJOR + 1))
    MINOR=0  # Reset minor
    PATCH=0  # Reset patch
    BUILD=1  # Reset build number
    local new_version="${MAJOR}.${MINOR}.${PATCH}.${BUILD}"

    write_version "$new_version"
    echo "$new_version"
}

# Display current version
show_version() {
    local version=$(read_version)
    parse_version "$version"

    echo "========================================"
    echo "Current Version Information"
    echo "========================================"
    echo "Full Version: $version"
    echo "Major:        $MAJOR"
    echo "Minor:        $MINOR"
    echo "Patch:        $PATCH"
    echo "Build:        $BUILD"
    echo "========================================"
}

# Create git tag
create_tag() {
    local version=$1
    local message=${2:-"Release version $version"}

    if git rev-parse "v${version}" >/dev/null 2>&1; then
        print_warning "Tag v${version} already exists"
        return 1
    fi

    git tag -a "v${version}" -m "$message"
    print_success "Created tag: v${version}"

    print_info "To push the tag, run: git push origin v${version}"
}

# Usage information
usage() {
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  show                    Show current version"
    echo "  build                   Increment build number (0.1.0.1 -> 0.1.0.2)"
    echo "  patch|bugfix           Increment patch version (0.1.0.5 -> 0.1.1.1)"
    echo "  minor|feature          Increment minor version (0.1.5.3 -> 0.2.0.1)"
    echo "  major|breaking         Increment major version (1.2.3.4 -> 2.0.0.1)"
    echo "  tag [message]          Create git tag for current version"
    echo "  get                    Get current version (output only)"
    echo ""
    echo "Examples:"
    echo "  $0 show                           # Display version info"
    echo "  $0 build                          # Increment build number"
    echo "  $0 patch                          # Create bugfix version"
    echo "  $0 minor                          # Create feature version"
    echo "  $0 major                          # Create breaking change version"
    echo "  $0 tag 'Release notes here'       # Tag current version"
    echo ""
    echo "Version Format: MAJOR.MINOR.PATCH.BUILD"
    echo "  MAJOR - Incompatible API changes"
    echo "  MINOR - Add functionality (backwards compatible)"
    echo "  PATCH - Bug fixes (backwards compatible)"
    echo "  BUILD - Build/commit number (auto-incremented)"
}

# Main logic
init_version

case "$ACTION" in
    show)
        show_version
        ;;
    build)
        new_version=$(increment_build)
        print_success "Build number incremented"
        echo "$new_version"
        ;;
    patch|bugfix)
        new_version=$(increment_patch)
        print_success "Patch version incremented (bugfix)"
        echo "$new_version"
        ;;
    minor|feature)
        new_version=$(increment_minor)
        print_success "Minor version incremented (new feature)"
        echo "$new_version"
        ;;
    major|breaking)
        new_version=$(increment_major)
        print_success "Major version incremented (breaking change)"
        echo "$new_version"
        ;;
    tag)
        current_version=$(read_version)
        message=${2:-"Release version $current_version"}
        create_tag "$current_version" "$message"
        ;;
    get)
        read_version
        ;;
    "")
        usage
        exit 0
        ;;
    *)
        print_error "Unknown command: $ACTION"
        echo ""
        usage
        exit 1
        ;;
esac
