#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Write
# @raycast.mode fullOutput
#
# Optional parameters:
# @raycast.icon ✍🏼
# @raycast.packageName Write
#
# Documentation:
# @raycast.description Write mode.
# @raycast.author José Cabeda
# @raycast.authorURL https://github.com/cabeda/dotfiles

cd "$(dirname "${BASH_SOURCE[0]}")" || exit

../write.sh