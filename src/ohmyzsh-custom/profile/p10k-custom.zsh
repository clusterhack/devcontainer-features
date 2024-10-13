# Overrides for .p10k.zsh
# Should be sourced at the end of .p10k.zsh

() {
  # Per-directory history customization
  typeset -g POWERLEVEL9K_PER_DIRECTORY_HISTORY_LOCAL_CONTENT_EXPANSION=''
  typeset -g POWERLEVEL9K_PER_DIRECTORY_HISTORY_GLOBAL_CONTENT_EXPANSION=''
  typeset -g POWERLEVEL9K_PER_DIRECTORY_HISTORY_LOCAL_VISUAL_IDENTIFIER_EXPANSION='󰪻'
  typeset -g POWERLEVEL9K_PER_DIRECTORY_HISTORY_GLOBAL_VISUAL_IDENTIFIER_EXPANSION='󱨓'

  # Set directory classes
  typeset -g POWERLEVEL9K_DIR_CLASSES=(
    '/workspaces(|/*)'  WORKSPACE ''
    '~(|/*)'            HOME      ''
    '*'                 DEFAULT   ''
  )

  # Set custom icons for (some of) the directory classes
  typeset -g POWERLEVEL9K_DIR_WORKSPACE_VISUAL_IDENTIFIER_EXPANSION='󰨞'
  typeset -g POWERLEVEL9K_DIR_HOME_VISUAL_IDENTIFIER_EXPANSION=' '

  # VSCode-specific
  typeset -g POWERLEVEL9K_DIR_TRUNCATE_BEFORE_MARKER="first"

  # %%EXTRA_CUSTOMIZATIONS
}
