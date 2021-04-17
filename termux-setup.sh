#!/bin/bash

# A script to set up termux

apt install git entr zsh

# Setup git


# Install ZSH
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"


# Set dotfiles configs to be the ones used by the system
sudo ln -f .tmux.conf ~/.tmux.conf
sudo ln -f .vimrc ~/.vimrc
sudo ln -f .zshrc ~/.zshrc
sudo ln -f .alacritty.yml ~/.alacritty.yml