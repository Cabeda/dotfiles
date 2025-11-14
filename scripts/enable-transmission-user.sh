#!/usr/bin/env bash
# Installs user-level Transmission service files and prints instructions
set -euo pipefail

CONFIG_DIR="$HOME/.config/transmission-daemon"
UNIT_DIR="$HOME/.config/systemd/user"
REPO_ROOT="$(dirname "${BASH_SOURCE[0]}")/.."

echo "Creating config dir: $CONFIG_DIR"
mkdir -p "$CONFIG_DIR"

# Copy template settings.json if it doesn't exist
if [ ! -f "$CONFIG_DIR/settings.json" ]; then
  echo "Copying settings.json template"
  cp "$REPO_ROOT/.config/transmission-daemon/settings.json" "$CONFIG_DIR/settings.json"
  echo "Remember to edit $CONFIG_DIR/settings.json and set rpc-password and rpc-username"
else
  echo "Config already exists at $CONFIG_DIR/settings.json - not overwriting"
fi

# Install user systemd unit
mkdir -p "$UNIT_DIR"
if [ ! -f "$UNIT_DIR/transmission-daemon.service" ]; then
  echo "Installing systemd user unit"
  cp "$REPO_ROOT/systemd/user/transmission-daemon.service" "$UNIT_DIR/transmission-daemon.service"
else
  echo "Systemd user unit already installed at $UNIT_DIR/transmission-daemon.service"
fi

cat <<'EOF'

Next steps (run as the user you want Transmission to run as):

1) Edit your settings:
   nano ~/.config/transmission-daemon/settings.json
   - Set "rpc-username" and "rpc-password" (the password will be hashed on first run)
   - Configure "download-dir" and other preferences

2) Reload user systemd units and enable the service:
   systemctl --user daemon-reload
   systemctl --user enable --now transmission-daemon

3) To check status:
   systemctl --user status transmission-daemon

4) Open web UI at: http://localhost:9091/ (or http://<host-ip>:9091/ if rpc-bind-address is 0.0.0.0)

5) If you want the service to start at boot for your user, ensure lingering is enabled:
   sudo loginctl enable-linger $(whoami)

Security notes:
 - The template sets rpc-authentication-required to true. Use a strong password.
 - If exposing to the network, run behind a reverse proxy with HTTPS + auth.

EOF
