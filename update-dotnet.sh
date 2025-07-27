#!/bin/bash

# .NET Version Manager Sync Tool
# Automatically sync your system with officially supported .NET versions
#
# IMPORTANT: Only installs LTS and Current versions
# Preview versions are development/experimental and not recommended for production
#
# Version: 1.0.0
# Author: .NET Version Manager Sync Tool Contributors
# License: MIT

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_VERSION="1.0.0"
readonly LOG_FILE="${HOME}/.dotnet-sync.log"

# Global variables for .NET versions
CURRENT_VERSION=""
LTS_VERSIONS=""
SUPPORTED_VERSIONS=""

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# .NET installation directory
DOTNET_ROOT="${DOTNET_ROOT:-$HOME/.dotnet}"

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

Automatically sync your system with officially supported .NET versions.

USAGE:
    ${SCRIPT_NAME} [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -v, --version       Show version information
    -q, --quiet         Suppress non-error output
    --dry-run           Show what would be done without making changes
    --no-cleanup        Skip automatic removal of unsupported versions
    --no-profile-update Skip updating shell profile (manual PATH setup required)
    --log-file          Specify custom log file location
    --dotnet-root       Specify custom .NET installation directory

EXAMPLES:
    ${SCRIPT_NAME}                      # Standard sync with cleanup and profile update
    ${SCRIPT_NAME} --dry-run            # Preview changes
    ${SCRIPT_NAME} --no-cleanup         # Install only, no cleanup
    ${SCRIPT_NAME} --no-profile-update  # Don't modify shell profile
    ${SCRIPT_NAME} --quiet              # Minimal output

SUPPORTED VERSIONS:
    - Current: Latest stable release
    - LTS: All active Long Term Support versions

For more information, visit: https://github.com/theroks/node-up-to-date
EOF
}

# Version information
show_version() {
    echo "${SCRIPT_NAME} v${SCRIPT_VERSION}"
    echo ".NET Version Manager Sync Tool"
    echo "Licensed under MIT License"
}

# Parse command line arguments
QUIET=false
DRY_RUN=false
NO_CLEANUP=false
NO_PROFILE_UPDATE=false

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
        --no-cleanup)
            NO_CLEANUP=true
            shift
            ;;
        --no-profile-update)
            NO_PROFILE_UPDATE=true
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
        --dotnet-root)
            if [[ -n ${2:-} ]]; then
                DOTNET_ROOT="$2"
                shift 2
            else
                error "Option --dotnet-root requires a value"
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

# Detect OS and architecture
detect_platform() {
    local os arch

    case "$(uname -s)" in
        Linux*)
            os="linux"
            ;;
        Darwin*)
            os="osx"
            ;;
        CYGWIN*|MINGW32*|MSYS*|MINGW*)
            os="win"
            ;;
        *)
            error "Unsupported operating system: $(uname -s)"
            exit 1
            ;;
    esac

    case "$(uname -m)" in
        x86_64|amd64)
            arch="x64"
            ;;
        arm64|aarch64)
            arch="arm64"
            ;;
        armv7l)
            arch="arm"
            ;;
        *)
            error "Unsupported architecture: $(uname -m)"
            exit 1
            ;;
    esac

    echo "${os}-${arch}"
}

# Get .NET releases information from Microsoft's official API
get_dotnet_releases() {
    local api_url="https://dotnetcli.azureedge.net/dotnet/release-metadata/releases-index.json"
    local releases

    if command -v curl >/dev/null 2>&1; then
        releases=$(curl -s "$api_url")
    elif command -v wget >/dev/null 2>&1; then
        releases=$(wget -qO- "$api_url")
    else
        error "Neither curl nor wget is available"
        return 1
    fi

    if [ -z "$releases" ] || [ "$releases" = "null" ]; then
        error "Failed to fetch .NET releases information"
        return 1
    fi

    echo "$releases"
}

