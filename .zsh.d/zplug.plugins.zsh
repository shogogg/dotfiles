# enhancd
zplug "b4b4r07/enhancd", use:init.sh

# zsh-notify
zplug "marzocchi/zsh-notify", if:"type terminal-notifier || type notify-send"
zstyle ':notify:*' command-complete-timeout 5
zstyle ':notify:*' error-sound Glass
zstyle ':notify:*' success-sound default
