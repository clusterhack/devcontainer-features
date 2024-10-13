#!/bin/bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
check "fzf" fzf --version
# TODO check zsh config..?

# Report results
reportResults