# Parse .NET versions from Microsoft's releases API
parse_dotnet_versions() {
    local releases="$1"
    local current_versions lts_versions temp_file

    # Create temporary file for easier parsing
    temp_file="/tmp/dotnet-releases-$$.json"
    echo "$releases" > "$temp_file"

    # Get the current version (STS with active support)
    current_versions=$(grep -B5 -A15 '"release-type": "sts"' "$temp_file" | \
                      grep -B15 -A5 '"support-phase": "active"' | \
                      grep '"latest-sdk":' | head -1 | \
                      sed 's/.*"latest-sdk": "\([^"]*\)".*/\1/')

    # Get LTS versions with active or maintenance support only (exclude EOL versions)
    # Use a simpler approach: extract just the .NET 8.0 entry since it's the only LTS with active support
    lts_versions=$(echo "$releases" | grep -A 15 '"channel-version": "8.0"' | \
                  grep '"support-phase": "active"' > /dev/null && \
                  echo "$releases" | grep -A 15 '"channel-version": "8.0"' | \
                  grep '"latest-sdk":' | \
                  sed 's/.*"latest-sdk": "\([^"]*\)".*/\1/' || echo "")

    CURRENT_VERSION="$current_versions"
    LTS_VERSIONS="$lts_versions"
}

# Fetch and validate .NET versions
get_supported_versions() {
    progress "Fetching supported .NET versions..."

    local releases

    if ! releases=$(get_dotnet_releases); then
        error "Failed to fetch .NET releases"
        return 1
    fi

    parse_dotnet_versions "$releases"

    # Validate versions
    if [ -z "$CURRENT_VERSION" ]; then
        error "Failed to fetch current .NET version"
        return 1
    fi

    # Combine current and LTS versions
    SUPPORTED_VERSIONS=$(echo -e "$CURRENT_VERSION\n$LTS_VERSIONS" | sort -u -V | grep -v '^$')

    success "Found supported versions:"
    echo "$SUPPORTED_VERSIONS" | while read -r version; do
        if echo "$LTS_VERSIONS" | grep -q "^$version$"; then
            info "  $version (LTS)"
        else
            info "  $version (Current)"
        fi
    done

    return 0
}

# Download and install .NET version
install_dotnet_version() {
    local version="$1"
    local platform
    local install_script_url
    local install_script="/tmp/dotnet-install.sh"

    platform=$(detect_platform)

    progress "Installing .NET $version for $platform..."

    if [ "$DRY_RUN" = true ]; then
        if is_compatible_version_installed "$version"; then
            info "DRY RUN: Compatible .NET ${version%.*}.x version already installed"
        else
            info "DRY RUN: Would install .NET $version"
        fi
        return 0
    fi

    # Download the .NET install script
    case "$platform" in
        linux-*|osx-*)
            install_script_url="https://dot.net/v1/dotnet-install.sh"
            if command -v curl >/dev/null 2>&1; then
                curl -fsSL "$install_script_url" -o "$install_script"
            elif command -v wget >/dev/null 2>&1; then
                wget -q "$install_script_url" -O "$install_script"
            else
                error "Neither curl nor wget is available"
                return 1
            fi

            chmod +x "$install_script"

            # Install the specific version (SDK)
            # The version should already be in the correct format (e.g., "9.0.303")
            if "$install_script" --version "$version" --install-dir "$DOTNET_ROOT" --no-path --channel "${version%.*}"; then
                success "Successfully installed .NET $version"
            else
                error "Failed to install .NET $version"
                return 1
            fi

            rm -f "$install_script"
            ;;
        win-*)
            error "Windows installation not implemented. Please use the official installer."
            return 1
            ;;
        *)
            error "Unsupported platform: $platform"
            return 1
            ;;
    esac

    return 0
}

# Check if a .NET version is already installed (exact or newer patch in same major.minor)
is_compatible_version_installed() {
    local target_version="$1"
    local target_major_minor="${target_version%.*}"

    if ! command -v dotnet >/dev/null 2>&1; then
        return 1
    fi

    # Get installed SDKs from all possible locations
    local all_installed_sdks=""

    # Get SDKs from active dotnet installation
    if installed_sdks=$(dotnet --list-sdks 2>/dev/null | awk '{print $1}'); then
        all_installed_sdks="$installed_sdks"
    fi

    # Also check our DOTNET_ROOT installation if it exists and is different
    if [ -d "$DOTNET_ROOT/sdk" ] && [ "$(ls -A "$DOTNET_ROOT/sdk" 2>/dev/null)" ]; then
        local script_sdks
        if script_sdks=$("$DOTNET_ROOT/dotnet" --list-sdks 2>/dev/null | awk '{print $1}'); then
            all_installed_sdks=$(echo -e "$all_installed_sdks\n$script_sdks" | sort -u | grep -v '^$')
        fi
    fi

    if [ -z "$all_installed_sdks" ]; then
        return 1
    fi

    # Check if any installed version matches the major.minor and is newer or equal
    local target_patch="${target_version##*.}"
    while IFS= read -r installed; do
        local installed_major_minor="${installed%.*}"
        if [ "$installed_major_minor" = "$target_major_minor" ]; then
            local installed_patch="${installed##*.}"
            # If installed patch is greater than or equal to target, consider it compatible
            if [ "$installed_patch" -ge "$target_patch" ] 2>/dev/null; then
                return 0  # Compatible or newer version found
            fi
        fi
    done <<< "$all_installed_sdks"

    return 1  # No compatible version found
}

