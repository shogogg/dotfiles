if ! hash phpbrew; then
  curl -L -O https://github.com/phpbrew/phpbrew/raw/master/phpbrew \
    && chmod +x phpbrew \
    && mv phpbrew /usr/local/bin \
    && phpbrew init
fi

[[ -e ~/.phpbrew/bashrc ]] && source ~/.phpbrew/bashrc

export PHPBREW_RC_ENABLE=1
