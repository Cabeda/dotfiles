#!/bin/bash

# Migrate MKV files to AV1 format
# Compatible with macOS and Raspberry Pi OS (Linux)

usage() {
    echo "Usage: $0 [-r] [-s] [directory]"
    echo "  -r: Replace original files (deletes original after successful conversion)"
    echo "  -s: Search recursively in subdirectories"
    echo "  directory: Target directory (defaults to current directory)"
    exit 1
}

REPLACE_ORIGINAL=false
RECURSIVE=false
TARGET_DIR="."

# Parse flags
while getopts "rs" opt; do
    case $opt in
        r) REPLACE_ORIGINAL=true ;;
        s) RECURSIVE=true ;;
        *) usage ;;
    esac
done
shift $((OPTIND-1))

# Target directory is the next argument if provided
if [ ! -z "$1" ]; then
    TARGET_DIR="$1"
fi

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo "Error: ffmpeg is not installed."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "Install it using: brew install ffmpeg"
    else
        echo "Install it using: sudo apt update && sudo apt install ffmpeg"
    fi
    exit 1
fi

# Determine the best available AV1 encoder
if ffmpeg -encoders 2>/dev/null | grep -q libsvtav1; then
    ENCODER="libsvtav1"
    # SVT-AV1 settings: preset 8 is a good balance, crf 35 is decent quality
    PARAMS="-c:v libsvtav1 -preset 8 -crf 35"
elif ffmpeg -encoders 2>/dev/null | grep -q libaom-av1; then
    ENCODER="libaom-av1"
    # libaom-av1 settings: cpu-used 6 for speed, crf 35
    PARAMS="-c:v libaom-av1 -crf 35 -b:v 0 -cpu-used 6"
else
    echo "Error: No AV1 encoder (libsvtav1 or libaom-av1) found in ffmpeg."
    exit 1
fi

if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Directory '$TARGET_DIR' not found."
    exit 1
fi

# Setup output strategy
if [ "$REPLACE_ORIGINAL" = true ]; then
    echo "MODE: Replace original files"
else
    OUTPUT_DIR="$TARGET_DIR/av1_converted"
    mkdir -p "$OUTPUT_DIR"
    echo "MODE: Save to subfolder ($OUTPUT_DIR)"
fi

echo "Scanning for MKV files in: $TARGET_DIR"
if [ "$RECURSIVE" = true ]; then
    echo "Search mode: Recursive"
else
    echo "Search mode: Current directory only"
fi
echo "Using encoder: $ENCODER"
echo "--------------------------------------------------"

# Use find with -print0 and read -d '' to handle filenames with spaces/special characters
FIND_OPTS="-maxdepth 1"
if [ "$RECURSIVE" = true ]; then
    FIND_OPTS=""
fi

find "$TARGET_DIR" $FIND_OPTS -iname "*.mkv" -type f -print0 | while IFS= read -r -d '' file; do
    filename=$(basename "$file")
    
    if [ "$REPLACE_ORIGINAL" = true ]; then
        output_file="${file}.tmp.mkv"
    else
        # Mirror directory structure in output folder to avoid collisions
        rel_path="${file#$TARGET_DIR}"
        rel_path="${rel_path#/}"
        output_file="$OUTPUT_DIR/$rel_path"
        mkdir -p "$(dirname "$output_file")"
    fi
    
    echo "Processing: $filename"
    
    # Run ffmpeg
    # -map 0: include all streams (video, audio, subtitles)
    # -c:a copy: copy audio without re-encoding
    # -c:s copy: copy subtitles without re-encoding
    # -y: overwrite output if it exists
    ffmpeg -i "$file" -map 0 $PARAMS -c:a copy -c:s copy "$output_file" -hide_banner -loglevel error -stats -y
    
    if [ $? -eq 0 ]; then
        if [ "$REPLACE_ORIGINAL" = true ]; then
            mv "$output_file" "$file"
            echo "Done: Replaced $filename"
        else
            echo "Done: $filename -> $output_file"
        fi
    else
        echo "Error: Failed to process $filename"
        [ -f "$output_file" ] && rm "$output_file"
    fi
    echo "--------------------------------------------------"
done

echo "Migration finished."
