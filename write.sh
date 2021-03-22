#bin/bash

if [ ${1-"mac"} == "windows" ] 
then
    echo "Starting windows"
else
    code ~/Documents/Git/pensamentos/
    open -a spotify
fi