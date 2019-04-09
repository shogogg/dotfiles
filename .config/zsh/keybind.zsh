# Reset
bindkey -d

# Bind
bindkey "^A" beginning-of-line
bindkey "^E" end-of-line
bindkey "^L" clear-screen
bindkey "^N" history-beginning-search-forward-end
bindkey "^P" history-beginning-search-backward-end
# bindkey "^R" history-fzy
bindkey "^U" vi-kill-line
bindkey "^W" vi-backward-kill-word

bindkey '\e\C-?' vi-backward-kill-word  # ⌥ + ⌫
bindkey '\e\e[C' vi-forward-word        # ⌥ + →
bindkey '\e\e[D' vi-backward-word       # ⌥ + ←
