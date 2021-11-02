#!/bin/bash

WIKI_DIR="$HOME/Git/pensamentos"
GIT_SYNC_PATH="$HOME/Git/dotfiles"

if [ ${1-"mac"} == "windows" ] 
then
    echo "Starting windows"
else
    open -a "Visual Studio Code" $WIKI_DIR
    cd $WIKI_DIR
    bash $GIT_SYNC_PATH/git_sync.sh
fi