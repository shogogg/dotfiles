export ZPLUG_HOME=/usr/local/opt/zplug
export ZPLUG_CACHE_DIR=~/.zplug/cache

. ${ZPLUG_HOME}/init.zsh
. ${HOME}/.zsh.d/zplug.plugins.zsh

zplug check || zplug install
zplug load
