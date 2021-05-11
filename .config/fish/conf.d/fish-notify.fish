function fish-notify --on-event fish_prompt
  set -l _display_status $status
  if test $CMD_DURATION
    set -l secs (math "$CMD_DURATION / 1000")
    if test $secs -ge 5
      terminal-notifier \
        -title (if test $_display_status -eq 0; echo 'SUCCESS'; else; echo 'FAILURE'; end) \
        -subtitle $history[1] \
        -message "$secs seconds" \
        -group fish-notify \
        -remove fish-notify \
        -activate com.googlecode.iterm2 \
        -sender com.googlecode.iterm2 \
        -sound (if test $_display_status -eq 0; echo 'default'; else; echo 'Hero'; end) \
        > /dev/null 2> /dev/null
    end
  end
end
