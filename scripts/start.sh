#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title start
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🤖

# Documentation:
# @raycast.author José cabeda

set -e 

if [ ${1-"mac"} == "windows" ] 
then
    echo "Starting windows"

else
    open -a ghostty
    open -a slack -g
    open -a "Visual Studio Code" -g
    open -a "Microsoft Teams"
    open -a "Firefox" https://www.gocomics.com/random/calvinandhobbes
    open -a "Firefox" https://outlook.office.com
    open -a "Firefox" https://to-do.live.com/tasks/
    open -a "bitwarden"
    
    bash $(dirname $0)/write.sh

    echo "Good work and have a nice dev day!"
fi 
