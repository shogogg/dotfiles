#!/bin/bash

base_dir="$(cd -- "$(dirname -- "${BASH_SOURCE}")"; pwd)"
dot_files=(
  .anyenv
  .editorconfig
  .gemrc
  .gitconfig
  .gitignore
  .sbtconfig
  .sbtrc
  .vim
  .vimrc
  .zsh.d
  .zshrc
)

for file in ${dot_files[@]}; do
  rm -f "${HOME}/${file}"
  ln -s "${base_dir}/${file}" "${HOME}/"
done

# setup submodules
git submodule init
git submodule update

# setup anyenv
export PATH="$HOME/.anyenv/bin:$PATH"
eval "$(anyenv init -)"

# setup anyenv-update
mkdir -p $(anyenv root)/plugins
git clone https://github.com/znz/anyenv-update.git $(anyenv root)/plugins/anyenv-update

# setup ndenv
if [ -z "$(anyenv envs | grep ndenv)" ]; then
  anyenv install ndenv
fi

# setup pyenv
if [ -z "$(anyenv envs | grep pyenv)" ]; then
  anyenv install pyenv
fi

# setup rbenv
if [ -z "$(anyenv envs | grep rbenv)" ]; then
  anyenv install rbenv
fi
if cd ~/.anyenv/envs/rbenv/plugins; then
  test -d rbenv-binstubs || git clone git@github.com:ianheggie/rbenv-binstubs.git
  test -d rbenv-gem-rehash || git clone git@github.com:sstephenson/rbenv-gem-rehash.git
fi
