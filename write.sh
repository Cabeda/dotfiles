#bin/bash

if [ ${1-"mac"} == "windows" ] 
then
    echo "Starting windows"
else
    open -a typora ~/Documents/Git/pensamentos/
    ~/Documents/Git/pensamentos/git_sync.sh
    open -a spotify
fi