source ~/.zsh.d/antigen/antigen.zsh

# enhancd
antigen bundle b4b4r07/enhancd

# zsh-notify
zstyle ':notify:*' command-complete-timeout 5
zstyle ':notify:*' error-sound Glass
zstyle ':notify:*' success-sound default
antigen bundle shogogg/zsh-notify
