# Development Environment Version Management Tools

Advanced automation tools to sync your development environment with officially supported versions of Node.js and .NET.

**Version:** 1.0.0
**License:** MIT
**Platform Support:** Linux, macOS

## 📦 Available Tools

### 🟢 Node.js Version Manager (`update-node.sh`)

Intelligently synchronizes your NVM installation with officially supported Node.js versions: Current, Active LTS, and Maintenance LTS.

### 🔵 .NET Version Manager (`update-dotnet.sh`)

Seamlessly manages your .NET SDK installations with officially supported versions: Current and Long Term Support (LTS) releases.

## 🚀 Quick Start

Select your preferred tool and begin automation in seconds:

### Node.js Tool

```bash
# Direct execution (recommended)
curl -fsSL https://raw.githubusercontent.com/theroks/node-up-to-date/main/update-node.sh | bash

# Manual installation
git clone https://github.com/theroks/node-up-to-date.git
cd node-up-to-date && chmod +x update-node.sh && ./update-node.sh
```

### .NET Tool

```bash
# Direct execution (recommended)
curl -fsSL https://raw.githubusercontent.com/theroks/node-up-to-date/main/update-dotnet.sh | bash

# Manual installation
git clone https://github.com/theroks/node-up-to-date.git
cd node-up-to-date && chmod +x update-dotnet.sh && ./update-dotnet.sh
```

---

## 🟢 Node.js Tool Details

### 🎯 Node.js Tool Purpose

This tool ensures your development environment stays current with Node.js's official support policy by automatically:

- Installing the latest **stable** Current release (even-numbered major versions only)
- Installing the Active LTS version (recommended for production)
- Installing the Maintenance LTS version (still receiving security updates)
- Removing outdated/unsupported versions
- Setting Active LTS as your default version

### 📋 Node.js Tool Prerequisites

- **NVM (Node Version Manager)**: Must be installed and properly configured
- **Operating System**: macOS or Linux
- **Network Access**: Required to fetch version information and download Node.js
- **Bash shell**: Version 4.0 or higher

### 🏗️ Node.js Release Cycle Understanding

**Important**: This tool intelligently filters Node.js versions:

- **Even major versions** (v20, v22, v24...) become LTS and are production-ready
- **Odd major versions** (v21, v23, v25...) are development/experimental and never become LTS
- **Current**: Latest stable even-numbered major version
- **Active LTS**: Production-recommended version with 18-month active support
- **Maintenance LTS**: Previous LTS receiving security updates only

### 📖 Node.js Tool Usage

#### Node.js Basic Usage

```bash
./update-node.sh
```

#### Node.js Command Line Options

```bash
./update-node.sh [OPTIONS]

OPTIONS:
    -h, --help          Show help message
    -v, --version       Show version information
    -q, --quiet         Suppress non-error output
    --dry-run           Show what would be done without making changes
```

#### What Node.js Tool Does

1. **Fetches Current Versions**: Queries NVM for the latest official releases
2. **Installs Supported Versions**:
   - Current: Latest **stable** release (even-numbered major version, e.g., v24.x.x)
   - Active LTS: Most recent LTS (e.g., v22.x.x "Jod")
   - Maintenance LTS: Previous LTS still maintained (e.g., v20.x.x "Iron")
3. **Sets Default**: Configures Active LTS as your default Node.js version
4. **Cleanup**: Removes unsupported/outdated versions to keep your environment clean

#### Node.js Example Output

```text
🔄 Syncing NVM with all officially supported Node.js versions...
ℹ️  NVM directory: /Users/user/.nvm
🔄 Fetching latest Node.js versions...
✅ Found supported versions:
ℹ️    v24.17.1 (Current)
ℹ️    v22.17.1 (Active LTS: Jod)
ℹ️    v20.17.1 (Maintenance LTS: Iron)
🔄 Installing 3 supported versions...
🔄 [1/3] Installing Node.js v24.17.1 (Current)...
✅ Node.js v24.17.1 installed successfully
🔧 Setting Active LTS (v22.17.1) as default version...
✅ Default Node.js version set to v22.17.1
✅ System is now synced with all officially supported Node.js versions!
```

---

## 🔵 .NET Tool Details

### 🎯 .NET Tool Purpose

This tool ensures your development environment stays current with Microsoft's official .NET support policy by automatically:

- Installing the latest **Current** release (stable, newest features)
- Installing all active **LTS versions** (recommended for production)
- Setting up proper environment variables and PATH configuration
- Providing cleanup of unsupported and End-of-Life versions
- Supporting cross-platform installation (Linux, macOS)

### 📋 .NET Tool Prerequisites

- **Operating System**: Linux or macOS (Windows support planned)
- **Network Access**: Required to download .NET installers
- **curl or wget**: For downloading installation scripts
- **Bash shell**: Version 4.0 or higher

### 🏗️ .NET Release Cycle Understanding

**Important**: This tool follows Microsoft's .NET release pattern:

- **Even versions** (6, 8, 10...) are typically LTS with 3-year support
- **Odd versions** (7, 9, 11...) are Current releases with 18-month support
- **End-of-Life versions** are automatically excluded (e.g., .NET 6.0 reached EOL on November 12, 2024)
- **Preview/RC versions** are excluded as they're not production-ready

