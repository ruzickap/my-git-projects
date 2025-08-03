# Multi-Gitter Repository Management

This directory contains configuration and scripts for managing multiple GitHub
repositories using [multi-gitter](https://github.com/lindell/multi-gitter).

## Overview

Multi-gitter is a tool for updating multiple repositories at once. This setup
automatically applies standardized configuration files, GitHub workflows, and
development tools across all your repositories.

## Files

- `config.yaml` - Multi-gitter configuration file
- `multi-gitter-run-script.sh` - Script that runs for each repository
- `README.md` - This documentation file

## Usage

### Prerequisites

1. Install [multi-gitter](https://github.com/lindell/multi-gitter)
2. Install [rclone](https://rclone.org/)
3. Ensure you have Git configured with appropriate authentication

### Environment Variables

The script supports the following environment variables:

- `GH_REPO_DEFAULTS_BASE` - Base directory for repository defaults
  (default: `$HOME/git/my-git-projects/gh-repo-defaults`)
- `RCLONE_OPTS` - Additional options for rclone
  (default: `--verbose --stats 0`)
- `DEBUG` - Set to `true` to enable debug mode with verbose output

### Running Multi-Gitter

```bash
# Dry run (recommended first)
multi-gitter run --config config.yaml --dry-run ./multi-gitter-run-script.sh

# Interactive run
multi-gitter run --config config.yaml ./multi-gitter-run-script.sh

# Non-interactive run (use with caution)
multi-gitter run --config config.yaml --interactive=false ./multi-gitter-run-script.sh
```

### Repository Categories

The script handles different repository types:

1. **Action repositories** (`ruzickap/action-*`) - GitHub Action templates
2. **Ansible repositories** (`ruzickap/ansible-*`) - Ansible playbook
   configurations
3. **LaTeX repositories** (`ruzickap/cheatsheet-*`, `ruzickap/cv`) - LaTeX
   document templates
4. **Hugo repositories** (`ruzickap/petr.ruzicka.dev`, `ruzickap/xvx.cz`) -
   Hugo site configurations
5. **Special repositories** - Custom handling for specific repositories

## Configuration

### Repository Selection

Edit `config.yaml` to:

- Add repositories to `skip-repo` list to exclude them
- Add private repositories to the `repo` list
- Modify the `user` field to target different GitHub users

### Script Behavior

The script:

1. Validates the environment and required tools
2. Copies base defaults to all repositories
3. Applies category-specific configurations
4. Handles special cases for specific repositories
5. Provides detailed logging and error handling

## Error Handling

The improved script includes:

- Environment validation
- Command existence checks
- Proper error propagation
- Detailed logging with timestamps
- Graceful handling of missing files

## Debugging

Enable debug mode:

```bash
DEBUG=true multi-gitter run --config config.yaml ./multi-gitter-run-script.sh
```

## Safety Features

- **Dry run mode** - Test changes without applying them
- **Interactive mode** - Review changes before committing
- **Error handling** - Script stops on failures
- **Validation** - Checks for required tools and directories
- **Logging** - Comprehensive output for troubleshooting

## Customization

To add support for new repository types:

1. Add a new handler function (e.g., `handle_newtype_repos()`)
2. Add the pattern to the main case statement in `process_repository()`
3. Update this documentation

## Security Considerations

- Review all changes in dry-run mode first
- Use SSH authentication for private repositories
- Regularly audit the repositories being modified
- Consider using branch protection rules on target repositories
