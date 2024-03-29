#!/bin/bash

ssh-keygen -t ed25519 -C "jecabeda@gmail.com"
eval "$(ssh-agent -s)"

# Remove flag -K if not mac machine
ssh-add -K ~/.ssh/id_ed25519

# pbcopy only works on MAC (copy output to github)
cat ~/.ssh/id_ed25519.pub
pbcopy < ~/.ssh/id_ed25519.pub