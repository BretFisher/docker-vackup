#!/bin/bash
# Test runner script for vackup
# Usage: ./test/run-tests.sh [options]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default options
VERBOSE=false
PARALLEL=false
CLEAN=false

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Run Bats tests for vackup

OPTIONS:
    -v, --verbose    Run tests in verbose mode
    -p, --parallel   Run tests in parallel (if bats supports it)
    -c, --clean      Clean up any leftover test resources before running
    -h, --help       Show this help message

EXAMPLES:
    $0                      # Run all tests
    $0 -v                   # Run tests with verbose output
    $0 -c                   # Clean up first, then run tests
    $0 -v -p               # Run tests verbose and in parallel

EOF
}

cleanup_test_resources() {
    echo -e "${YELLOW}Cleaning up leftover test resources...${NC}"
    
    # Clean up test volumes
    docker volume ls -q | grep '^vackup_test_' | while read -r vol; do
        [ -n "$vol" ] && docker volume rm "$vol" > /dev/null 2>&1 && echo "Removed volume: $vol" || true
    done
    
    # Clean up test images
    docker image ls -q --filter "reference=vackup_test_*" | while read -r img; do
        [ -n "$img" ] && docker image rm "$img" > /dev/null 2>&1 && echo "Removed image: $img" || true
    done
    
    echo -e "${GREEN}Cleanup completed.${NC}"
}

check_requirements() {
    echo "Checking requirements..."
    
    # Check if bats is installed
    if ! command -v bats >/dev/null 2>&1; then
        echo -e "${RED}Error: bats is not installed. Please install it first.${NC}"
        echo "On macOS: brew install bats-core"
        echo "On Ubuntu/Debian: apt-get install bats"
        exit 1
    fi
    
    # Check if docker is available
    if ! command -v docker >/dev/null 2>&1; then
        echo -e "${RED}Error: docker is not installed or not in PATH.${NC}"
        exit 1
    fi
    
    # Check if docker daemon is running
    if ! docker info >/dev/null 2>&1; then
        echo -e "${RED}Error: Docker daemon is not running.${NC}"
        exit 1
    fi
    
    # Check if vackup script exists and is executable
    if [ ! -x "$REPO_ROOT/vackup" ]; then
        echo -e "${RED}Error: vackup script not found or not executable at $REPO_ROOT/vackup${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}All requirements satisfied.${NC}"
}

run_tests() {
    local bats_args=()
    
    if [ "$VERBOSE" = true ]; then
        bats_args+=("--verbose-run")
    fi
    
    if [ "$PARALLEL" = true ]; then
        # Check if bats supports parallel execution
        if bats --help | grep -q parallel; then
            bats_args+=("--jobs" "$(nproc 2>/dev/null || echo 4)")
        else
            echo -e "${YELLOW}Warning: This version of bats doesn't support parallel execution.${NC}"
        fi
    fi
    
    echo -e "${YELLOW}Running tests...${NC}"
    cd "$REPO_ROOT"
    
    if [ ${#bats_args[@]} -gt 0 ]; then
        bats "${bats_args[@]}" test/vackup.bats
    else
        bats test/vackup.bats
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}Some tests failed.${NC}"
        return 1
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -p|--parallel)
            PARALLEL=true
            shift
            ;;
        -c|--clean)
            CLEAN=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            exit 1
            ;;
    esac
done

# Main execution
echo -e "${GREEN}Vackup Test Runner${NC}"
echo "Repository: $REPO_ROOT"
echo

check_requirements

if [ "$CLEAN" = true ]; then
    cleanup_test_resources
    echo
fi

run_tests
