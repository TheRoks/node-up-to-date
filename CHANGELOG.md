# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-07-27

### Added

#### Node.js Version Management Tool (`update-node.sh`)

- Automatic detection and installation of Current, Active LTS, and Maintenance LTS versions
- **Smart version filtering**: Only installs even-numbered major versions (v20, v22, v24, etc.)
- Intelligent cleanup of unsupported Node.js versions
- Automatic setting of Active LTS as default version
- NVM compatibility verification
- Command-line options: `--help`, `--version`, `--quiet`, `--dry-run`

#### .NET Version Management Tool (`update-dotnet.sh`)

- Cross-platform .NET SDK management (Linux, macOS)
- Automatic installation of Current and LTS .NET versions
- **End-of-Life version exclusion**: Automatically excludes EOL versions (e.g., .NET 6.0)
- Side-by-side .NET version support
- Microsoft official installer integration
- .NET environment configuration (PATH, DOTNET_ROOT)
- Command-line options: `--help`, `--version`, `--quiet`, `--dry-run`, `--no-cleanup`, `--no-profile-update`

#### Core Features

- Comprehensive error handling and validation
- Color-coded output for better user experience
- Advanced logging system with timestamps
- Dry run mode for previewing changes
- Quiet mode for automation
- Cross-platform compatibility (macOS, Linux)

#### Documentation

- Consolidated comprehensive README with unified documentation
- Comprehensive usage examples and troubleshooting guide
- Contributing guidelines for developers
- MIT license for open source usage

### Technical Implementation

#### Node.js Tool Features

- **Smart Version Detection**: Automatically identifies the three officially supported Node.js versions
- **Stability Focus**: Excludes odd-numbered major versions (v21, v23, v25) as they are development/experimental
- **Safe Installation**: Installs latest patch versions with newest npm
- **Intelligent Cleanup**: Only removes truly unsupported versions
- **Default Management**: Sets Active LTS as default for stability

#### .NET Tool Features

- **Microsoft API Integration**: Queries official .NET releases API for supported versions
- **Support Phase Filtering**: Distinguishes between active, maintenance, and end-of-life versions
- **Smart Cleanup**: Maintains one version per major.minor, removes EOL versions
- **Environment Integration**: Automatic PATH and shell profile configuration
- **Homebrew Compatibility**: Detects and works alongside existing .NET installations

### Architecture

- Shell scripts with modern bash practices
- ShellCheck compliant code
- Proper error handling with exit codes
- Enterprise-grade project structure
- Modular design for maintainability

## [Unreleased]

### Planned Features

- Interactive mode for version selection
- Configuration file support
- CI/CD integration examples
- Windows support via WSL
- Plugin system for custom version sources
- Performance optimizations
- Enhanced testing suite
