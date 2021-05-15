#!/bin/bash

# Starts automatic git pull and push
# Should mainly work for a single user repo like this
# REQUIREMENTS
# - git (make sure repo is public or you have credentials to access)
# - entr (checks for file changes)

git pull

while true
do
echo "Starting git auto"
{ git ls-files; git ls-files . --exclude-standard --others; } | entr bash -c 'git add . && git diff-index --quiet HEAD || git commit -m "Auto commit" && git pull && git push'

sleep 1 # Allow to exit with ctr + C

# 
done

echo "Finished sync"