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
set -x PATH (cat /etc/paths)
fish_add_path -pm ~/bin

#
# aliases
#
alias artisan 'php artisan'
alias bump 'yarn upgrade-interactive && yarn && npx yarn-deduplicate yarn.lock && yarn'
alias d 'docker'
alias g 'git'
alias gad 'git add'
alias gam 'git amend'
alias gb 'git branch'
alias gcb 'git cb'
alias gci 'git ci'
alias gco 'git co'
alias gd 'cd (ghq root)/(ghq list | fzf)'
alias gri 'git ri'
alias gs 'git s'
alias gsm 'git sm'
alias gsp 'git stash pop'
alias gss 'git add . && git stash save'
alias gst 'git status'
alias gup 'git up'
alias la 'eza --time-style=long-iso -l -h -a'
alias ll 'eza --time-style=long-iso -l -h -a -g'
alias ls 'eza --time-style=long-iso'
alias pull 'git pull'
alias push 'git push'
alias s "git branch | sed 's#remotes/[^/]*/##' | grep -v '*' | sort | uniq | fzf --preview 'echo {} | cut -c 3- | xargs git log --color=always' | xargs git switch"
alias st stree
alias t tmux_interactive
alias tinker 'php artisan tinker'
alias vi 'vim'

#
# Homebrew
#
eval (/opt/homebrew/bin/brew shellenv)

#
# anyenv
#
if test -d ~/.anyenv
  source (anyenv init - | psub)
end
set -Ux PHP_BUILD_INSTALL_EXTENSION \
  "apcu=5.1.21" \
  "redis=5.3.7"

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
fish_add_path -pm /opt/homebrew/opt/curl/bin

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
fish_add_path -pm /opt/homebrew/opt/mysql-client/bin

#
# pipx
#
fish_add_path -pm ~/.local/bin

#
# PostgreSQL Client
#
fish_add_path -pm /opt/homebrew/opt/libpq/bin

#
# rust
#
fish_add_path -pm ~/.cargo/bin

#
# starship
#
starship init fish | source

#
# tmux
#
tmux_auto_attach_session
