if [[ -z "$VIRTUAL_ENV" ]]; then
  # Show warning message (should hopefully reduce dangerous confusion?)
  prompt_virtualenv() { prompt_segment red white '\u26a0 \u27e8no python env\u27e9' }
else
  # Devcontainer sets VIRTUAL_ENV_DISABLE_PROMPT, so no need to check...
  prompt_virtualenv() { prompt_segment blue black "(${VIRTUAL_ENV:t:gs/%/%%})" }
fi
