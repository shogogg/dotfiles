#!/bin/bash

BASE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE}")"; pwd)"
DOT_FILES=(.gemrc .gitconfig .gitignore .sbtconfig .sbtrc .vimrc .zshrc)

for file in ${DOT_FILES[@]}; do
  rm -rf ~/$file
  ln -s "$BASE_DIR/$file" ~/
done

# setup vim
if [ ! -d ~/.vim/bundle/neobundle.vim ]; then
  mkdir -p ~/.vim/bundle/neobundle.vim
  git clone git://github.com/Shougo/neobundle.vim ~/.vim/bundle/neobundle.vim
fi
if [ ! -f ~/.vim/colors/molokai.vim ]; then
  mkdir -p ~/.vim/colors 
  curl https://raw.github.com/tomasr/molokai/master/colors/molokai.vim > ~/.vim/colors/molokai.vim
fi

# setup zsh-notify
if [ ! -d ~/.zsh.d ]; then
  mkdir ~/.zsh.d
fi
if [ ! -f ~/.zsh.d/zsh-notify/notify.plugin.zsh ]; then
  git clone git@github.com:marzocchi/zsh-notify.git ~/.zsh.d/zsh-notify
fi
