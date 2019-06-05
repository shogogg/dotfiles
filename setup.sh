#!/bin/bash

base_dir="$(cd -- "$(dirname -- "${BASH_SOURCE}")"; pwd)"
dot_files=(
  .editorconfig
  .gemrc
  .gitconfig
  .gitignore
  .hyper.js
  .phpbrewrc
  .sbtconfig
  .sbtrc
  .vim
  .vimrc
  .zshenv
)

for file in ${dot_files[@]}; do
  rm -f ~/$file
  ln -s "$base_dir/$file" ~/
done

# create .config directory if not exists
if [[ ! -d ~/.config ]]; then
  mkdir ~/.config
fi

# create .config/brewfile
rm -rf ~/.config/brewfile
ln -s "${base_dir}/.config/brewfile" ~/.config/brewfile

# create .config/psysh
rm -rf ~/.config/psysh
mkdir ~/.config/psysh
ln -s "${base_dir}/.config/psysh/config.php" ~/.config/psysh/config.php

# create .config/zsh
rm -rf ~/.config/zsh
ln -s "${base_dir}/.config/zsh" ~/.config/zsh

# setup submodules
git submodule init
git submodule update
