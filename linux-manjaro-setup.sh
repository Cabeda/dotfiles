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
                ripgrep steam vim

curl https://zoom.us/client/latest/zoom_x86_64.pkg.tar.xz --output ~/Downloads/zoom.pkg.tar.xz
sudo pacman -U ~/Downloads/zoom.pkg.tar.xz

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
ln -f .alacritty.yml ~/.alacritty.yml

echo
echo_ok "Done."
echo