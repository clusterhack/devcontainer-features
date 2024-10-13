#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive

goplatform_guess() {
  # XXX Kludge that should work for Intel and Apple silicon; should be sufficient...
  #   Couldn't find a simple way to get Go platform (without installing go)
  #   This is for fzf binaries (which is written in go)
  [[ $(arch) == x86_64 ]] && echo linux_amd64 || echo linux_arm64
}

# KNOWN_THEMES=(p10k agnoster)
# KNOWN_PLUGINS=(fzf fzf-tab virtualenv git per-directory-history colorize zsh-syntax-highlighting)
FZF_VARIANT=${FZF_VARIANT:-$(goplatform_guess)}
FZF_VERSION=${FZF_VERSION:-latest}  # TODO? Make feature parameter
FZF_INSTALL_ROOT=${FZF_INSTALL_ROOT:-/usr/local/bin}

FEATURE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"  # For copying files

SETUPSCRIPT=/usr/local/bin/ohmyzsh-setup.sh  # For lifecycle hook

die() {
  echo -e "$@"
  exit 1
}

install_user_file() {
  # $1 src relative to feature directory
  # $2 container path relative to user home
  cp "${FEATURE_DIR}/$1" "${USER_HOME}/$2"
  chown "$USERNAME.$USERNAME" "${USER_HOME}/$2"
}

append_user_zshrc() {
  # $1 snippet src relative to feature directory
  cat "${FEATURE_DIR}/$1" >> "${USER_HOME}/.zshrc"
}

setup_replace_in_user_file() {
  local tag=$1       # Placeholder tag in file; indentation will be matched
  local subfile=$2   # Path of file with replacement text, relative to repo root
  local filename=$3  # Path of file to be modified, relative to user home

  [ -z "$subfile" ] && return

  echo "expand_file \"${USER_HOME}/${filename}\" \"${tag}\" \"${subfile}\"" >>"$SETUPSCRIPT"
}


echo "Activating feature 'ohmyzsh-plugins'"

[ "$(id -u)" -eq 0 ] || die 'Script must be run as root'

# Username detection based on https://github.com/devcontainers/features/main/src/conda
USERNAME=${USERNAME:-"${_REMOTE_USER:-automatic}"}
if [[ ${USERNAME} == "auto" || ${USERNAME} == "automatic" ]]; then
  USERNAME=""
  POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
  for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
    if id -u "${CURRENT_USER}" > /dev/null 2>&1; then
      USERNAME="${CURRENT_USER}"
      break
    fi
  done
  if [[ ${USERNAME} == "" ]]; then
    USERNAME=root
  fi
elif [[ ${USERNAME} == "none" ]] || ! id -u "${USERNAME}" > /dev/null 2>&1; then
  USERNAME=root
fi

USER_HOME=$(getent passwd "$USERNAME" | cut -d: -f6)
# USER_HOME=${USER_HOME:-"/home/$USERNAME"}
[ -d "$USER_HOME" ] || die "User home directory ${USER_HOME} does not exist"

type -p zsh >/dev/null || die 'zsh not found in container'
[ -d "$USER_HOME/.oh-my-zsh" ] || die 'Oh My Zsh not found in user home'

ZSH_CUSTOM=${ZSH_CUSTOM:-"$USER_HOME/.oh-my-zsh/custom"}

# Set default values; some may be overwritten below
ZSHRC_THEME=$THEME
IFS=' ' read -ra ZSHRC_PLUGINS <<<"$PLUGINS"

DISABLE_AUTOUPDATE="${DISABLEAUTOUPDATE:-true}"
INSTALL_ALIASES="${INSTALLALIASES:-true}"
EXTRA_ALIASES="${EXTRAALIASES:-}"
EXTRA_P10K_CUSTOMIZATIONS="${EXTRAPOWERLEVEL10KCUSTOMIZATIONS:-}"
EXTRA_AGNOSTER_CUSTOMIZATIONS="${EXTRAAGNOSTERCUSTOMIZATIONS:-}"


is_plugin_selected() {
  local query=$1

  for p in "${ZSHRC_PLUGINS[@]}"; do
    [[ $p == "$query" ]] && return 0
  done
  return 1
}

