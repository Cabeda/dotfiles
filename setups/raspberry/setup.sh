#!/bin/sh

# Install jellyfin and transmission

curl -LsSf https://astral.sh/uv/install.sh | sh
sudo apt install jellyfin transmission \
    tealdeer fzf ripgrep zsh zoxide trash-cli yt-dlp \
    hx speedtest

curl -sS https://starship.rs/install.sh | sh
curl -LSfs https://raw.githubusercontent.com/cantino/mcfly/master/ci/install.sh | sh -s -- --git cantino/mcfly
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh 
sudo apt install libdbus-1-dev pkg-config && cargo install bluetui

touch /root/.zsh_history
eval "$(mcfly init zsh)"


sudo apt install podman podman-docker podman-compose
sudo systemctl enable --now podman.socket