# Install .NET versions
install_versions() {
    local version_count
    version_count=$(echo "$SUPPORTED_VERSIONS" | wc -l)
    local current=0

    progress "Installing $version_count supported versions..."

    # Ensure DOTNET_ROOT directory exists
    if [ "$DRY_RUN" != true ]; then
        mkdir -p "$DOTNET_ROOT"
    fi

    while IFS= read -r version; do
        current=$((current + 1))
        progress "[$current/$version_count] Installing .NET $version..."

        # Check if a compatible version is already installed
        if is_compatible_version_installed "$version"; then
            success "Compatible .NET ${version%.*}.x version already installed"
            continue
        fi

        if ! install_dotnet_version "$version"; then
            error "Failed to install .NET $version"
            return 1
        fi
    done <<< "$SUPPORTED_VERSIONS"

    return 0
}

# Set up .NET environment
setup_environment() {
    progress "Setting up .NET environment..."

    if [ "$DRY_RUN" = true ]; then
        info "DRY RUN: Would set up .NET environment variables"
        info "DRY RUN: Would add $DOTNET_ROOT to PATH"
        if [ "$NO_PROFILE_UPDATE" = false ]; then
            if command -v dotnet >/dev/null 2>&1; then
                local dotnet_path
                dotnet_path=$(command -v dotnet)
                if [[ "$dotnet_path" != "$DOTNET_ROOT"* ]]; then
                    info "DRY RUN: Would skip shell profile update (.NET already available at $dotnet_path)"
                else
                    info "DRY RUN: Would update shell profile for persistent PATH"
                fi
            else
                info "DRY RUN: Would update shell profile for persistent PATH"
            fi
        else
            info "DRY RUN: Would skip shell profile update (--no-profile-update)"
        fi
        return 0
    fi

    # Add DOTNET_ROOT to PATH if not already present
    if [[ ":$PATH:" != *":$DOTNET_ROOT:"* ]]; then
        export PATH="$DOTNET_ROOT:$PATH"
        success "Added $DOTNET_ROOT to PATH"
    fi

    # Set DOTNET_ROOT environment variable
    export DOTNET_ROOT

    # Update shell profile for persistent PATH (unless disabled or .NET already available)
    if [ "$NO_PROFILE_UPDATE" = false ]; then
        # Check if .NET is already available in PATH from other installations (like Homebrew)
        if command -v dotnet >/dev/null 2>&1; then
            local dotnet_path
            dotnet_path=$(command -v dotnet)

            # If dotnet is already available and not from our DOTNET_ROOT, inform user
            if [[ "$dotnet_path" != "$DOTNET_ROOT"* ]]; then
                info ".NET CLI already available in PATH: $dotnet_path"
                info "Skipping shell profile update (using system installation)"
            else
                update_shell_profile
            fi
        else
            update_shell_profile
        fi
    else
        info "Skipping shell profile update due to --no-profile-update flag"
        info "You'll need to manually add: export PATH=\"$DOTNET_ROOT:\$PATH\" to your shell profile"
    fi

    # Verify installation and detect multiple .NET installations
    if command -v dotnet >/dev/null 2>&1; then
        local active_dotnet_path
        active_dotnet_path=$(command -v dotnet)
        success ".NET CLI is available: $(dotnet --version)"

        # Check if we have multiple .NET installations
        local script_installed_sdks=""
        if [ -d "$DOTNET_ROOT/sdk" ] && [ "$(ls -A "$DOTNET_ROOT/sdk" 2>/dev/null)" ]; then
            script_installed_sdks=$("$DOTNET_ROOT/dotnet" --list-sdks 2>/dev/null || echo "")
        fi

        # Show currently active SDKs
        info "Currently active SDKs (from $active_dotnet_path):"
        dotnet --list-sdks | while read -r sdk; do
            info "  $sdk"
        done

        # If we have SDKs installed by our script but they're not active, inform the user
        if [ -n "$script_installed_sdks" ] && [[ "$active_dotnet_path" != "$DOTNET_ROOT"* ]]; then
            warning ""
            warning "Additional .NET SDKs installed by this script (in $DOTNET_ROOT):"
            echo "$script_installed_sdks" | while read -r sdk; do
                warning "  $sdk"
            done
            warning ""
            warning "These versions are available but not currently active due to PATH precedence."
            info "Your system is using: $active_dotnet_path"
            info "Script installed to: $DOTNET_ROOT"
            info ""
            info "To use the script-installed versions instead:"
            info "1. Remove Homebrew .NET: brew uninstall dotnet"
            info "2. Or adjust PATH priority: export PATH=\"$DOTNET_ROOT:\$PATH\""
            info "3. Or use specific version: $DOTNET_ROOT/dotnet --version"
            info ""
            info "To see all script-installed SDKs: $DOTNET_ROOT/dotnet --list-sdks"
        fi
    else
        warning ".NET CLI not found in PATH. You may need to restart your shell or add $DOTNET_ROOT to your PATH manually."
    fi

    return 0
}

