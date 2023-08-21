#!/bin/bash

# This is a small script that I run every day to start working

if [ ${1-"mac"} == "windows" ]; then
    echo "Starting windows"

else
    open -a slack -g
    open -a "Visual Studio Code" -g
    open -a "Google Chrome"
    open -a "bitwarden"
    open -a "Firefox" https://www.gocomics.com/random/calvinandhobbes
    open -a "Brave Browser" --args --app=https://web.whatsapp.com

    echo "Good work and have a nice dev day!"
fi
