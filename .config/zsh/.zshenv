setopt no_global_rcs

typeset -U path cdpath fpath manpath

path=(
  ~/bin(N-/)
  /usr/local/bin(N-/)
  /usr/local/sbin(N-/)
  $path
)

fpath=(
  $ZDOTDIR/local-functions(N-/)
  $fpath
)

export EDITOR=vim
export LANG=ja_JP.UTF-8
export TERM=xterm-256color
export LSCOLORS=DxGxcxdxCxegedabagacad
export CLICOLOR=1
