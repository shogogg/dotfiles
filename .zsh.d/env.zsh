export EDITOR=vim
export LANG=ja_JP.UTF-8
export TERM=xterm-256color
export LSCOLORS=DxGxcxdxCxegedabagacad
export CLICOLOR=1

# コマンドの入力ミスを補正する
setopt correct

# コマンドラインの = 以降でもパス補完を有効にする
setopt magic_equal_subst

# 拡張GLOBを有効にする
setopt extended_glob
setopt nonomatch
