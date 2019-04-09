export ZPLUG_HOME=/usr/local/opt/zplug
export ZPLUG_CACHE_DIR=~/.zplug/cache

. ${ZPLUG_HOME}/init.zsh
. ${ZDOTDIR}/zplug.plugins.zsh

zplug check || zplug install
zplug load
