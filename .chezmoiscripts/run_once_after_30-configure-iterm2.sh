#!/bin/bash
set -euo pipefail

if ! command -v defaults &>/dev/null; then
  exit 0
fi

defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$HOME/.config/iterm2"
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
