#bin/bash

WIKI_DIR="~/Documents/Git/pensamentos"

if [ ${1-"mac"} == "windows" ] 
then
    echo "Starting windows"
else
    open -a typora ~/Documents/Git/pensamentos
    open -a spotify
    cd ~/Documents/Git/pensamentos
    bash git_sync.sh
fi