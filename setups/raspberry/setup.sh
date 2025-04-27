#!/bin/sh

# Install jellyfin and transmission

curl -LsSf https://astral.sh/uv/install.sh | sh
sudo apt install jellyfin transmission \
    tealdeer fzf ripgrep zsh zoxide trash-cli

curl -sS https://starship.rs/install.sh | sh
curl -LSfs https://raw.githubusercontent.com/cantino/mcfly/master/ci/install.sh | sh -s -- --git cantino/mcfly

touch /root/.zsh_history
eval "$(mcfly init zsh)"

