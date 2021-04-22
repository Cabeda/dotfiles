#!/bin/bash

# A script to set up termux

apt install git entr zsh openssh


# Install ZSH
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

git clone https://github.com/agkozak/zsh-z $ZSH_CUSTOM/plugins/zsh-z

# Set dotfiles configs to be the ones used by the system
# ln -s .tmux.conf ~/.tmux.conf
# ln -s .vimrc ~/.vimrc
# ln -s .zshrc ~/.zshrc
# ln -s .alacritty.yml ~/.alacritty.yml


# Git setup ssh key
export SSH_AUTH_SOCK=$HOME/.sshagent
eval $(ssh-agent -a "$SSH_AUTH_SOCK")
ssh-add
ssh-add ~/.ssh/id_rsa