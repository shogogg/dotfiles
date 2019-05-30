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
if [[ -d ~/.composer ]]; then
  path=(
    ~/.composer/vendor/bin(N-/)
    $path
  )
fi

#
# direnv
#
eval "$(direnv hook zsh)"
export DIRENV_LOG_FORMAT=""

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
# phpbrew
#
export PHPBREW_RC_ENABLE=1

if ! hash phpbrew; then
  curl -L -O https://github.com/phpbrew/phpbrew/raw/master/phpbrew \
    && chmod +x phpbrew \
    && mv phpbrew /usr/local/bin \
    && phpbrew init
fi
[[ -e ~/.phpbrew/bashrc ]] && source ~/.phpbrew/bashrc

#
# sbt
#
export SBT_OPTS=(
  -Xmx2048m
  -XX:ReservedCodeCacheSize=256m
)