# Update shell profile to persist PATH changes
update_shell_profile() {
    local shell_profile=""
    local dotnet_export="export PATH=\"\$HOME/.dotnet:\$PATH\""
    local custom_dotnet_export="export PATH=\"$DOTNET_ROOT:\$PATH\""

    # Determine the correct shell profile file
    if [ -n "${ZSH_VERSION:-}" ] || [ "$SHELL" = "/bin/zsh" ] || [ "$SHELL" = "/usr/bin/zsh" ]; then
        shell_profile="$HOME/.zshrc"
    elif [ -n "${BASH_VERSION:-}" ] || [ "$SHELL" = "/bin/bash" ] || [ "$SHELL" = "/usr/bin/bash" ]; then
        if [ -f "$HOME/.bash_profile" ]; then
            shell_profile="$HOME/.bash_profile"
        else
            shell_profile="$HOME/.bashrc"
        fi
    else
        # Fallback: try to detect from common profile files
        for profile in "$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.bashrc" "$HOME/.profile"; do
            if [ -f "$profile" ]; then
                shell_profile="$profile"
                break
            fi
        done
    fi

    if [ -z "$shell_profile" ]; then
        warning "Could not determine shell profile file"
        info "Please manually add: export PATH=\"$DOTNET_ROOT:\$PATH\" to your shell profile"
        return 0
    fi

    # Check if .NET PATH is already in the profile
    local export_line
    if [ "$DOTNET_ROOT" = "$HOME/.dotnet" ]; then
        export_line="$dotnet_export"
    else
        export_line="$custom_dotnet_export"
    fi

    if [ -f "$shell_profile" ] && grep -Fq "dotnet" "$shell_profile" && grep -Fq "PATH" "$shell_profile"; then
        info ".NET PATH already configured in $shell_profile"
        return 0
    fi

    # Add .NET to PATH in shell profile
    progress "Updating shell profile: $shell_profile"

    {
        echo ""
        echo "# Added by .NET Version Manager Sync Tool"
        echo "$export_line"
    } >> "$shell_profile"

    success "Updated $shell_profile with .NET PATH"
    info "Changes will take effect in new shell sessions"

    # Try to source the profile in the current session (best effort)
    if [ -f "$shell_profile" ]; then
        # shellcheck disable=SC1090
        if source "$shell_profile" 2>/dev/null; then
            success "Applied changes to current shell session"
            info "No restart required - .NET CLI should be available now"
        else
            info "Profile updated, but couldn't apply to current session"
            info "Run: source $shell_profile  (or start a new shell)"
        fi
    fi

    return 0
}

