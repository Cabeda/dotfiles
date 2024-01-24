#!/bin/bash

# This is a small script that I run every day to start working


if [ ${1-"mac"} == "windows" ] 
then
    echo "Starting windows"

else
    open -a spotify -g
    open -a slack -g
    open -a "Visual Studio Code" -g
    open -a "Google Chrome" 
    open -a "Microsoft Outlook"
    open -a "Microsoft Teams" 
    open -a "Firefox" https://www.gocomics.com/random/calvinandhobbes
    open -a "bitwarden"
    
    bash $(dirname $0)/write.sh

    echo "Good work and have a nice dev day!"
fi 
