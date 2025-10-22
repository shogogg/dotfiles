set -q FISH_NOTIFY_EXCLUDED; or set -Ux FISH_NOTIFY_EXCLUDED bat cd claude codex g gam gci git gs less php psysh ssh t tmux vi view vim
set -q FISH_NOTIFY_APP; or set -Ux FISH_NOTIFY_APP com.apple.Terminal

function fish-notify --on-event fish_prompt
  set -l _display_status $status
  if test $CMD_DURATION
    set -l secs (math "$CMD_DURATION / 1000")
    set -l command (echo $history[1] | awk '{ print $1 }')
    if test $secs -ge 5; and not contains $command $FISH_NOTIFY_EXCLUDED
      terminal-notifier \
        -title (if test $_display_status -eq 0; echo 'SUCCESS'; else; echo 'FAILURE'; end) \
        -subtitle $history[1] \
        -message "$secs seconds" \
        -group fish-notify \
        -remove fish-notify \
        -activate $FISH_NOTIFY_APP \
        -sound (if test $_display_status -eq 0; echo 'Sonar'; else; echo 'Hero'; end) \
        > /dev/null 2> /dev/null
    end
  end
end