# Clean up old .NET versions (keep only latest patch per major.minor)
cleanup_versions() {
    local installed_sdks unsupported_versions=() older_patches=() removed_count=0

    if [ "$NO_CLEANUP" = true ]; then
        info "Skipping cleanup due to --no-cleanup flag"
        return 0
    fi

    progress "Cleaning up unsupported and older patch versions..."

    if [ "$DRY_RUN" = true ]; then
        info "DRY RUN: Would check for unsupported .NET versions and older patches"
        return 0
    fi

    # Collect all installed SDKs from all locations
    local all_installed_sdks=""
    local temp_file="/tmp/dotnet-cleanup-$$"

    # Get SDKs from active dotnet installation
    if command -v dotnet >/dev/null 2>&1; then
        if installed_sdks=$(dotnet --list-sdks 2>/dev/null); then
            echo "$installed_sdks" | while IFS= read -r line; do
                local version=$(echo "$line" | awk '{print $1}')
                local path=$(echo "$line" | sed 's/.*\[\(.*\)\].*/\1/')
                echo "$version|$path" >> "${temp_file}_paths"
                echo "$version" >> "${temp_file}_versions"
            done
        fi
    fi

    # Also check our DOTNET_ROOT installation
    if [ -d "$DOTNET_ROOT/sdk" ] && [ "$(ls -A "$DOTNET_ROOT/sdk" 2>/dev/null)" ]; then
        for sdk_dir in "$DOTNET_ROOT/sdk"/*; do
            if [ -d "$sdk_dir" ]; then
                local version=$(basename "$sdk_dir")
                echo "$version|$DOTNET_ROOT/sdk" >> "${temp_file}_paths"
                echo "$version" >> "${temp_file}_versions"
            fi
        done
    fi

    if [ ! -f "${temp_file}_versions" ]; then
        info "No installed .NET SDKs found"
        return 0
    fi

    all_installed_sdks=$(sort -u "${temp_file}_versions" 2>/dev/null | grep -v '^$')

    info "Currently installed .NET SDKs:"
    echo "$all_installed_sdks" | while read -r version; do
        info "  $version"
    done

    # Find latest version for each major.minor
    local temp_latest="${temp_file}_latest"
    > "$temp_latest"  # Clear file

    echo "$all_installed_sdks" | while IFS= read -r version; do
        local major_minor="${version%.*}"
        local current_latest=""

        # Check if we already have a latest for this major.minor
        if [ -f "$temp_latest" ]; then
            current_latest=$(grep "^$major_minor|" "$temp_latest" 2>/dev/null | cut -d'|' -f2)
        fi

        if [ -z "$current_latest" ]; then
            # First version for this major.minor
            echo "$major_minor|$version" >> "$temp_latest"
        else
            # Compare patch versions
            local current_patch="${current_latest##*.}"
            local new_patch="${version##*.}"

            if [ "$new_patch" -gt "$current_patch" ] 2>/dev/null; then
                # New version has higher patch, update
                sed -i.bak "s|^$major_minor|.*|$major_minor|$version|" "$temp_latest" 2>/dev/null || {
                    # Fallback for systems without sed -i
                    grep -v "^$major_minor|" "$temp_latest" > "${temp_latest}.tmp" 2>/dev/null || true
                    echo "$major_minor|$version" >> "${temp_latest}.tmp"
                    mv "${temp_latest}.tmp" "$temp_latest"
                }
            fi
        fi
    done

    # Identify versions to remove
    echo "$all_installed_sdks" | while IFS= read -r installed; do
        local major_minor="${installed%.*}"
        local is_supported=false
        local is_latest_patch=false

        # Check if this major.minor version is supported
        echo "$SUPPORTED_VERSIONS" | while IFS= read -r supported; do
            local supported_major_minor="${supported%.*}"
            if [ "$major_minor" = "$supported_major_minor" ]; then
                echo "$installed" >> "${temp_file}_supported_majmin"
                break
            fi
        done

        # If not found in supported major.minor, it's unsupported
        if [ ! -f "${temp_file}_supported_majmin" ] || ! grep -q "^$installed$" "${temp_file}_supported_majmin" 2>/dev/null; then
            echo "$installed" >> "${temp_file}_unsupported"
        else
            # Check if this is the latest patch for its major.minor
            if [ -f "$temp_latest" ]; then
                local latest_for_major_minor=$(grep "^$major_minor|" "$temp_latest" 2>/dev/null | cut -d'|' -f2)
                if [ "$installed" != "$latest_for_major_minor" ]; then
                    echo "$installed (keeping latest: $latest_for_major_minor)" >> "${temp_file}_older"
                fi
            fi
        fi
    done

    # Report what will be removed
    if [ -f "${temp_file}_unsupported" ]; then
        local unsupported_count=$(wc -l < "${temp_file}_unsupported" 2>/dev/null || echo "0")
        if [ "$unsupported_count" -gt 0 ]; then
            warning "Found $unsupported_count unsupported version(s) to remove:"
            while IFS= read -r version; do
                warning "  $version (unsupported major.minor)"
            done < "${temp_file}_unsupported"
        fi
    fi

    if [ -f "${temp_file}_older" ]; then
        local older_count=$(wc -l < "${temp_file}_older" 2>/dev/null || echo "0")
        if [ "$older_count" -gt 0 ]; then
            warning "Found $older_count older patch version(s) to remove:"
            while IFS= read -r line; do
                warning "  $line"
            done < "${temp_file}_older"
        fi
    fi

    # Combine versions to remove
    local versions_to_remove=""
    if [ -f "${temp_file}_unsupported" ]; then
        versions_to_remove=$(cat "${temp_file}_unsupported" 2>/dev/null || echo "")
    fi
    if [ -f "${temp_file}_older" ]; then
        local older_versions=$(cut -d' ' -f1 "${temp_file}_older" 2>/dev/null || echo "")
        versions_to_remove=$(echo -e "$versions_to_remove\n$older_versions" | grep -v '^$')
    fi

    if [ -z "$versions_to_remove" ]; then
        success "No cleanup needed - all versions are supported and latest patches"
        rm -f "${temp_file}"* 2>/dev/null || true
        return 0
    fi

    # Remove versions
    local temp_remove_list="${temp_file}_remove_list"
    echo "$versions_to_remove" > "$temp_remove_list"

    while IFS= read -r version; do
        if [ -n "$version" ]; then
            progress "Removing .NET SDK $version..."
            local removed=false

            # Try to find and remove from all possible locations
            if [ -f "${temp_file}_paths" ]; then
                while IFS='|' read -r sdk_version sdk_base_path; do
                    if [ "$sdk_version" = "$version" ]; then
                        local sdk_path="$sdk_base_path/$version"

                        if [ -d "$sdk_path" ]; then
                            if rm -rf "$sdk_path" 2>/dev/null; then
                                success "Removed .NET SDK $version from $sdk_path"
                                removed_count=$((removed_count + 1))
                                removed=true
                            elif sudo rm -rf "$sdk_path" 2>/dev/null; then
                                success "Removed .NET SDK $version from $sdk_path (with sudo)"
                                removed_count=$((removed_count + 1))
                                removed=true
                            fi
                        fi
                    fi
                done < "${temp_file}_paths"
            fi

            if [ "$removed" = false ]; then
                warning "Could not locate or remove .NET SDK $version"
            fi
        fi
    done < "$temp_remove_list"

    # Cleanup temp files
    rm -f "${temp_file}"* 2>/dev/null || true

    if [ $removed_count -gt 0 ]; then
        success "Successfully removed $removed_count .NET SDK(s)"
        info "Refreshing .NET SDK list..."

        # Show remaining SDKs
        if command -v dotnet >/dev/null 2>&1; then
            info "Remaining installed SDKs:"
            dotnet --list-sdks | while read -r sdk; do
                info "  $sdk"
            done
        fi

        if [ -d "$DOTNET_ROOT/sdk" ] && [ "$(ls -A "$DOTNET_ROOT/sdk" 2>/dev/null)" ]; then
            info "Script-installed SDKs:"
            "$DOTNET_ROOT/dotnet" --list-sdks | while read -r sdk; do
                info "  $sdk"
            done
        fi
    else
        warning "No versions were successfully removed"
        info "You may need to manually clean up using: https://docs.microsoft.com/en-us/dotnet/core/additional-tools/uninstall-tool"
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

    progress "Syncing system with all officially supported .NET versions..."
    info "Installation directory: $DOTNET_ROOT"

    # Get supported versions
    get_supported_versions || exit 1

    # Install versions
    install_versions || exit 1

    # Set up environment
    setup_environment || exit 1

    # Clean up old versions
    cleanup_versions || exit 1

    success "System is now synced with all officially supported .NET versions!"
    info "Log file: $LOG_FILE"

    if [ "$DRY_RUN" != true ]; then
        info ""
        info "🔧 Next steps:"
        if [ "$NO_PROFILE_UPDATE" = true ]; then
            info "1. Add to your shell profile: export PATH=\"$DOTNET_ROOT:\$PATH\""
            info "2. Restart your shell or run: source ~/.zshrc (or ~/.bashrc)"
        else
            info "1. Shell profile updated automatically - no restart needed!"
        fi
        info "2. Verify installation: dotnet --version"
        info "3. List installed SDKs: dotnet --list-sdks"
    fi

    log "=== Completed $SCRIPT_NAME v$SCRIPT_VERSION ==="
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
