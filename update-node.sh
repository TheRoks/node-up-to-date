#!/bin/bash

# Node.js Version Manager Sync Tool
# Automatically sync NVM with officially supported Node.js versions
#
# IMPORTANT: Only installs even-numbered major versions (v20, v22, v24, etc.)
# Odd-numbered versions (v21, v23, v25, etc.) are development/experimental and never become LTS
#
# Version: 1.0.0
# Author: Node.js Version Manager Sync Tool Contributors
# License: MIT

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_VERSION="1.0.0"
readonly LOG_FILE="${HOME}/.nvm-sync.log"

# Global variables for Node.js versions
CURRENT_VERSION=""
ACTIVE_LTS=""
MAINTENANCE_LTS=""
SUPPORTED_VERSIONS=""

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Logging functions
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" >> "$LOG_FILE"
}

info() {
    echo -e "${BLUE}ℹ️  $*${NC}"
    log "INFO: $*"
}

success() {
    echo -e "${GREEN}✅ $*${NC}"
    log "SUCCESS: $*"
}

warning() {
    echo -e "${YELLOW}⚠️  $*${NC}"
    log "WARNING: $*"
}

error() {
    echo -e "${RED}❌ $*${NC}" >&2
    log "ERROR: $*"
}

progress() {
    echo -e "${PURPLE}🔄 $*${NC}"
    log "PROGRESS: $*"
}

# Error handling
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        error "Script failed with exit code $exit_code"
        error "Check the log file at: $LOG_FILE"
    fi
    exit $exit_code
}

trap cleanup EXIT

# Help function
show_help() {
    cat << EOF
${SCRIPT_NAME} v${SCRIPT_VERSION}

Automatically sync NVM with officially supported Node.js versions.

USAGE:
    ${SCRIPT_NAME} [OPTIONS]

OPTIONS:
    -h, --help      Show this help message
    -v, --version   Show version information
    -q, --quiet     Suppress non-error output
    --dry-run       Show what would be done without making changes
    --log-file      Specify custom log file location

EXAMPLES:
    ${SCRIPT_NAME}                  # Standard sync
    ${SCRIPT_NAME} --dry-run        # Preview changes
    ${SCRIPT_NAME} --quiet          # Minimal output

For more information, visit: https://github.com/theroks/node-up-to-date
EOF
}

# Version information
show_version() {
    echo "${SCRIPT_NAME} v${SCRIPT_VERSION}"
    echo "Node.js Version Manager Sync Tool"
    echo "Licensed under MIT License"
}

# Parse command line arguments
QUIET=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--version)
            show_version
            exit 0
            ;;
        -q|--quiet)
            QUIET=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --log-file)
            if [[ -n ${2:-} ]]; then
                LOG_FILE="$2"
                shift 2
            else
                error "Option --log-file requires a value"
                exit 1
            fi
            ;;
        *)
            error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Quiet mode handling
if [ "$QUIET" = true ]; then
    # Redefine output functions for quiet mode
    info() { log "INFO: $*"; }
    progress() { log "PROGRESS: $*"; }
    success() { log "SUCCESS: $*"; }
fi

# NVM initialization and validation
initialize_nvm() {
    progress "Initializing NVM..."

    # Set NVM directory
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

    # Source NVM script
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        # shellcheck source=/dev/null
        \. "$NVM_DIR/nvm.sh"
    else
        error "NVM script not found at $NVM_DIR/nvm.sh"
        error "Please install NVM first: https://github.com/nvm-sh/nvm"
        exit 1
    fi

    # Load bash completion if available
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

    # Verify NVM is working
    if ! command -v nvm &> /dev/null; then
        error "NVM command not available after initialization"
        exit 1
    fi

    success "NVM initialized successfully ($(nvm --version))"
}

