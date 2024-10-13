#!/bin/bash

# This test file will be executed against an auto-generated devcontainer.json that
# includes the 'ohmyzsh-custom' feature with no options.
#
# For more information, see: https://github.com/devcontainers/cli/blob/main/docs/features/test.md

set -e

source dev-container-features-test-lib  # for check and reportResults

# XXX DBG
check "pwd $(pwd)" true
check "ls $(ls -1)" true

# Feature-specific tests
check "aliases installed" test -f "$HOME/.zsh_aliases"
check "alias placeholder removed" bash -c '! grep -q "^# %%ALIASES" "$HOME/.zsh_aliases"'
check "powerlevel10k" test -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
check "powerlevel10k config" test -f "$HOME/.p10k.zsh" -a -f "$HOME/.p10k-custom.zsh"

# Report results
reportResults
