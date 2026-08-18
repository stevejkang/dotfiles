#!/bin/bash
set -euo pipefail

# Set if key exists, Add if it doesn't (idempotent PlistBuddy write)
plist_set() {
  local file="$1" key="$2" type="$3" value="$4"
  /usr/libexec/PlistBuddy -c "Set ${key} ${value}" "${file}" 2>/dev/null ||
    /usr/libexec/PlistBuddy -c "Add ${key} ${type} ${value}" "${file}"
}

echo "Applying macOS defaults..."

# 24-hour time (system-wide + lock screen)
defaults write NSGlobalDomain AppleICUForce24HourTime -bool true
# Dock magnification
defaults write com.apple.dock magnification -bool true
# Dock position left
defaults write com.apple.dock orientation -string left
# Dock auto-hide
defaults write com.apple.dock autohide -bool true
# Animate opening apps
defaults write com.apple.dock launchanim -bool true
# Show running app indicators
defaults write com.apple.dock show-process-indicators -bool true
# Hide suggested and recent apps
defaults write com.apple.dock show-recents -bool false
# Disable window tiling on edge drag
defaults write com.apple.WindowManager EnableTilingByEdgeDrag -bool false
# Disable window tiling on menu bar drag
defaults write com.apple.WindowManager EnableTopTilingByEdgeDrag -bool false
# Screen saver: never
defaults -currentHost write com.apple.screensaver idleTime -int 0

# Display sleep: never (battery + AC)
sudo pmset -b displaysleep 0 || true
sudo pmset -c displaysleep 0 || true

# Globe/fn key: 0=DoNothing, 1=InputSource, 2=Emoji, 3=Dictation
defaults write com.apple.HIToolbox AppleFnUsageType -int 0

HOTKEYS="$HOME/Library/Preferences/com.apple.symbolichotkeys.plist"
FINDER_PLIST="$HOME/Library/Preferences/com.apple.finder.plist"

# Disable "Select previous input source" (symbolic hotkey 60)
plist_set "$HOTKEYS" ":AppleSymbolicHotKeys:60:enabled" "bool" "false"

# "Select next input source" → Option+Space (symbolic hotkey 61)
# 32=space ascii, 49=space keycode, 524288=Option modifier bitmask
plist_set "$HOTKEYS" ":AppleSymbolicHotKeys:61:enabled" "bool" "true"
plist_set "$HOTKEYS" ":AppleSymbolicHotKeys:61:value:parameters:0" "integer" "32"
plist_set "$HOTKEYS" ":AppleSymbolicHotKeys:61:value:parameters:1" "integer" "49"
plist_set "$HOTKEYS" ":AppleSymbolicHotKeys:61:value:parameters:2" "integer" "524288"

# Disable Spotlight shortcuts (64=Show Spotlight, 65=Finder Search)
plist_set "$HOTKEYS" ":AppleSymbolicHotKeys:64:enabled" "bool" "false"
plist_set "$HOTKEYS" ":AppleSymbolicHotKeys:65:enabled" "bool" "false"

# Finder Desktop: show only external disks
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowMountedServersOnDesktop -bool false
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool false

# Finder: new window opens home folder
defaults write com.apple.finder NewWindowTarget -string "PfHm"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/"

# Disable opening folders in tabs
defaults write com.apple.finder FinderSpawnTab -bool false
# Search scoped to current folder
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
# Finder Desktop: Use Stacks grouped by Kind
plist_set "$FINDER_PLIST" ":DesktopViewSettings:GroupBy" "string" "Kind"

killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true

echo "macOS defaults applied. Globe key change requires logout."
