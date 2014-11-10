autoload -Uz add-zsh-hook

source ~/.zsh.d/env.zsh
source ~/.zsh.d/alias.zsh
source ~/.zsh.d/complement.zsh
source ~/.zsh.d/history.zsh
source ~/.zsh.d/prompt.zsh
source ~/.zsh.d/path.zsh

# 個別設定
source ~/.zsh.d/common/*.zsh

# OS別個別設定
case ${OSTYPE} in
  darwin*)
    source ~/.zsh.d/osx/*.zsh
    ;;
  linux*)
    source ~/.zsh.d/linux/*.zsh
    ;;
esac
