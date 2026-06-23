# Contributing to Brain Shell

Thank you for your interest in contributing! To keep the stable release clean and the history readable, we use a standard integration workflow. Please review the following rules before contributing.

## 1. Local Development Setup

To test changes to Brain Shell locally:

### Using NixOS (Recommended if on NixOS)
```bash
nix flake show
nix develop # If a devShell is configured
# Or run directly:
nix run .
```

### Using Arch Linux
Make sure you have all the required dependencies installed (see `CI.yml` or `install.sh` for the full list, including `hyprland`, `qt6-declarative`, `quickshell-git`, etc.).
You can test the shell by executing it with `quickshell`:
```bash
quickshell shell.qml
```

## 2. The Git Workflow
* **Target the `dev` branch:** Always base your new feature or fix branches off of `dev`. 
* **Submit PRs to `dev`:** Do NOT submit Pull Requests to `main`. 
* I will review your PR, merge it into `dev`, and test it alongside other changes.
* Once `dev` is stable, I will handle the final batch merge into `main` for the next release.

## 3. Conventional Commits
All commit messages must follow the [Conventional Commits](https://www.conventionalcommits.org/) standard. Format: `type(scope): brief description`

**Allowed types:**
* `feat:` for new features (e.g., `feat(ui): add dashboard popup`)
* `fix:` for bug fixes (e.g., `fix(updater): resolve crash on startup`)
* `docs:` for documentation updates
* `chore:` for maintenance, dependency updates, or tooling
* `refactor:` for code changes that neither fix a bug nor add a feature

## 4. Quick Command Reference
```bash
git fetch origin
git checkout dev
git pull origin dev
git checkout -b feature/your-feature
# When committing:
git commit -m "feat(module): description of the new feature"
```
