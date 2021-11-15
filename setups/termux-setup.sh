#!/bin/bash

# A script to set up termux

# Enable storage 
termux-setup-storage

GIT_FOLDER="$HOME/git/dotfiles"

# Set dotfiles configs to be the ones used by the system
ln -s "$GIT_FOLDER/.tmux.conf" "$HOME/.tmux.conf"
ln -s "$GIT_FOLDER/.vimrc" "$HOME/.vimrc"
ln -s "$GIT_FOLDER/.zshrc" "$HOME/.zshrc"
ln -s "$GIT_FOLDER/.alacritty.yml" "$HOME/.alacritty.yml"

# Install packages
pkg install git zoxide bat starship tsu python
apt install entr zsh openssh 

curl -s https://install.speedtest.net/app/cli/install.deb.sh | sudo bash
sudo apt-get install speedtest

pip install time-tracker speedtest-cli

# Git setup ssh key
export SSH_AUTH_SOCK=$HOME/.sshagent
eval $(ssh-agent -a "$SSH_AUTH_SOCK")
ssh-add
ssh-add ~/.ssh/id_rsa

source ~/.zshrc

echo "speedtest-cli" > ~/.shortcuts/speedtest.sh
echo "tt track" > ~/.shortcuts/pomodoro.sh