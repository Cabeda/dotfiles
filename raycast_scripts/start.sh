#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Start
# @raycast.mode fullOutput
#
# Optional parameters:
# @raycast.icon 💻
# @raycast.packageName Start
#
# Documentation:
# @raycast.description Start your day.
# @raycast.author José Cabeda
# @raycast.authorURL https://github.com/cabeda/dotfiles

cd "$(dirname "${BASH_SOURCE[0]}")" || exit

../scripts/start.py