function __tmux-colours
  echo (set_color brblack)base03(set_color normal)
  echo (set_color black)base02(set_color normal)
  echo (set_color brgreen)base01(set_color normal)
  echo (set_color bryellow)base00(set_color normal)
  echo (set_color brblue)base0(set_color normal)
  echo (set_color brcyan)base1(set_color normal)
  echo (set_color white)base2(set_color normal)
  echo (set_color yellow)yellow(set_color normal)
  echo (set_color bryellow)orange(set_color normal)
  echo (set_color red)red(set_color normal)
  echo (set_color magenta)magenta(set_color normal)
  echo (set_color brmagenta)violet(set_color normal)
  echo (set_color blue)blue(set_color normal)
  echo (set_color cyan)cyan(set_color normal)
  echo (set_color green)green(set_color normal)
end

function tmux-colours
  __tmux-colours | column -x
end
