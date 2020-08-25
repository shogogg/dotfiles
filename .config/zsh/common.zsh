#
# anyenv
#
eval "$(anyenv init -)"

anyenv_root="$(anyenv root)"
anyenv_plugins="$anyenv_root/plugins"
anyenv_update="$anyenv_root/plugins/anyenv-update"

[[ -d $anyenv_plugins ]] || mkdir -p "$anyenv_plugins"
[[ -d $anyenv_update ]] || git clone https://github.com/znz/anyenv-update.git "$anyenv_update"

#
# composer
#
export COMPOSER_MEMORY_LIMIT=-1
if [[ -d ~/.composer ]]; then
  path=(~/.composer/vendor/bin $path)
fi

#
# direnv
#
eval "$(direnv hook zsh)"
export DIRENV_LOG_FORMAT=""

#
# fzf
#
[[ -f "${HOME}/.fzf.zsh" ]] && source "${HOME}/.fzf.zsh"
export FZF_DEFAULT_OPTS='--height 50% --inline-info --reverse'

#
# golang
#
export GOPATH="$HOME/.go/"

#
# gpg-agent
#
export GPG_TTY=$(/usr/bin/tty)
export SSH_AUTH_SOCK="$HOME/.gnupg/S.gpg-agent.ssh"

gpgconf --launch gpg-agent

#
# grep
#
export GREP_OPTIONS='--color=auto'

#
# hyper-tab-icons-plus
#
title() {
  export TITLE_OVERRIDDEN=1
  echo -en "\e]0;$*\a"
}
auto_title() {
  export TITLE_OVERRIDDEN=0
}
tab_title_precmd() {
  if [[ $TITLE_OVERRIDDEN == 1 ]]; then
    return
  fi
  pwd=$(pwd)
  cwd=${pwd##*/}
  print -Pn "\e]0;$cwd\a"
}
tab_title_preexec() {
  if [[ $TITLE_OVERRIDDEN == 1 ]]; then
    return
  fi
  pwd=$(pwd)
  cwd=${pwd##*/}
  printf "\033]0;%s\a" "${1%% *} | $cwd"
}
auto_title
precmd_functions=($precmd_functions tab_title_precmd)
preexec_functions=($preexec_functions tab_title_preexec)

#
# phpbrew
#
export PHPBREW_RC_ENABLE=1

if ! hash phpbrew; then
  curl -L -O https://github.com/phpbrew/phpbrew/raw/master/phpbrew \
    && chmod +x phpbrew \
    && mv phpbrew /usr/local/bin \
    && phpbrew init \
    && echo '#compdef phpbrew' > /usr/local/share/zsh/site-functions/_phpbrew \
    && phpbrew zsh --bind phpbrew --program phpbrew >> /usr/local/share/zsh/site-functions/_phpbrew
fi
[[ -e ~/.phpbrew/bashrc ]] && source ~/.phpbrew/bashrc

#
# sbt
#
export SBT_OPTS=(
  -Xmx2048m
  -XX:ReservedCodeCacheSize=256m
)

#
# starship
#
eval "$(starship init zsh)"
