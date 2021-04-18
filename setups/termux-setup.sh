#!/bin/bash

# A script to set up termux

apt install git entr zsh

# Setup git


# Install ZSH
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"


# Set dotfiles configs to be the ones used by the system
# ln -s .tmux.conf ~/.tmux.conf
# ln -s .vimrc ~/.vimrc
# ln -s .zshrc ~/.zshrc
# ln -s .alacritty.yml ~/.alacritty.yml


# Git setup ssh key
eval $(ssh-agent)
ssh-add
ssh-add ~/.ssh/id_rsa