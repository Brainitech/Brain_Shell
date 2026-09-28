# Contributing to Brain Shell

First off, thank you for considering contributing to Brain Shell! It's people like you that make this project better for everyone.

## Where to Start

- **Bug Reports**: If you find a bug, please open an issue on GitHub. Describe the bug in detail, including steps to reproduce it, your operating system, your compositor, and any relevant logs.
- **Feature Requests**: Have an idea for a new feature? Start a discussion or open an issue to propose it.
- **Code Contributions**: We welcome pull requests! If you're planning a major change, please open an issue or discussion first to ensure your work aligns with the project's goals and architecture.

## Development Setup

1. Fork the repository on GitHub.
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/Brain_Shell.git /path/to/development/location/
   ```
3. Set up the development environment by installing the required dependencies (see `README.md` for a complete list).
4. Run the shell directly using Quickshell:
   ```bash
   quickshell -p /path/to/development/location/Brain_Shell
   ```

## Coding Guidelines

- **Maintain Clean Code**: Keep logic clean and concise. Avoid over-engineering.
- **Preserve Functionality**: Features and fixes should not break existing functionality. If a breaking change is strictly necessary, it must be explicitly mentioned in the PR.
- **Clear Commenting**: Keep comments simple, professional, and easy to understand. Any new logic must be commented properly.
- **AI Usage Guidelines**: If AI is used to generate code, ensure you test and proofread the output rigorously. AI slop will be rejected immediately.

## Pull Request Process

1. **Target Branch Selection**:
   - **Features & Minor Bugs**: Base your branch off and open your Pull Request against the `dev` branch.
   - **Critical Bugs (Hotfixes)**: Base your branch off and open your Pull Request against the `main` branch.
2. **Use the Template**: Fill out the provided PR template entirely.
3. **Clear Definitions**: Clearly define exactly what your feature or fix does in the PR description.

## Code of Conduct

Please note that this project is released with a Contributor Code of Conduct. By participating in this project you agree to abide by its terms. Let's build a welcoming and respectful community.
