#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title music
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🎧
# @raycast.argument1 {"type": "dropdown", "placeholder": "type", "data": [{"title": "Synth", "value": "https://www.youtube.com/live/4xDzrJKXOOY"}, {"title": "Lofi", "value": "https://www.youtube.com/live/jfKfPfyJRdk"}, {"title": "offline", "value": "/Users/jose.cabeda/Git/dotfiles/synth.mp4"}] }

# Documentation:
# @raycast.author José cabeda



mpv $1 --loop