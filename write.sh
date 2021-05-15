#bin/bash

WIKI_DIR="~/Documents/Git/pensamentos/"

if [ ${1-"mac"} == "windows" ] 
then
    echo "Starting windows"
else
    cd $WIKI_DIR
    open -a typora .
    git_sync.sh
    open -a spotify
fi