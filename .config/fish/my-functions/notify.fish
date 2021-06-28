function notify
  $argv
  set -l success $status
  terminal-notifier \
    -title (if test $success -eq 0; echo 'SUCCESS'; else; echo 'FAILURE'; end) \
    -message "$argv" \
    -group fish-notify \
    -remove fish-notify \
    -activate com.googlecode.iterm2 \
    -sound (if test $success -eq 0; echo 'default'; else; echo 'Hero'; end) \
    > /dev/null 2> /dev/null
end
