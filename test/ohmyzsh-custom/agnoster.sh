#!/bin/bash

set -e

source dev-container-features-test-lib

check_extra_customizations() {
  grep -q '# %%EXTRA_CUSTOMIZATIONS - BEGIN' "$HOME/.agnoster-custom.zsh" && \
  grep -q '# %%EXTRA_CUSTOMIZATIONS - END' "$HOME/.agnoster-custom.zsh" && \
  [[ $(grep -c 'prompt_virtualenv()' "$HOME/.agnoster-custom.zsh") -eq 2 ]]
}

# Feature-specific tests
check "agnoster config" test -f "$HOME/.agnoster-custom.zsh"
check "no powerlevel10k" test ! -e "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
check "agnoster extra customizations" check_extra_customizations

# Report results
reportResults
