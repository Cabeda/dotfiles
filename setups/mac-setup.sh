#!/bin/bash

# A script to set up a new mac. Uses bash, homebrew, etc.

# helpers
function echo_ok { echo -e '\033[1;32m'"$1"'\033[0m'; }
function echo_warn { echo -e '\033[1;33m'"$1"'\033[0m'; }
function echo_error { echo -e '\033[1;31mERROR: '"$1"'\033[0m'; }

echo_ok "Install starting. You may be asked for your password (for sudo)."

# requires xcode and tools!
xcode-select -p || exit "XCode must be installed! (use the app store)"

# requirements
cd ~ || exit
mkdir -p tmp
echo_warn "setting permissions..."
for dir in "/usr/local /usr/local/bin /usr/local/include /usr/local/lib /usr/local/share"; do
  sudo chgrp admin $dir
  sudo chmod g+w $dir
done

# oh my zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# homebrew
export HOMEBREW_CASK_OPTS="--appdir=/Applications"
if hash brew &>/dev/null; then
  echo_ok "Homebrew already installed"
else
  echo_warn "Installing homebrew..."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# RVM
if hash rvm &>/dev/null; then
  echo_ok "RVM already installed"
else
  echo "Installing RVM..."
  curl -sSL https://get.rvm.io | bash -s stable --ruby
fi

# add default gems to rvm
global_gems_config="$HOME/.rvm/gemsets/global.gems"
default_gems="bundler awesome-print lunchy rak"
for gem in $default_gems; do
  echo $gem >>$global_gems_config
done
awk '!a[$0]++' $global_gems_config >/tmp/global.tmp
mv /tmp/global.tmp $global_gems_config

# RVM ruby versions
for version in $ruby_versions; do
  source ~/.rvm/scripts/rvm
  rvm install $version
done

# moar homebrew...
brew update && brew upgrade --cask

# Upgrade mac
softwareupdate --all --install --force
xcode-select --install

# brew taps
brew tap xo/xo
brew tap turbot/tap
brew tap microsoft/git

# Homebrew base
brew upgrade
brew install \
  gpg entr tealdeer gh fzf freetype htop pwgen \
  jq yq libxml2 heroku ffmpeg zlib \
  sqlite v8 wget poetry uv git ripgrep \
  awscli asdf rust starship trash zsh-autosuggestions \
  git-delta watch zoxide m-cli bat \
  eza mcfly dive colima lazydocker jless broot \
  direnv jc lazygit deno duckdb \
  docker-credential-helper docker-buildx \
  pearcleaner bottom localsend ghostty \
  mise jordanbaird-ice


# Docker buildx hotfix https://github.com/abiosoft/colima/discussions/273
mkdir -p ~/.docker/cli-plugins
ln -sfn $HOMEBREW_PREFIX/opt/docker-buildx/bin/docker-buildx ~/.docker/cli-plugins/docker-buildx

# Deno install tools 
npm i -g --global @bitwarden/cli

# Set file for env files
touch ~/env

# Gh config
gh auth login
gh extension install dlvhdr/gh-dash
gh extension install github/gh-copilot

# ASDF plugins
asdf plugin-add java https://github.com/halcyon/asdf-java.git
asdf install nodejs latest
asdf global nodejs latest

## Start colima on boot
brew services start colima

# Install java
. ~/.asdf/plugins/java/set-java-home.zsh
asdf install java openjdk-11.0.2
asdf global java openjdk-11.0.2

# Apps
echo_warn "Installing applications..."

brew install --cask \
  vlc iina overkill slack zoom google-chrome zen-browser visual-studio-code \
  anytype openmtp swiftdefaultappsprefpane raycast \
  font-jetbrains-mono font-jetbrains-mono-nerd-font handbrake bitwarden  git-credential-manager-core bruno \
  httpie android-platform-tools

# brew imagemagick
#brew cask install inkscape
brew install librsvg
brew install imagemagick

# Set one time configs
git config --global core.pager "delta --line-numbers --dark"
git config --global delta.side-by-side true
git config --global --add --bool push.autoSetupRemote true
gh config set pager 'delta -s'

# Mac System Preferences
echo_warn "Applying Mac system preferences..."

# Dock preferences
defaults write com.apple.dock wvous-br-corner -int 0 # Disable hot corner
defaults write com.apple.dock orientation left # Set dock position to the left
defaults write com.apple.spaces spans-displays -bool false # Disable separate spaces for displays
killall Dock # Apply dock settings

# System appearance
defaults write -g AppleInterfaceStyle Dark # Set system appearance to dark mode
killall SystemUIServer # Apply appearance settings

# Desktop background (using absolute path for reliability)
osascript -e 'tell application "System Events" to set picture of current desktop to "'"$HOME/Git/dotfiles/backgrounds/black.jpeg"'"'

# Disable boot sound
sudo nvram SystemAudioVolume=%80

# Set dotfiles configs to be the ones used by the system
mkdir -p ~/.config
mkdir -p ~/.config/mise
mkdir -p ~/.config/alacritty
mkdir -p ~/.config/prs
mkdir -p ~/.config/gh-dash

cd ~/Git/dotfiles || exit

ln -f tmux.conf ~/.tmux.conf
ln -f .vimrc ~/.vimrc
ln -f .nanorc ~/.nanorc
ln -f .zshrc ~/.zshrc
ln -f .gitconfig ~/.gitconfig
ln -f alacritty.yml ~/.config/alacritty/alacritty.yml
ln -f starship.toml ~/.config/starship.toml
ln -f github_prs.yml ~/.config/gh-dash/config.yml
ln -f .tool-versions ~/.tool-versions
ln -f vale.ini ~/.vale.ini
ln -f mise.toml ~/.config/mise/config.toml


# Set confidential files from bitwarden

bw login

# Disable boot sound
sudo nvram SystemAudioVolume=%80

echo
echo_ok "Done."
echo

