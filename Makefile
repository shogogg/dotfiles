DOT_PATH := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))

DOTFILES_CANDIDATES := $(wildcard .??*)
DOTFILES_EXCLUSIONS := .DS_Store .config .git .gitignore .gitmodules .idea
DOTFILES := $(filter-out $(DOTFILES_EXCLUSIONS), $(DOTFILES_CANDIDATES))

CONFIG_PATH := $(DOT_PATH)/.config
CONFIGS := $(wildcard .config/??*)

COMMANDS := $(wildcard bin/??*)

UNAME := $(shell uname -s)

.PHONY: all
all: dotfiles bin claude codex config anyenv vim macos-config pam-tid

.PHONY: list
list:
	@echo 'dotfiles:'
	@$(foreach name, $(DOTFILES), /bin/ls -dF $(name);)
	@echo ''
	@echo 'config:'
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

.PHONY: ghostty
ghostty: dir
	@ln -fnsv "$(CONFIG_PATH)/$@" "$(HOME)/.config/$@"

.PHONY: git
git: dir
	@ln -fnsv "$(CONFIG_PATH)/$@" "$(HOME)/.config/$@"

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
# Claude Code
#
.PHONY: claude
claude:
	@mkdir -p "$(HOME)/.claude"
	@ln -fnsv "$(DOT_PATH)/.claude/notify.sh" "$(HOME)/.claude/notify.sh"
	@ln -fnsv "$(DOT_PATH)/.claude/settings.json" "$(HOME)/.claude/settings.json"
	@ln -fnsv "$(DOT_PATH)/ai-agent/AGENTS.md" "$(HOME)/.claude/CLAUDE.md"
	@ln -fnsv "$(DOT_PATH)/ai-agent/agents" "$(HOME)/.claude/agents"
	@ln -fnsv "$(DOT_PATH)/ai-agent/prompts" "$(HOME)/.claude/commands"
	@ln -fnsv "$(DOT_PATH)/ai-agent/skills" "$(HOME)/.claude/skills"

#
# Codex
#
.PHONY: codex
codex:
	@mkdir -p "$(HOME)/.codex"
	@ln -fnsv "$(DOT_PATH)/.codex/notify.sh" "$(HOME)/.codex/notify.sh"
	@ln -fnsv "$(DOT_PATH)/.codex/config.toml" "$(HOME)/.codex/config.toml"
	@ln -fnsv "$(DOT_PATH)/ai-agent/AGENTS.md" "$(HOME)/.codex/AGENTS.md"
	@ln -fnsv "$(DOT_PATH)/ai-agent/prompts" "$(HOME)/.codex/prompts"
	@ln -fnsv "$(DOT_PATH)/ai-agent/skills" "$(HOME)/.codex/skills"

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
	curl -fsSL https://raw.githubusercontent.com/Shougo/dein-installer.vim/master/installer.sh > /tmp/installer.sh
	sh /tmp/installer.sh ~/.cache/dein > /dev/null 2>&1
	rm /tmp/installer.sh

#
# macOS configuration
#
macos-config:
ifeq ($(UNAME), Darwin)
	@defaults write -g KeyRepeat -int 1                                # Increase key repeat speed
	@defaults write -g InitialKeyRepeat -int 15                        # Shorten the delay until key repeat starts
	@defaults write com.apple.screencapture show-thumbnail -bool false # Disable thumbnail preview for screenshots
	@defaults write com.apple.screencapture disable-shadow -bool true  # Disable window shadows in screenshots
	@defaults write NSGlobalDomain AppleShowAllExtensions -bool true   # Show file extensions in Finder
	@defaults write com.apple.Finder AppleShowAllFiles -bool true      # Show hidden files in Finder
	@defaults write com.apple.Finder ShowPathbar -bool true            # Display the path bar in Finder
else
	@echo "Nothing to do."
endif

#
# pam_tid
#
pam-tid:
	@curl -fsSL https://gist.github.com/shogogg/61c7867412ddfe4e09b45eb4237fc015/raw/install-pam_tid-and-pam_reattach.sh | sudo bash
