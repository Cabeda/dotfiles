#!/bin/bash

# Concatenate all mp3 files into a single mp3 file
for file in *.mp3; do
    echo "file '$file'" >> list.txt
done

ffmpeg -f concat -safe 0 -i list.txt -c copy output.mp3

# Convert the single mp3 file to m4b
ffmpeg -i output.mp3 -c:a aac -b:a 64k -f mp4 output.m4b

# Clean up
rm list.txt output.mp3