# is_plugin_known() {
#   local query="$1"
#   # TODO
# }


# Write rcfile setup script (called by devcontainer lifecycle hooks)
tee "$SETUPSCRIPT" >/dev/null <<"EOF"
#! /bin/bash 

msg () {
  echo "$@" 1>&2
}

die () {
  msg "$@"
  exit 1
}

# TODO Refactor the expand_*() functions...

expand_text() {
  local dstfile=$1  # Container path of file to modify
  local tag=$2      # Placeholder tag in file; will be anchored to start of line
  local subtxt=$3   # Text that will replace each line matching the tag

  # Replace newline chars with '\n' escape; from https://stackoverflow.com/a/38674872
  local subtxt_escaped
  subtxt_escaped=$(awk -v ORS='\\n' '1' <<<"${subtxt}") 
  sed -i -E 's|^'"${tag}"'|'"${subtxt_escaped}"'|g' "${dstfile}"
}

unexpand_file() {
  local dstfile=$1
  local tag=$2

  local begin_tagline tagline_count
  begin_tagline=$(grep -E '^[[:blank:]]*'"${tag} - BEGIN" ${dstfile})
  tagline_count=$(wc -l <<<"${begin_tagline}")  # This is 1 even if $begin_tagline is empty...

  [[ -z $begin_tagline ]] && return
  [[ $tagline_count -gt 1 ]] && die "ERROR: Begin tag '${tag} - BEGIN' occurs more than once in ${dstfile}"

  msg "INFO: Removing prior modifications in ${dstfile}"

  local indent_prefix
  indent_prefix=$(grep -E -o '^[[:blank:]]*' <<<"${begin_tagline}")
  local indented_tag="${indent_prefix}${tag}"

  grep -q -E "^${indented_tag} - END" "${dstfile}" || die "ERROR: Matching ending tag not found in ${dstfile}"

  sed -i -E "/^${indented_tag} - BEGIN/,/^{$indented_tag} - END/c\\${indented_tag}" "${dstfile}"
}

expand_file() {
  shopt -s extglob

  local dstfile=$1
  local tag=$2
  local subfile=$3

  [[ -f "${dstfile}" ]] || die "ERROR: Target file ${dstfile} does not exist"
  [[ -f "${subfile}" ]] || die "ERROR: Substitution file ${subfile} does not exist"

  unexpand_file "${dstfile}" "${tag}"

  local tagline tagline_count
  tagline=$(grep -E '^[[:blank:]]*'"${tag}" ${dstfile})
  tagline_count=$(wc -l <<<"${tagline}")  # This is 1 even if $tagline is empty

  [[ -z $tagline ]] && die "ERROR: Tag '${tag}' does not occur in ${dstfile}"
  [[ $tagline_count -gt 1 ]] && die "ERROR: Tag '${tag}' occurs more than once in ${dstfile}"

  echo "Modifying ${dstfile}"

  local indent_prefix indented_tag
  indent_prefix=$(grep -E -o '^[[:blank:]]*' <<<"${tagline}")
  indented_tag="${indent_prefix}${tag}"
  local subtxt_escaped  # ..and indented (first)
  subtxt_escaped=$(sed 's|^|'"${indent_prefix}"'|;s|\\|\\\\|g' "${subfile}" | awk -v ORS='\\n' '1')
  subtxt_escaped="${subtxt_escaped%%+(\\n)}\n"  # Ensure value ends with single '\n'
  sed -i -E 's|^[[:blank:]]*'"${tag}"'|'"${indented_tag} - BEGIN\n${subtxt_escaped}${indented_tag} - END"'|g' "${dstfile}"
}

# Container and repo specific setup
echo "Setting up extra customizations"
EOF
chmod +x "$SETUPSCRIPT"


# Install powerlevel10k
if [[ $THEME == p10k || $THEME == powerlevel10k ]]; then
  ZSHRC_THEME="powerlevel10k/powerlevel10k"

  echo 'Installing powerlevel10k (GitHub source)'
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM}/themes/powerlevel10k"

  echo 'Installing powerlevel10k dotfiles'
  install_user_file profile/p10k.zsh .p10k.zsh
  install_user_file profile/p10k-custom.zsh .p10k-custom.zsh
  setup_replace_in_user_file '# %%EXTRA_CUSTOMIZATIONS' "$EXTRA_P10K_CUSTOMIZATIONS" .p10k-custom.zsh
  append_user_zshrc profile/zshrc_p10k_snippet.zsh
