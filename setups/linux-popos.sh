#!/bin/sh

sudo apt install system76-driver-nvidia

nvidia-smi

sudo apt install ubuntu-restricted-extras
sudo apt install snapd
sudo apt install zsh
sudo apt install zoxide



#Install asdf
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.13.1


# oh my zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

#Install starship
curl -fsSL https://starship.rs/install.sh | sh


# Install Python poetry
sudo apt install pipx
pipx ensurepath
pipx install poetry

#APT install
sudo snap install direnv asdf tldr


# Set config files
ln -f .tmux.conf ~/.tmux.conf
ln -f .vimrc ~/.vimrc
ln -f .zshrc ~/.zshrc
ln -f alacritty.yml ~/alacritty.yml

echo
echo_ok "Done."
echo
