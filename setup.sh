#!/bin/sh

BASE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE}")"; pwd)"
DOT_FILES=(.gitconfig .gitignore .sbtrc .vimrc .zshrc)

for file in ${DOT_FILES[@]}; do
  rm -rf ~/$file
  ln -s "$BASE_DIR/$file" ~/
done

# install neobundle.vim
NEOBUNDLE="~/.vim/bundle/neobundle.vim"
if [ ! -d $NEOBUNDLE ]; then
  git clone git://github.com/Shougo/neobundle.vim $NEOBUNDLE
fi

