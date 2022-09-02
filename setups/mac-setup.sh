#!/bin/bash

# A script to set up a new mac. Uses bash, homebrew, etc.

# Settings
ruby_versions="2.7.0"
python="3.8.1"
ruby_default="2.7.0"

# helpers
function echo_ok { echo -e '\033[1;32m'"$1"'\033[0m'; }
function echo_warn { echo -e '\033[1;33m'"$1"'\033[0m'; }
function echo_error { echo -e '\033[1;31mERROR: '"$1"'\033[0m'; }

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
brew tap homebrew/cask-versions
brew tap homebrew/cask-fonts
brew tap heroku/brew
brew tap xo/xo
brew tap cantino/mcfly
brew tap turbot/tap
brew tap microsoft/git

# Homebrew base
brew upgrade
brew install \
  go gpg entr tealdeer gh fzf freetype htop pwgen \
  jq yq libxml2 python heroku warrensbox/tap/tfswitch \
  sqlite v8 wget pipenv poetry pipx git ripgrep \
  awscli asdf rust starship vault trash zsh-autosuggestions \
  git-delta watch zoxide dog m-cli bat \
  exa mcfly dive lazydocker jless tmux broot \
  direnv thefuck jc lazygit

# Set file for env files
touch ~/env

# Gh config
gh extension install dlvhdr/gh-dash

# ASDF plugins
asdf plugin-add java https://github.com/halcyon/asdf-java.git
asdf plugin-add python # https://github.com/danhper/asdf-python


# Install java 
. ~/.asdf/plugins/java/set-java-home.zsh
asdf install java openjdk-11.0.2
asdf global java openjdk-11.0.2

# Apps
echo_warn "Installing applications..."

brew install --cask \
  spotify vlc alacritty slack zoomus google-chrome visual-studio-code \
  notion docker openmtp swiftdefaultappsprefpane raycast \
  font-jetbrains-mono font-jetbrains-mono-nerd-font handbrake bitwarden \ git-credential-manager-core insomnia lens

# brew imagemagick
#brew cask install inkscape
brew install librsvg
brew install imagemagick

# Set one time configs
git config --global core.pager "delta --line-numbers --dark"
git config --global delta.side-by-side true
git config --global --add --bool push.autoSetupRemote true
gh config set pager 'delta -s'
# Set background image
osascript -e 'tell application "Finder" to set desktop picture to POSIX file "/Users/jose.cabeda/Git/dotfiles/backgrounds/clement-dartigues-scirie.jpeg"'

# Set dotfiles configs to be the ones used by the system
mkdir -p ~/.config
mkdir -p ~/.config/alacritty
mkdir -p ~/.config/prs
mkdir -p ~/.config/gh-dash

ln -f .tmux.conf ~/.tmux.conf
ln -f .vimrc ~/.vimrc
ln -f .nanorc ~/.nanorc
ln -f .zshrc ~/.zshrc
ln -f .gitconfig ~/.gitconfig
ln -f alacritty.yml ~/.config/alacritty/alacritty.yml
ln -f starship.toml ~/.config/starship.toml
ln -f github_prs.yml ~~/.config/gh-dash/config.yml
ln -f .tool-versions ~/.tool-versions

# Disable boot sound
sudo nvram SystemAudioVolume=%80

echo
echo_ok "Done."
echo
echo
echo "You may want to add the following settings to your .bashrc:"
echo_warn '  export HOMEBREW_CASK_OPTS="--appdir=/Applications"'
echo
