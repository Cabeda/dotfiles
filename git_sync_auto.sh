#!/bin/bash

git pull

git add .
git diff-index --quiet HEAD
git commit -m "Auto commit"
git pull 
git push