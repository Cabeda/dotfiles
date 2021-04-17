#!/bin/bash

# A script to set up termux

apt install git entr

# Setup git


# Install ZSH
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"


# Set dotfiles configs to be the ones used by the system
ln -f .tmux.conf ~/.tmux.conf
ln -f .vimrc ~/.vimrc
ln -f .zshrc ~/.zshrc
ln -f .alacritty.yml ~/.alacritty.yml