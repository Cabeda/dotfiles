#!/bin/bash

# A script to set up termux

# Enable storage 
termux-setup-storage

# Set dotfiles configs to be the ones used by the system
ln -s .tmux.conf ~/.tmux.conf
ln -s .vimrc ~/.vimrc
ln -s .zshrc ~/.zshrc
ln -s .alacritty.yml ~/.alacritty.yml

# Install packages
pkg install git zoxide bat starship tsu
apt install entr zsh openssh

curl -s https://install.speedtest.net/app/cli/install.deb.sh | sudo bash
sudo apt-get install speedtest

# Install oh my ZSH
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# Git setup ssh key
export SSH_AUTH_SOCK=$HOME/.sshagent
eval $(ssh-agent -a "$SSH_AUTH_SOCK")
ssh-add
ssh-add ~/.ssh/id_rsa

source ~/.zshrc

echo "speedtest\n read" >> ~/.shortcuts/speedtest.sh