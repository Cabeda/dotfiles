#bin/bash

WIKI_DIR="~/Documents/Git/pensamentos"
CURRENT_PATH=$PWD
if [ ${1-"mac"} == "windows" ] 
then
    echo "Starting windows"
else
    open -a typora $WIKI_DIR
    open -a spotify
    cd ~/Documents/Git/pensamentos
    bash $CURRENT_PATH/git_sync.sh
fi