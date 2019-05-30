autoload -U colors; colors
autoload -Uz vcs_info

zstyle ':vcs_info:*' formats '[%s:%r#%b]'
zstyle ':vcs_info:*' actionformats '(%a) [%s:%r#%b]'
function _precmd_vcs_info() {
  psvar=()
  LANG=ja_JP.UTF-8 vcs_info
  [[ -n "$vcs_info_msg_0_" ]] && psvar[1]="$vcs_info_msg_0_"
}
add-zsh-hook precmd _precmd_vcs_info

local PROMPT_COLOR=yellow
if [ $UID -eq 0 ]; then
  local PROMPT_COLOR=red
fi

PROMPT="
%F{$PROMPT_COLOR}%n@%m: %~%f
%B%(!,#,$)%b "

RPROMPT="%1(v|%F{green}%1v%f|)"
