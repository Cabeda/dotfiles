#bin/bash

# This is a small script that I run every day to start working


if [ ${1-"mac"} == "windows" ] 
then
    echo "Starting windows"

else
    open -a spotify -g
    # open -a notion -g
    open -a slack -g
    open -a "Visual Studio Code" -g
    open -a "Google Chrome" 
    open -a firefox https://www.gocomics.com/random/calvinandhobbes
    open -a "authy desktop"
    open -a "bitwarden"

    echo "Good work and have a nice dev day!"
fi 
