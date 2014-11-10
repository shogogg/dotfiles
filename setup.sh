#!/bin/bash

BASE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE}")"; pwd)"
DOT_FILES=(
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

for file in ${DOT_FILES[@]}; do
  rm -f ~/$file
  ln -s "$BASE_DIR/$file" ~/
done

# setup submodules
git submodule init
git submodule update
