function switch_php_version(){
  version_file="$(pwd)/.php-version"
  if [ -f "${version_file}" ]; then
    phpbrew use php-$(cat "${version_file}")
  else
    phpbrew off > /dev/null
  fi
}

if [ -e ${HOME}/.phpbrew/bashrc ]; then
  source ${HOME}/.phpbrew/bashrc
  add-zsh-hook chpwd switch_php_version
fi
