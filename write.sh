#bin/bash

WIKI_DIR="~/Documents/Git/pensamentos"
CURRENT_PATH=$PWD
if [ ${1-"mac"} == "windows" ] 
then
    echo "Starting windows"
else
    open -a typora $WIKI_DIR
    open -a spotify
    bash $WIKI_DIR/git_sync.sh
fi