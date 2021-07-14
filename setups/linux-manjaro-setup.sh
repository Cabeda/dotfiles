#!/bin/bash

# oh my zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"




#Install starship
curl -fsSL https://starship.rs/install.sh | bash

# Install pacman packages (prefered)

# Update package list
sudo pacman -Sy

sudo pacman -S alacritty bitwarden tldr git \
                fzf z vlc github-cli docker \
                pwgen jq yq nodejs postgresql \
                ripgrep steam vim tmux nodejs gnome-keyring

curl https://zoom.us/client/latest/zoom_x86_64.pkg.tar.xz --output ~/Downloads/zoom.pkg.tar.xz
sudo pacman -U ~/Downloads/zoom.pkg.tar.xz

#Get zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# Get z command
git clone https://github.com/agkozak/zsh-z $ZSH_CUSTOM/plugins/zsh-z

# Install snap packages
sudo pacman -S snapd
sudo snap install code --classic
sudo snap install authy --beta

# Install Python poetry
curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python -
pip install pipenv

# Install wtih brew (secdond option)
brew install \
  zoomus notion\
  gpg speedtest \
  
sudo pacman -S base-devel

ln -f .tmux.conf ~/.tmux.conf
ln -f .vimrc ~/.vimrc
ln -f .zshrc ~/.zshrc
ln -f alacritty.yml ~/alacritty.yml

# Set system configs
xset r rate 195 35 # Reduce keyboard latency


echo
echo_ok "Done."
echo
