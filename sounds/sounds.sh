#!/bin/bash

# Play an mp3 sound on vlc through the command line on loop
# Start with interface minimized

# Usage: ./sounds.sh

vlc --loop --play-and-exit /Users/josecabeda/Git/dotfiles/sounds/rain.mp3 &
osascript -e 'tell application "vlc" to set miniaturized of every window to true'
