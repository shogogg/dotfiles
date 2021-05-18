function __tmux-colours-256
  for i in (seq 0 255)
    printf "\x1b[38;5;"$i"mcolour"$i" \x1b[0m\n"
  end
end

function tmux-colours-256
  __tmux-colours | column -x
end