### 📖 .NET Tool Usage

#### .NET Basic Usage

```bash
./update-dotnet.sh
```

#### .NET Command Line Options

```bash
./update-dotnet.sh [OPTIONS]

OPTIONS:
    -h, --help              Show help message
    -v, --version           Show version information
    -q, --quiet             Suppress non-error output
    --dry-run               Show what would be done without making changes
    --no-cleanup            Skip automatic removal of unsupported versions
    --no-profile-update     Skip updating shell profile (manual PATH setup required)
    --log-file              Specify custom log file location
    --dotnet-root           Specify custom .NET installation directory
```

#### What .NET Tool Does

1. **Fetches Supported Versions**: Queries Microsoft's release API for Current and LTS versions
2. **Installs Multiple Versions**: Installs Current and all active LTS versions side-by-side
3. **Environment Setup**: Configures PATH and DOTNET_ROOT environment variables
4. **Profile Integration**: Updates shell profile for persistent configuration
5. **Cleanup**: Removes End-of-Life and unsupported versions

#### .NET Example Output

```text
🔄 Syncing system with all officially supported .NET versions...
ℹ️  Installation directory: /Users/user/.dotnet
🔄 Fetching supported .NET versions...
✅ Found supported versions:
ℹ️    8.0.412 (LTS)
ℹ️    9.0.303 (Current)
🔄 Installing 2 supported versions...
🔄 [1/2] Installing .NET 8.0.412...
✅ Successfully installed .NET 8.0.412
🔄 [2/2] Installing .NET 9.0.303...
✅ Successfully installed .NET 9.0.303
🔄 Setting up .NET environment...
✅ Added /Users/user/.dotnet to PATH
✅ Updated /Users/user/.zshrc with .NET PATH
✅ .NET CLI is available: 9.0.303
✅ System is now synced with all officially supported .NET versions!
```

---

## 🛠️ Advanced Usage

### Dry Run Mode

Preview changes before execution:

```bash
# Node.js tool
./update-node.sh --dry-run

# .NET tool
./update-dotnet.sh --dry-run
```

### Quiet Mode

Minimal output for automation:

```bash
# Node.js tool
./update-node.sh --quiet

# .NET tool
./update-dotnet.sh --quiet
```

### Custom Installation Directory (.NET only)

```bash
./update-dotnet.sh --dotnet-root /custom/path/.dotnet
```

## 🔍 Troubleshooting

### Common Resolution Steps

#### "nvm: command not found"

- Verify NVM installation and shell profile configuration
- Restart your terminal session or execute: `source ~/.bashrc` (or `~/.zshrc`)

#### Permission denied

- Grant execution permissions: `chmod +x update-node.sh` or `chmod +x update-dotnet.sh`

#### Installation timeouts or failures

- Verify network connectivity and firewall settings
- Confirm access to Node.js and Microsoft download servers

### Diagnostic Information

1. **Review Detailed Logs**: Both tools maintain comprehensive operation logs
   - Node.js: `~/.node-sync.log`
   - .NET: `~/.dotnet-sync.log`

2. **Enable Verbose Output**: Remove `--quiet` flag for detailed operational feedback

3. **Preview Mode**: Utilize `--dry-run` to examine planned changes without execution

## 📊 Key Benefits

### Node.js Tool Advantages

- 🛡️ **Production-Ready Focus**: Installs only stable, enterprise-grade versions
- 🎯 **Smart LTS Management**: Prioritizes Long Term Support versions for stability
- 🧹 **Intelligent Maintenance**: Automated cleanup of deprecated and unsupported versions
- ⚡ **Optimized Performance**: Fast execution with concurrent operations
- 📝 **Comprehensive Diagnostics**: Detailed logging and troubleshooting capabilities

### .NET Tool Advantages

- 🛡️ **Complete Coverage**: Manages all active LTS and Current release versions
- 🌐 **Cross-Platform Excellence**: Native support for Linux and macOS environments
- 🔧 **Seamless Integration**: Automatic environment and PATH configuration
- 🧹 **Lifecycle Management**: Intelligent exclusion of End-of-Life versions
- 📝 **Enterprise Logging**: Comprehensive audit trails and error diagnostics

## 🤝 Contributing

We welcome contributions from the community! Please review our contributing guidelines for information on:

- Code standards and best practices
- Testing and validation requirements
- Pull request submission process
- Issue reporting and feature requests

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for complete terms.

## 🔗 Resources

### Node.js Resources

- [Node.js Release Schedule](https://nodejs.org/en/about/releases/) - Official support timeline and LTS information
- [NVM Documentation](https://github.com/nvm-sh/nvm) - Complete Node Version Manager guide
- [Node.js Documentation](https://nodejs.org/en/docs/) - Official Node.js reference

### .NET Resources

- [.NET Release Policy](https://dotnet.microsoft.com/en-us/platform/support/policy/dotnet-core) - Microsoft's official support policy
- [.NET Downloads](https://dotnet.microsoft.com/en-us/download) - Official SDK and runtime downloads
- [.NET Documentation](https://docs.microsoft.com/en-us/dotnet/) - Comprehensive .NET development guide

---

**Engineered for developers who demand reliable, automated development environments.**