# Fetch and validate Node.js versions
get_supported_versions() {
    progress "Fetching supported Node.js versions..."

    local lts_majors maintenance_major current_major

    # Get the current release (latest even-numbered major version only)
    # Node.js odd-numbered versions are never stable/LTS
    if ! CURRENT_VERSION=$(nvm ls-remote | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | while read -r version; do
        major=$(echo "$version" | cut -d'.' -f1 | sed 's/v//')
        if [ $((major % 2)) -eq 0 ]; then
            echo "$version"
        fi
    done | tail -1); then
        error "Failed to fetch current Node.js version"
        return 1
    fi

    # Validate that we found an even-numbered current version
    current_major=$(echo "$CURRENT_VERSION" | cut -d'.' -f1 | sed 's/v//')
    if [ $((current_major % 2)) -ne 0 ]; then
        warning "Current version $CURRENT_VERSION is odd-numbered (unstable), finding latest even-numbered version..."
        if ! CURRENT_VERSION=$(nvm ls-remote | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | while read -r version; do
            major=$(echo "$version" | cut -d'.' -f1 | sed 's/v//')
            if [ $((major % 2)) -eq 0 ]; then
                echo "$version"
            fi
        done | tail -1); then
            error "Failed to find stable even-numbered current version"
            return 1
        fi
    fi

    # Get Active LTS (the most recent LTS - already even-numbered by definition)
    if ! ACTIVE_LTS=$(nvm ls-remote --lts | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | tail -1); then
        error "Failed to fetch Active LTS version"
        return 1
    fi

    # Get Maintenance LTS (previous LTS major version that's still maintained)
    if ! lts_majors=$(nvm ls-remote --lts | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | awk -F'.' '{print $1}' | sort -u -V | tail -2); then
        error "Failed to fetch LTS major versions"
        return 1
    fi

    maintenance_major=$(echo "$lts_majors" | head -1)
    if [ -n "$maintenance_major" ]; then
        if ! MAINTENANCE_LTS=$(nvm ls-remote --lts | grep "$maintenance_major\." | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | tail -1); then
            warning "Failed to fetch Maintenance LTS for $maintenance_major, skipping"
            MAINTENANCE_LTS=""
        fi
    fi    # Validate versions
    if [ -z "$CURRENT_VERSION" ] || [ -z "$ACTIVE_LTS" ]; then
        error "Failed to fetch required Node.js versions"
        return 1
    fi

    # Combine into supported versions list
    if ! SUPPORTED_VERSIONS=$(echo -e "$CURRENT_VERSION\n$ACTIVE_LTS\n$MAINTENANCE_LTS" | sort -u | grep -v '^$'); then
        error "Failed to process supported versions list"
        return 1
    fi

    success "Found supported versions:"
    echo "$SUPPORTED_VERSIONS" | while read -r version; do
        info "  $version"
    done
    info "Active LTS ($ACTIVE_LTS) will be set as default"

    return 0
}

# Install Node.js versions
install_versions() {
    local version_count
    version_count=$(echo "$SUPPORTED_VERSIONS" | wc -l)
    local current=0

    progress "Installing $version_count supported versions..."

    while IFS= read -r version; do
        current=$((current + 1))
        progress "[$current/$version_count] Installing/updating $version..."

        if [ "$DRY_RUN" = true ]; then
            info "DRY RUN: Would install $version with latest npm"
            continue
        fi

        if nvm install "$version" --latest-npm; then
            success "Successfully installed $version"
        else
            error "Failed to install $version"
            return 1
        fi
    done <<< "$SUPPORTED_VERSIONS"

    return 0
}

# Set default Node.js version
set_default_version() {
    progress "Setting Active LTS ($ACTIVE_LTS) as default version..."

    if [ "$DRY_RUN" = true ]; then
        info "DRY RUN: Would set $ACTIVE_LTS as default"
        info "DRY RUN: Would switch to default version"
        return 0
    fi

    if nvm alias default "$ACTIVE_LTS" && nvm use default; then
        success "Set $ACTIVE_LTS as default and switched to it"
        info "Current Node.js version: $(node --version)"
        info "Current npm version: $(npm --version)"
    else
        error "Failed to set default version"
        return 1
    fi

    return 0
}

# Clean up unsupported versions
cleanup_versions() {
    local installed_versions unsupported_count=0

    progress "Cleaning up unsupported Node.js versions..."

    # Get only actually installed versions (those with * at the end)
    if ! installed_versions=$(nvm ls --no-colors | grep '\*$' | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | sort -u); then
        warning "Failed to get installed versions list"
        return 0
    fi

    if [ -z "$installed_versions" ]; then
        info "No installed versions found"
        return 0
    fi

    info "Currently installed versions:"
    echo "$installed_versions" | while read -r version; do
        info "  $version"
    done

    while IFS= read -r installed; do
        if ! echo "$SUPPORTED_VERSIONS" | grep -q "^$installed$"; then
            unsupported_count=$((unsupported_count + 1))
            warning "Found unsupported version: $installed"

            if [ "$DRY_RUN" = true ]; then
                info "DRY RUN: Would uninstall $installed"
                continue
            fi

            if nvm uninstall "$installed"; then
                success "Uninstalled unsupported version: $installed"
            else
                error "Failed to uninstall $installed"
            fi
        fi
    done <<< "$installed_versions"

    if [ $unsupported_count -eq 0 ]; then
        success "No unsupported versions found"
    else
        info "Processed $unsupported_count unsupported version(s)"
    fi

    return 0
}

# Main execution function
main() {
    # Initialize logging
    log "=== Starting $SCRIPT_NAME v$SCRIPT_VERSION ==="

    if [ "$DRY_RUN" = true ]; then
        info "Running in DRY RUN mode - no changes will be made"
    fi

    progress "Syncing NVM with all officially supported Node.js versions..."

    # Initialize NVM
    initialize_nvm || exit 1

    # Get supported versions
    get_supported_versions || exit 1

    # Install versions
    install_versions || exit 1

    # Set default version
    set_default_version || exit 1

    # Clean up unsupported versions
    cleanup_versions || exit 1

    success "NVM is now synced with all officially supported Node.js versions!"
    info "Log file: $LOG_FILE"

    log "=== Completed $SCRIPT_NAME v$SCRIPT_VERSION ==="
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
