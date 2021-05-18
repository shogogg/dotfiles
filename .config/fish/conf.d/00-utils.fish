function exists
  type $argv > /dev/null 2>&1
end

function is_macos
  test (uname) = "Darwin"
end

function is_tmux
  test ! -z "$TMUX"
end
