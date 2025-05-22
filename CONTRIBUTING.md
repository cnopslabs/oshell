# Contributing to oshell

Welcome! We appreciate your interest in contributing to the oshell project.
Please review the guidelines below before making a contribution.

For significant changes or new features:

## Pull Requests

When submitting a Pull Request (PR):

1. Choose the correct template:
   - Feature
   - Bugfix
   - Chore
   - Documentation
2. Follow the checklist included in the template.
3. Reference any related Issue 
4. Ensure your branch is named appropriately:
   - `feature/your-feature-name`
   - `bugfix/your-bug-description`
   - `chore/task-description`
   - `docs/documentation-update`

## Code Style

- Follow shell scripting best practices.
- Run `shellcheck` on your scripts before committing to ensure POSIX/Bash compatibility.
- Write clear, descriptive comments for functions and complex code blocks.
- Use meaningful variable and function names.
- Format your code consistently with the existing codebase.
- Write clear commit messages following the format: `<type>: <short description>`.

## Testing

Before submitting your changes:

1. Ensure all scripts pass syntax checking with `zsh -n your-script.sh`.
2. Run shellcheck to verify there are no linting issues: `shellcheck --shell=bash your-script.sh`.
3. Test the execution of your scripts to ensure they work as expected.

## Continuous Integration

Our CI workflow runs automatically on all branches. Ensure your changes:

1. Pass zsh syntax checks
2. Pass shellcheck linting
3. Execute successfully

The CI workflow will automatically run when you create a pull request.

## Project Structure

- `oshell.sh`: Main script that provides the core functionality
- `oci_auth_refresher.sh`: Script for refreshing OCI authentication
- `tenancy-map.yaml`: Example configuration for OCI tenancies
- `.zshrc_EXAMPLE.sh`: Example ZSH configuration

## Need Help?

If you have questions about the process, templates, or anything else, feel free to open a discussion or reach out to a maintainer.

Thanks for contributing and helping improve oshell!