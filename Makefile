DOT_PATH := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))

DOTFILES_CANDIDATES := $(wildcard .??*)
DOTFILES_EXCLUSIONS := .DS_Store .config .git .gitignore .gitmodules .idea
DOTFILES := $(filter-out $(DOTFILES_EXCLUSIONS), $(DOTFILES_CANDIDATES))

CONFIG_PATH := $(DOT_PATH)/.config
CONFIGS := $(wildcard .config/??*)

BIN_PATH := $(DOT_PATH)/bin
COMMANDS := $(wildcard bin/??*)

.PHONY: all
all: dotfiles bin config homebrew vim

.PHONY: list
list:
	@$(foreach name, $(DOTFILES), /bin/ls -dF $(name);)
	@$(foreach name, $(CONFIGS), /bin/ls -dF $(name);)

#
# dotfiles
#
.PHONY: dotfiles
dotfiles:
	@$(foreach name, $(DOTFILES), ln -fnsv $(abspath $(name)) $(HOME)/$(name);)

#
# bin
#
.PHONY: bin
bin: dir
	@$(foreach name, $(COMMANDS), ln -fnsv $(abspath $(name)) $(HOME)/$(name);)

#
# dir
#
.PHONY: dir
dir:
	@mkdir -p "$(HOME)/.config"
	@mkdir -p "$(HOME)/bin"

#
# Homebrew
#
.PHONY: homebrew
homebrew: dotfiles
	@type brew || bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	@brew bundle --global

#
# .config
#
.PHONY: config
config: fish git psysh starship.toml

.PHONY: fish
fish: dir
	@ln -fnsv "$(CONFIG_PATH)/$@" "$(HOME)/.config/$@"
	@curl https://git.io/fisher --create-dirs -sLo "$(CONFIG_PATH)/$@/functions/fisher.fish"

.PHONY: git
git: dir
	@mkdir -p "$(HOME)/.config/$@"
	@ln -fnsv "$(CONFIG_PATH)/$@/.gitconfig" "$(HOME)/.config/$@/.gitconfig"
	@ln -fnsv "$(CONFIG_PATH)/$@/.gitignore" "$(HOME)/.config/$@/.gitignore"

.PHONY: psysh
psysh: dir
	@ln -fnsv "$(CONFIG_PATH)/$@" "$(HOME)/.config/$@"

.PHONY: starship.toml
starship.toml: dir
	@ln -fnsv "$(CONFIG_PATH)/$@" "$(HOME)/.config/$@"

#
# vim
#
.PHONY: vim
vim:
	@curl -fsSL https://raw.githubusercontent.com/Shougo/dein.vim/HEAD/bin/installer.sh > installer.sh
	@sh ./installer.sh ~/.cache/dein > /dev/null 2>&1
	@rm ./installer.sh
