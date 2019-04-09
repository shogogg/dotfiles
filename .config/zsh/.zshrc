autoload -Uz add-zsh-hook

setopt correct
setopt magic_equal_subst
setopt extended_glob
setopt nonomatch

source ${ZDOTDIR}/alias.zsh
source ${ZDOTDIR}/completion.zsh
source ${ZDOTDIR}/history.zsh
source ${ZDOTDIR}/keybind.zsh
source ${ZDOTDIR}/prompt.zsh
source ${ZDOTDIR}/zplug.zsh

# common settings
for z in ${ZDOTDIR}/common/*.zsh; do source $z; done

# settings by os
case ${OSTYPE} in
  darwin*)
    for z in ${ZDOTDIR}/osx/*.zsh; do source $z; done
    ;;
  linux*)
    for z in ${ZDOTDIR}/linux/*.zsh; do source $z; done
    ;;
esac
