#bin/bash

WIKI_DIR="$HOME/Documents/Git/pensamentos"
GIT_SYNC_PATH="$HOME/Documents/Git/dotfiles"

if [ ${1-"mac"} == "windows" ] 
then
    echo "Starting windows"
else
    open -a typora $WIKI_DIR
    # open -a spotify
    cd $WIKI_DIR
    bash $GIT_SYNC_PATH/git_sync.sh
fi