function __fzf_default_options
  set -l base03 "234"
  set -l base02 "235"
  set -l base01 "240"
  set -l base00 "241"
  set -l base0 "244"
  set -l base1 "245"
  set -l base2 "254"
  set -l base3 "230"
  set -l yellow "136"
  set -l orange "166"
  set -l red "160"
  set -l magenta "125"
  set -l violet "61"
  set -l blue "33"
  set -l cyan "37"
  set -l green "64"

  set -l options "--height 50%" "--inline-info" "--reverse"
  set -l --append options "--color fg:-1,bg:-1,hl:$blue,fg+:$base2,bg+:$base02,hl+:$blue"
  set -l --append options "--color info:$yellow,prompt:$yellow,pointer:$base3,marker:$base3,spinner:$yellow"

  string join ' ' -- $options
end
