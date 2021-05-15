#bin/bash

WIKI_DIR="~/Documents/Git/pensamentos"

if [ ${1-"mac"} == "windows" ] 
then
    echo "Starting windows"
else
    open -a typora ~/Documents/Git/pensamentos
    ~/Documents/Git/pensamentos/git_sync.sh
    open -a spotify
fi