autoload -Uz add-zsh-hook

source ~/.zsh.d/env.zsh
source ~/.zsh.d/path.zsh
source ~/.zsh.d/alias.zsh
source ~/.zsh.d/complement.zsh
source ~/.zsh.d/history.zsh
source ~/.zsh.d/prompt.zsh
source ~/.zsh.d/keybind.zsh
source ~/.zsh.d/zplug.zsh

# common settings
for x in ~/.zsh.d/common/*.zsh; do source $x; done

# settings by os
case ${OSTYPE} in
  darwin*)
    for x in ~/.zsh.d/osx/*.zsh; do source $x; done
    ;;
  linux*)
    for x in ~/.zsh.d/linux/*.zsh; do source $x; done
    ;;
esac
