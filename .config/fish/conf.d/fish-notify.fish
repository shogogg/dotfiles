function fish-notify --on-event fish_prompt
  set -l _display_status $status
  if test $CMD_DURATION
    set -l secs (math "$CMD_DURATION / 1000")
    if test $secs -ge 5
      terminal-notifier \
        -title $history[1] \
        -subtitle (if test $_display_status -eq 0; echo 'SUCCESS'; else; echo 'FAILURE'; end) \
        -message "$secs seconds" \
        -group "fish-notify" \
        -remove "fish-notify" \
        -activate "co.zeit.hyper" \
        -sender "co.zeit.hyper" \
        -sound (if test $_display_status -eq 0; echo 'Ping'; else; echo 'Glass'; end) \
        > /dev/null 2> /dev/null
    end
  end
end
