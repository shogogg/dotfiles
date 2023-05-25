DOT_PATH := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))

DOTFILES_CANDIDATES := $(wildcard .??*)
DOTFILES_EXCLUSIONS := .DS_Store .config .git .gitignore .gitmodules .idea
DOTFILES := $(filter-out $(DOTFILES_EXCLUSIONS), $(DOTFILES_CANDIDATES))

CONFIG_PATH := $(DOT_PATH)/.config
CONFIGS := $(wildcard .config/??*)

COMMANDS := $(wildcard bin/??*)

UNAME := $(shell uname -s)

.PHONY: all
all: dotfiles bin config anyenv vim key-repeat pam-tid

.PHONY: list
list:
	@echo 'dotfiles:'
	@$(foreach name, $(DOTFILES), /bin/ls -dF $(name);)
	@echo ''
	@echo 'config:'
	@$(foreach name, $(CONFIGS), /bin/ls -dF $(name);)

#
# dotfiles
#a
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
ifeq (, $(shell type brew))
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
config: fish git iterm2 karabiner psysh starship.toml

.PHONY: fish
fish: dir
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

.PHONY: iterm2
iterm2: dir
	@ln -fnsv "$(CONFIG_PATH)/$@" "$(HOME)/.config/$@"

.PHONY: karabiner
karabiner: dir
	@ln -fnsv "$(CONFIG_PATH)/$@" "$(HOME)/.config/$@"

.PHONY: psysh
psysh: dir
	@ln -fnsv "$(CONFIG_PATH)/$@" "$(HOME)/.config/$@"

.PHONY: starship.toml
starship.toml: dir
	@ln -fnsv "$(CONFIG_PATH)/$@" "$(HOME)/.config/$@"

#
# anyenv
#
.PHONY: anyenv
anyenv: bundle
	@anyenv install --init | true
	@anyenv install --skip-existing nodenv
	@anyenv install --skip-existing phpenv

#
# Rust
#
.PHONY: rust
rust: bundle
ifeq (, $(shell type rustc))
	@echo "Install Rust"
	@rustup-init -y -q --no-modify-path
else
	@echo "Rust already installed!!"
endif

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
	@defaults write -g KeyRepeat -float 1.6
	@defaults write -g InitialKeyRepeat -int 15
else
	@echo "Nothing to do."
endif

#
# pam_tid
#
pam-tid:
	@curl -fsSL https://gist.github.com/shogogg/61c7867412ddfe4e09b45eb4237fc015/raw/install-pam_tid-and-pam_reattach.sh | bash
