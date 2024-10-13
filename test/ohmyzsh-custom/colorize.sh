#!/bin/bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
check "pygmentize" pygmentize -V
# TODO Check zsh config somehow?

# Report results
reportResults
