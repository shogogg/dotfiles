eval "$(anyenv init -)"

anyenv_root="$(anyenv root)"

anyenv_plugins="${anyenv_root}/plugins"
if [[ ! -d "${anyenv_plugins}" ]]; then
  mkdir -p "${anyenv_plugins}"
fi

anyenv_update="${anyenv_root}/plugins/anyenv-update"
if [[ ! -d "${anyenv_update}" ]]; then
  git clone https://github.com/znz/anyenv-update.git "${anyenv_update}"
fi
