autoload -Uz add-zsh-hook

setopt correct
setopt magic_equal_subst
setopt extended_glob
setopt nonomatch

#
# aliases
#
alias artisan='php artisan'
alias bump='yarn upgrade-interactive'
alias ga='git add'
alias gco='git checkout'
alias grh='git reset --hard'
alias gsp='git stash pop'
alias gss='git add . && git stash save'
alias gst='git status'
alias gu='gitup'
alias la='exa --time-style=long-iso -lha'
alias ll='exa --time-style=long-iso -aghl'
alias ls='exa --time-style=long-iso'
alias pull='git pull'
alias push='git push'
alias st='stree'
alias tinker='php artisan tinker'
alias vi='vim'

#
# completion
#
setopt auto_list
setopt auto_menu
setopt list_packed
setopt list_types
bindkey "^[[Z" reverse-menu-complete

#
# history
#
export HISTFILE=~/.zsh_history
export HISTSIZE=9999
export SAVEHIST=9999

setopt bang_hist
setopt extended_history
setopt hist_ignore_dups
setopt share_history
setopt hist_reduce_blanks

autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end

#
# key bind
#
bindkey -d
bindkey "^A" beginning-of-line
bindkey "^E" end-of-line
bindkey "^L" clear-screen
bindkey "^N" history-beginning-search-forward-end
bindkey "^P" history-beginning-search-backward-end
bindkey "^U" vi-kill-line
bindkey "^W" vi-backward-kill-word
bindkey '\e\C-?' vi-backward-kill-word  # ⌥ + ⌫
bindkey '\e\e[C' vi-forward-word        # ⌥ + →
bindkey '\e\e[D' vi-backward-word       # ⌥ + ←

#
# zplug
#
export ZPLUG_HOME=/usr/local/opt/zplug
export ZPLUG_CACHE_DIR=~/.zplug/cache

source "$ZPLUG_HOME/init.zsh"
source "$ZDOTDIR/zplug.plugins.zsh"
zplug check || zplug install
zplug load

#
# common settings
#
source "$ZDOTDIR/common.zsh"

#
# settings by os
#
case ${OSTYPE} in
  darwin*)
    source "$ZDOTDIR/macos.zsh"
    ;;
  linux*)
    source "$ZDOTDIR/linux.zsh"
    ;;
esac

#
# local functions
#
if [[ -f "$ZDOTDIR/local-functions/index.zsh" ]]; then
  source "$ZDOTDIR/local-functions/index.zsh"
fi
