# Contributing to Node.js Version Manager Sync Tool

Thank you for your interest in contributing! We welcome contributions from everyone.

## Code of Conduct

This project adheres to a code of conduct. By participating, you are expected to uphold this code.

## How to Contribute

### Reporting Bugs

1. **Check existing issues** to avoid duplicates
2. **Use the bug report template** when creating new issues
3. **Include system information**: OS, shell, NVM version, Node.js versions
4. **Provide reproduction steps** with expected vs actual behavior

### Suggesting Features

1. **Check existing feature requests** to avoid duplicates
2. **Use the feature request template**
3. **Explain the use case** and why it would benefit users
4. **Consider implementation complexity** and backwards compatibility

### Code Contributions

#### Development Setup

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/theroks/node-up-to-date.git
   cd node-up-to-date
   ```
3. Create a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

#### Coding Standards

- **Shell Script Standards**: Follow [ShellCheck](https://www.shellcheck.net/) recommendations
- **Documentation**: Update README.md for user-facing changes
- **Comments**: Add comments for complex logic
- **Error Handling**: Include proper error handling and user feedback

#### Testing

Before submitting your pull request:

1. **Test the script** with different NVM setups
2. **Verify error handling** with invalid inputs
3. **Check compatibility** with different shells (bash, zsh)
4. **Run linting**: Use shellcheck on the script

#### Pull Request Process

1. **Update documentation** if you're changing functionality
2. **Add/update tests** for your changes
3. **Ensure all tests pass**
4. **Write clear commit messages**:
   ```
   feat: add support for custom version selection

   - Allow users to specify which versions to install
   - Add --interactive flag for guided selection
   - Update documentation with new options
   ```

5. **Submit the pull request** with:
   - Clear description of changes
   - Link to related issues
   - Screenshots/examples if applicable

### Review Process

1. **Automated checks** will run on your PR
2. **Code review** by maintainers
3. **Feedback incorporation** (if needed)
4. **Merge** once approved

## Development Guidelines

### Script Structure

- Keep functions small and focused
- Use descriptive variable names
- Handle edge cases gracefully
- Provide informative error messages

### Documentation

- Update README.md for user-facing changes
- Add inline comments for complex logic
- Include examples for new features

### Backwards Compatibility

- Maintain compatibility with existing usage
- Deprecate features before removing them
- Provide migration guides for breaking changes

## Questions?

- **General questions**: Use [Discussions](https://github.com/theroks/node-up-to-date/discussions)
- **Bug reports**: Use [Issues](https://github.com/theroks/node-up-to-date/issues)
- **Feature requests**: Use [Issues](https://github.com/theroks/node-up-to-date/issues) with the feature label

Thank you for contributing! 🎉
