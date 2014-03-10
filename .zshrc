autoload -Uz add-zsh-hook

# ================================
# General Settings
# ================================
export EDITOR=vim
export LANG=ja_JP.UTF-8

setopt auto_pushd
setopt correct
setopt magic_equal_subst

## Complement
autoload -U compinit; compinit -u
setopt auto_list
setopt auto_menu
setopt list_packed
setopt list_types
bindkey "^[[Z" reverse-menu-complete

## Glob
setopt extended_glob

## History
HISTFILE=~/.zsh_history
HISTSIZE=9999
SAVEHIST=9999
setopt bang_hist
setopt extended_history
setopt hist_ignore_dups
setopt share_history
setopt hist_reduce_blanks

autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^P" history-beginning-search-backward-end
bindkey "^N" history-beginning-search-forward-end

## Path
NODE_BIN=$HOME/.nodebrew/current/bin
ANDROID_TOOLS=/opt/local/android-sdk-macosx/tools
ANDROID_PLATFORM_TOOLS=/opt/local/android-sdk-macosx/platform-tools
export PATH="$HOME/bin:$PATH:$NODE_BIN:$ANDROID_TOOLS:$ANDROID_PLATFORM_TOOLS"

## Alias
alias ll='ls -l'
alias la='ls -la'
alias pd='popd'
alias vi='vim'
alias st='stree'


# ================================
# Look and Feel Settings
# ================================
export LSCOLORS=DxGxcxdxCxegedabagacad
export CLICOLOR=1
export TERM=xterm-256color

## Prompt
autoload -U colors; colors
autoload -Uz vcs_info

zstyle ':vcs_info:*' formats '[%s:%r#%b]'
zstyle ':vcs_info:*' actionformats '(%a) [%s:%r#%b]'
function _precmd_vcs_info() {
  psvar=()
  LANG=ja_JP.UTF-8 vcs_info
  [[ -n "$vcs_info_msg_0_" ]] && psvar[1]="$vcs_info_msg_0_"
}
add-zsh-hook precmd _precmd_vcs_info

local PROMPT_COLOR=yellow
if [ ${UID} -eq 0 ]; then
  local PROMPT_COLOR=red
fi

PROMPT="
%F{$PROMPT_COLOR}%n@%m: %~%f
%B%(!,#,$)%b "

RPROMPT="%1(v|%F{green}%1v%f|)"


# ================================
# Other Settings
# ================================

## sbt
export SBT_OPTS="-Xmx2048m -XX:MaxPermSize=2048m -XX:ReservedCodeCacheSize=256m"

## Android
export ANDROID_HOME=/opt/local/android-sdk-macosx
export ANDROID_SDK_HOME="$ANDROID_HOME"
export ANDROID_SDK_ROOT="$ANDROID_HOME"

## karma
export CHROME_BIN="$(pwd)/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

