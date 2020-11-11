function fish_notify --on-event fish_prompt
  set _display_status $status
  if test $CMD_DURATION
    set secs (math "$CMD_DURATION / 1000")
    if test $secs -ge 3
      terminal-notifier -title $history[1] -message "Returned $_display_status, took $secs seconds" -sound Ping
    end
  end
end
