#!/bin/bash

# A script to set up a new mac. Uses bash, homebrew, etc.


# Settings
node_version="14.9.0"
ruby_versions="2.7.0"
python="3.8.1"
ruby_default="2.7.0"

# helpers
function echo_ok { echo -e '\033[1;32m'"$1"'\033[0m'; }
function echo_warn { echo -e '\033[1;33m'"$1"'\033[0m'; }
function echo_error  { echo -e '\033[1;31mERROR: '"$1"'\033[0m'; }

echo_ok "Install starting. You may be asked for your password (for sudo)."

# requires xcode and tools!
xcode-select -p || exit "XCode must be installed! (use the app store)"

# requirements
cd ~
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
if hash brew &> /dev/null; then
	echo_ok "Homebrew already installed"
else
    echo_warn "Installing homebrew..."
	ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# RVM
if hash rvm &> /dev/null; then
	echo_ok "RVM already installed"
else
	echo "Installing RVM..."
	curl -sSL https://get.rvm.io | bash -s stable --ruby
fi

# add default gems to rvm
global_gems_config="$HOME/.rvm/gemsets/global.gems"
default_gems="bundler awesome-print lunchy rak"
for gem in $default_gems; do
	echo $gem >> $global_gems_config
done
awk '!a[$0]++' $global_gems_config > /tmp/global.tmp
mv /tmp/global.tmp $global_gems_config

# RVM ruby versions
for version in $ruby_versions; do
	source ~/.rvm/scripts/rvm
	rvm install $version
done

# moar homebrew...
brew update && brew cask upgrade

# brew taps
brew tap homebrew/cask-versions
brew tap homebrew/cask-fonts
brew tap teamookla/speedtest
brew tap heroku/brew
brew tap xo/xo

# Homebrew base
brew upgrade
brew install \
  go gpg entr tldr gh speedtest fzf freetype htop pwgen \
  jq yq libxml2 node python heroku terraform warrensbox/tap/tfswitch z\
  postgres sqlite unrar v8 wget pipenv poetry git ripgrep \
  awscli asdf rust starship vault trash zsh-autosuggestions\
  git-delta
  
  
brew install bitwarden-cli
brew install speedtest --force

# Apps
echo_warn "Installing applications..."

# google
brew install --cask google-chrome 
brew install --cask google-drive-file-stream

# other favorites
brew install --cask alacritty
brew install --cask firefox
brew install --cask slack
brew install --cask zoomus

brew cask install \
  spotify vlc \
  chrome-devtools visual-studio-code dbeaver-community \
  keybase notion docker tunnelblick spectacle authy \
  scroll-reverser alt-tab openmtp protonvpn \
  intellij-idea-ce libreoffice swiftdefaultappsprefpane
# brew imagemagick
#brew cask install inkscape
brew install librsvg
brew install imagemagick

# Install java through sdkman
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"
sdk install java

# Set one time configs
git config --global core.pager "delta --line-numbers --dark"
git config --global delta.side-by-side true
gh config set pager 'delta -s'

# Disable boot sound
sudo nvram SystemAudioVolume=%80

echo
echo_ok "Done."
echo
echo
echo "You may want to add the following settings to your .bashrc:"
echo_warn '  export HOMEBREW_CASK_OPTS="--appdir=/Applications"'
echo
