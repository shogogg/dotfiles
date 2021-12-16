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
fish_add_path -pm ~/bin

#
# aliases
#
alias artisan 'php artisan'
alias bump 'yarn upgrade-interactive'
alias ga 'git add'
alias gcd 'cd (ghq root)/(ghq list | fzf)'
alias gco 'git checkout'
alias grm 'git rebase main'
alias gsp 'git stash pop'
alias gss 'git add . && git stash save'
alias gst 'git status'
alias la 'exa --time-style=long-iso -lha'
alias ll 'exa --time-style=long-iso -aghl'
alias ls 'exa --time-style=long-iso'
alias pull 'git pull'
alias push 'git push'
alias s "git branch | sed 's#remotes/[^/]*/##' | grep -v '*' | sort | uniq | fzf --preview 'echo {} | cut -c 3- | xargs git log --color=always' | xargs git switch"
alias st stree
alias t tmux_interactive
alias tinker 'php artisan tinker'
alias vi 'vim'

#
# anyenv
#
if test -d ~/.anyenv
  fish_add_path -pm ~/.anyenv/bin
  status --is-interactive; and source (anyenv init - | psub)
end

#
# composer
#
if test -d ~/.composer
  fish_add_path -pm ~/.composer/vendor/bin
  set -Ux COMPOSER_MEMORY_LIMIT -1
end

#
# curl
#
fish_add_path -pm /usr/local/opt/curl/bin

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
set -Ux FZF_DEFAULT_OPTS (__fzf_default_options)

#
# golang
#
set -Ux GOPATH ~/.go/
fish_add_path -pm ~/.go/bin

#
# grep
#
set -Ux GREP_OPTIONS "--color=auto"

#
# iterm2
#
test -e {$HOME}/.iterm2_shell_integration.fish ; and source {$HOME}/.iterm2_shell_integration.fish

#
# mysql-client
#
fish_add_path -pm /usr/local/opt/mysql-client/bin

#
# phpbrew
#
set -Ux PHPBREW_SHELL fish
set -Ux PHPBREW_RC_ENABLE 1
if not test -d ~/.phpbrew
  phpbrew init
end
if test -f ~/.phpbrew/phpbrew.fish
  source ~/.phpbrew/phpbrew.fish
end
if test -f .phpbrewrc
  source .phpbrewrc
end

#
# starship
#
starship init fish | source

#
# tmux
#
tmux_auto_attach_session
