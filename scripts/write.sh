#!/bin/bash


if [ ${1-"mac"} == "windows" ] 
then
    echo "Starting windows"
else
    open -a anytype
fi