#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title start
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🤖

# Documentation:
# @raycast.author José cabeda

if [ ${1-"mac"} == "windows" ] 
then
    echo "Starting windows"

else
    open -a slack -g
    open -a "Visual Studio Code" -g
    open -a "Safari" 
    open -a "Microsoft Outlook"
    open -a "Microsoft Teams (work or school)"
    open -a "Firefox" https://www.music.youtube.com
    open -a "Firefox" https://www.gocomics.com/random/calvinandhobbes
    open -a "bitwarden"
    
    bash $(dirname $0)/write.sh

    echo "Good work and have a nice dev day!"
fi 
