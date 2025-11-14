Transmission user service setup

Files added:
- `systemd/user/transmission-daemon.service` - user-level systemd unit
- `.config/transmission-daemon/settings.json` - template settings (update rpc-password)
- `scripts/enable-transmission-user.sh` - helper installer script

Quick setup

1) Run the installer script:
   bash scripts/enable-transmission-user.sh

2) Edit your settings:
   nano ~/.config/transmission-daemon/settings.json
   - Set `rpc-username` and `rpc-password` (the password will be hashed on first run)

3) Reload user units and enable:
   systemctl --user daemon-reload
   systemctl --user enable --now transmission-daemon

4) Optional: enable lingering so service starts at boot for your user:
   sudo loginctl enable-linger $(whoami)

Security notes

- The template sets `rpc-authentication-required` to true.
- If exposing the UI externally, put Transmission behind a reverse proxy with HTTPS and add extra authentication.
