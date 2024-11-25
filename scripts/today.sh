#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title today
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 📝

# Documentation:
# @raycast.author José cabeda

# 0. Search for a directory under ~/ named Pensamentos
repo=~/Nextcloud2/Pensamentos/journals/$(date +"%Y")
filename=$(date +"%Y-%m-%d").md
# 1. Create a new markdown file with today date with yyyy-mm-dd.md format

touch $repo/"$filename"

# 2. Add the markdown header text with the pubdate: yyyy-mm-dd
echo "---" > $repo/"$filename"
echo "pubdate: "$filename >> $repo/"$filename"
echo "---" >> $repo/"$filename"

# 2. Open the file with vs code
code $repo/"$filename"
