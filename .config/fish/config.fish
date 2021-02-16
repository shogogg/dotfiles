#
# env
#
set fish_home (dirname (status --current-filename))
set fish_greeting ""
set --prepend fish_function_path \
  $fish_home/local-functions \
  $fish_home/my-functions

set -Ux EDITOR vim
set -Ux LANG ja_JP.UTF-8
set -Ux TERM xterm-256color

#
# aliases
#
alias artisan "php artisan"
alias bump "yarn upgrade-interactive"
alias ga "git add"
alias gco "git checkout"
alias grm "git rebase master"
alias gsp "git stash pop"
alias gss "git add . && git stash save"
alias gst "git status"
alias gu "gitup"
alias la "exa --time-style=long-iso -lha"
alias ll "exa --time-style=long-iso -aghl"
alias ls "exa --time-style=long-iso"
alias pull "git pull"
alias push "git push"
alias s "git branch | sed 's#remotes/[^/]*/##' | grep -v '*' | sort | uniq | fzf --preview 'echo {} | cut -c 3- | xargs git log --color=always' | xargs git switch"
alias st "stree"
alias tinker "php artisan tinker"
alias vi "vim"

#
# anyenv
#
if test -d ~/.anyenv
  set -x --prepend PATH "~/.anyenv/bin"
  status --is-interactive; and source (anyenv init - | psub)
end

#
# composer
#
if test -d ~/.composer
  set -x --prepend PATH ~/.composer/vendor/bin
  set -Ux COMPOSER_MEMORY_LIMIT -1
end

#
# curl
#
set -x --prepend PATH "/usr/local/opt/curl/bin"

#
# direnv
#
set -Ux DIRENV_LOG_FORMAT ""
eval (direnv hook fish)

#
# enhancd
#
set -Ux ENHANCD_FILTER "fzf:fzy:peco"
set -Ux ENHANCD_ROOT "$fish_home/functions/enhancd"

#
# fzf
#
set -Ux FZF_COMPLETE 0
set -Ux FZF_DEFAULT_OPTS '--height 50% --inline-info --reverse'

#
# golang
#
set -Ux GOPATH ~/.go/
set --prepend -x PATH ~/.go/bin

#
# grep
#
set -Ux GREP_OPTIONS "--color=auto"

#
# phpbrew
#
set -Ux PHPBREW_SHELL fish
set -Ux PHPBREW_RC_ENABLE 1
if not type -q phpbrew
  curl -L -O https://github.com/phpbrew/phpbrew/raw/master/phpbrew \
    and chmod +x phpbrew \
    and mv phpbrew /usr/local/bin \
    and phpbrew init
end
if test -f ~/.phpbrew/phpbrew.fish
  source ~/.phpbrew/phpbrew.fish
end

#
# starship
#
starship init fish | source
