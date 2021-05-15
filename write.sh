#bin/bash

WIKI_DIR="~/Documents/Git/pensamentos"

if [ ${1-"mac"} == "windows" ] 
then
    echo "Starting windows"
else
    open -a typora ~/Documents/Git/pensamentos
    open -a spotify
    ~/Documents/Git/pensamentos/git_sync.sh
fi