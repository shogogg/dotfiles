# enhancd
zplug "b4b4r07/enhancd", use:init.sh

# history-fzy
zplug "shogogg/86f13a0aff12b9a31efb083946a500cb", from:gist

# zsh-completion
zplug "zsh-users/zsh-completions"

# zsh-notify
zplug "marzocchi/zsh-notify", if:"type terminal-notifier || type notify-send"
zstyle ':notify:*' command-complete-timeout 5
zstyle ':notify:*' error-sound Glass
zstyle ':notify:*' success-sound default
