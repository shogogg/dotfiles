function __tmux_has_session
  tmux has-session > /dev/null 2>&1
end

function __tmux_is_running
  tmux info > /dev/null 2>&1
end

function __tmux_read_session_name
  echo $argv | awk '{ print $2 }' | sed 's/://g'
end

function __tmux_read_window_name
  echo $argv | awk '{ print $2 }' | sed 's/://g'
end

function __tmux_create_session
  read -p 'echo "session name?: "' name
  if is_tmux
    tmux new-session -s "$name" -d
    tmux switch -t "$name"
  else
    tmux new-session -s "$name"
  end
end

function __tmux_create_window
  tmux new-window
end

function __tmux_rename_session
  set -l current_session_name (tmux display-message -p '#S')
  read -p 'echo "session name? [$current_session_name]: "' name
  if test ! -z "$name"
    tmux rename-session "$name"
  end
end

function __tmux_list_actions
  if is_tmux
    echo -s (set_color brmagenta) "SPLIT" (set_color normal) ": right"
    echo -s (set_color brmagenta) "SPLIT" (set_color normal) ": down"
    tmux ls 2> /dev/null | grep -v attached | while read session
      echo -s (set_color blue) "SWITCH"(set_color normal) ": $session"
    end
    echo -s (set_color yellow) "CREATE" (set_color normal) ": new window"
    echo -s (set_color yellow) "CREATE" (set_color normal) ": new session"
    echo -s (set_color magenta) "DETACH" (set_color normal)
    echo -s (set_color magenta) "KILL SESSION" (set_color normal)
    echo -s (set_color brmagenta) "RENAME SESSION" (set_color normal)
  else
    tmux ls 2> /dev/null | while read session
      echo -s (set_color blue) "ATTACH" (set_color normal) ": $session"
    end
    echo -s (set_color yellow) "CREATE" (set_color normal) ": new session"
  end
  echo -s "CANCEL"
end

function __tmux_do_action
  switch "$argv"
    case 'ATTACH: *'
      tmux attach -t (__tmux_read_session_name $argv)
    case 'CANCEL'
      # DO NOTHING
    case 'CREATE: new session'
      __tmux_create_session
    case 'CREATE: new window'
      __tmux_create_window
    case 'DETACH'
      tmux detach
    case 'KILL SESSION'
      tmux kill-session
    case 'RENAME SESSION'
      __tmux_rename_session
    case 'SPLIT: right'
       tmux split-window -h
    case 'SPLIT: down'
       tmux split-window -v
    case 'SWITCH: *'
      tmux switch -t (__tmux_read_session_name $argv)
  end
end

function tmux_auto_attach_session
  if not status --is-interactive
    # DO NOTHING
  else if is_tmux
    echo "This is tmux session"
  else if not exists tmux
    echo "TMUX IS NOT INSTALLED!!"
  else if __tmux_is_running
    set -l action (__tmux_list_actions | fzf --ansi)
    __tmux_do_action "$action"
  else
    tmux
  end
end

function tmux_interactive
  set -l action (__tmux_list_actions | fzf --ansi)
  __tmux_do_action "$action"
end
