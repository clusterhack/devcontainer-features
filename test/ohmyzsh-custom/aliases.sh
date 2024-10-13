#!/bin/bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
check "alias placeholder removed" bash -c '! grep -q "^# %%ALIASES" "$HOME/.zsh_aliases"'
check "foo in aliases" grep -q "^foo='echo FOO'" "$HOME/.zsh_aliases"
check "bar in aliases" grep -q "^bar='echo BAR'" "$HOME/.zsh_aliases"
# TODO check zsh config..?

# Report results
reportResults
