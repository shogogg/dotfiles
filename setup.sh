#!/bin/bash

base_dir="$(cd -- "$(dirname -- "${BASH_SOURCE}")"; pwd)"
dot_files=(
  .editorconfig
  .gemrc
  .gitconfig
  .gitignore
  .sbtconfig
  .sbtrc
  .vim
  .vimrc
  .zshenv
)

for file in ${dot_files[@]}; do
  rm -f "${HOME}/${file}"
  ln -s "${base_dir}/${file}" "${HOME}/"
done

# create .config directory if not exists
if [[ ! -d "${HOME}/.config" ]]; then
  mkdir "${HOME}/.config"
fi

# create .config/brewfile
rm -rf "${HOME}/.config/brewfile"
ln -s "${base_dir}/.config/brewfile" "${HOME}/.config/"

# create .config/psysh
rm -rf "${HOME}/.config/psysh"
mkdir "${HOME}/.config/psysh"
ln -s "${base_dir}/.config/psysh/config.php" "${HOME}/.config/psysh/"

# create .config/zsh
rm -rf "${HOME}/.config/zsh"
ln -s "${base_dir}/.config/zsh" "${HOME}/.config/"

# setup submodules
git submodule init
git submodule update