fi

# Install agnoster customizations
if [[ $THEME == agnoster ]]; then
  echo "Installing agnoster customizations"
  install_user_file profile/agnoster-custom.zsh .agnoster-custom.zsh
  setup_replace_in_user_file '# %%EXTRA_CUSTOMIZATIONS' "$EXTRA_AGNOSTER_CUSTOMIZATIONS" .agnoster-custom.zsh
  append_user_zshrc profile/zshrc_agnoster_snippet.zsh
fi

# Install fzf binary
if is_plugin_selected fzf || is_plugin_selected fzf-tab; then
  echo 'Installing fzf (GitHub binary release)'
  if [[ $FZF_VERSION == latest ]]; then
    FZF_VERSION=$(
      curl -sSL "https://api.github.com/repos/junegunn/fzf/tags" | 
      grep -oP '"name": "v\K([^"])+"' |
      tr -d \" |
      sort -rV |
      head -1
    )
  fi
  echo "Downloading and extracting fzf v${FZF_VERSION}"
  FZF_URL="https://github.com/junegunn/fzf/releases/download/v{$FZF_VERSION}/fzf-${FZF_VERSION}-${FZF_VARIANT}.tar.gz"
  (
    cd "$FZF_INSTALL_ROOT" &&
    curl -L -s "$FZF_URL" | tar --keep-newer-files -zxf -
  )
fi

# Install pygments (for pygmentize)
if is_plugin_selected colorize; then
  echo 'Installng pygmentize (apt)'
  apt-get update -y
  apt-get -y install --no-install-recommends python3-pygments
  # TODO! Add ZSH_COLORIZE_TOOL=pygmentize ZSH_COLORIZE_STYLE=material to .zshrc *BEFORE* sourcing ohmyzsh

fi

# Install fzf-tab
if is_plugin_selected fzf-tab; then
  echo 'Installing fzf-tab (GitHub source)'
  git clone --depth=1 https://github.com/Aloxaf/fzf-tab "${ZSH_CUSTOM}/plugins/fzf-tab"
fi

# Install zsh-autosuggestions
if is_plugin_selected zsh-autosuggestions; then
  echo 'Installing zsh-autosuggestions (GitHub source)'
  git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
fi

# Install zsh-syntax-highlighting
if is_plugin_selected zsh-syntax-highlighting; then
  echo 'Installing zsh-syntax-highlighting (GitHub source)'
  git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
  # Ensure it's the last plugin (assumes no spaces in any ZSHRC_PLUGINS element)
  IFS=' ' read -ra ZSHRC_PLUGINS <<<"${ZSHRC_PLUGINS[@]/zsh-syntax-highlighting}"  # Remove first...
  ZSHRC_PLUGINS+=( zsh-syntax-highlighting )  # ...then append
fi

if [[ $INSTALL_ALIASES == true ]]; then
  echo "Installing aliases"
  install_user_file profile/aliases.zsh .zsh_aliases
  setup_replace_in_user_file '# %%EXTRA_ALIASES' "$EXTRA_ALIASES" .zsh_aliases
  append_user_zshrc profile/zshrc_aliases_snippet.zsh
fi

echo "Modifying ZSH_THEME and plugins in zshrc"
sed -i -E 's|^ZSH_THEME=.*$|ZSH_THEME="'"$ZSHRC_THEME"'"|g' "${USER_HOME}/.zshrc"
sed -i -E 's|^plugins=.*$|plugins=('"${ZSHRC_PLUGINS[*]}"')|g' "${USER_HOME}/.zshrc"

if [[ $DISABLE_AUTOUPDATE == true ]]; then
  echo "Disabling Oh My Zsh auto-updates"
  sed -i -E 's|^# (zstyle '"'"':omz:update'"'"' mode disabled.*)$|\1|g' "${USER_HOME}/.zshrc"
fi
