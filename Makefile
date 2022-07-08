DOT_PATH := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))

DOTFILES_CANDIDATES := $(wildcard .??*)
DOTFILES_EXCLUSIONS := .DS_Store .config .git .gitignore .gitmodules .idea
DOTFILES := $(filter-out $(DOTFILES_EXCLUSIONS), $(DOTFILES_CANDIDATES))

CONFIG_PATH := $(DOT_PATH)/.config
CONFIGS := $(wildcard .config/??*)

BIN_PATH := $(DOT_PATH)/bin
COMMANDS := $(wildcard bin/??*)

UNAME := $(shell uname -s)

.PHONY: all
all: dotfiles bin config bundle vim key-repeat pam-tid

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
ifeq (, $(shell which brew))
	@echo "Install Homebrew"
	@curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash
else
	@echo "Homebrew already installed!!"
endif

bundle: homebrew
	@brew bundle --global

#
# .config
#
.PHONY: config
config: fish git psysh starship.toml

.PHONY: fish
fish: dir bundle
	@ln -fnsv "$(CONFIG_PATH)/$@" "$(HOME)/.config/$@"
	@curl https://git.io/fisher --create-dirs -sLo "$(CONFIG_PATH)/$@/functions/fisher.fish"
	@sudo sed -I -e '/\/opt\/homebrew\/bin\/fish/d' /etc/shells
	@echo '/opt/homebrew/bin/fish' | sudo tee -a /etc/shells > /dev/null
	@sudo chsh -s '/opt/homebrew/bin/fish' $(shell whoami)

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
# docker
#
.PHONY: docker
docker:
	@mkdir -p "$(HOME)/.docker/cli-plugins"
	@ln -sfn "$(shell brew --prefix docker-compose)/bin/docker-compose" "$(HOME)/.docker/cli-plugins/docker-compose"

#
# vim
#
.PHONY: vim
vim:
	@curl -fsSL https://raw.githubusercontent.com/Shougo/dein.vim/HEAD/bin/installer.sh > installer.sh
	@sh ./installer.sh ~/.cache/dein > /dev/null 2>&1
	@rm ./installer.sh

#
# Key Repeat for macOS
#
key-repeat:
ifeq ($(UNAME), Darwin)
	@defaults write KeyRepeat -float 1.6
	@defaults write InitialKeyRepeat -int 15
else
	@echo "Nothing to do."
endif

#
# pam_tid
#
pam-tid:
	@curl -fsSL https://gist.github.com/shogogg/dd6fd5d84ce7c87569038ae4f81a4101/raw/install-pam_tid-and-pam_reattach.sh | bash
