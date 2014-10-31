#!/bin/bash

brew_install(){
  brew install $1 || brew upgrade $1 || true
}

cask_install(){
  brew cask install $1 || true
}

brew update
brew cleanup

brew_install caskroom/cask/brew-cask

brew tap caskroom/homebrew-versions

brew_install ffmpeg
brew_install git
brew_install giter8
brew_install lftp
brew_install maven
brew_install mobile-shell
brew_install nkf
brew_install phantomjs
brew_install rename
brew_install sbt
brew_install scala
brew_install tree
brew_install typesafe-activator
brew_install wget

cask_install alfred
cask_install apache-directory-studio
cask_install atom
cask_install dash
cask_install dropbox
cask_install firefox-ja
cask_install google-chrome
cask_install intellij-idea-ce
cask_install iterm2
cask_install java7
cask_install libreoffice
cask_install phpstorm
cask_install sequel-pro
cask_install slack
cask_install sourcetree
cask_install vagrant
cask_install virtualbox

brew cleanup
brew cask cleanup
