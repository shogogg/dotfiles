#!/bin/bash

base_dir="$(cd -- "$(dirname -- "${BASH_SOURCE}")"; pwd)"
dot_files=(
  .anyenv
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
