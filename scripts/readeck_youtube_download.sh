#!/usr/bin/env bash

# Readeck Video Downloader
# Fetches items from a Readeck reading list, filters non-archived items,
# extracts video links (YouTube and other yt-dlp-compatible URLs),
# and downloads them using yt-dlp.
# Requirements: curl, jq, yt-dlp

set -euo pipefail

# Configuration
READECK_URL="${READECK_URL:-https://read.cabeda.dev}"
READECK_API_KEY="${READECK_API_KEY:-}"
DOWNLOAD_DIR="${READECK_DOWNLOAD_DIR:-$HOME/Downloads/readeck-videos}"
# Path to yt-dlp download archive file (keeps track of downloaded IDs)
ARCHIVE_FILE="${READECK_ARCHIVE_FILE:-$DOWNLOAD_DIR/.yt-dlp-archive.txt}"
# Maximum number of items to fetch (if API supports pagination/limit)
MAX_ITEMS="${MAX_ITEMS:-100}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions (to stderr so stdout can be used for data)
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

# Dependencies
check_dependencies() {
    local missing_deps=()
    for cmd in curl jq yt-dlp; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done

    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        log_info "Install them with: brew install ${missing_deps[*]}"
        exit 1
    fi
}

check_config() {
    if [ -z "$READECK_API_KEY" ]; then
        log_error "READECK_API_KEY is not set"
        log_info "Set it with: export READECK_API_KEY=your_api_key"
        exit 1
    fi
}

create_download_dir() {
    if [ ! -d "$DOWNLOAD_DIR" ]; then
        log_info "Creating download directory: $DOWNLOAD_DIR"
        mkdir -p "$DOWNLOAD_DIR"
    fi
}

# Ensure archive file exists and is writable
ensure_archive_file() {
    if [ ! -f "$ARCHIVE_FILE" ]; then
        touch "$ARCHIVE_FILE" || log_warn "Could not create archive file: $ARCHIVE_FILE"
    fi
}

# Fetch items from Readeck
fetch_readeck_items() {
    log_info "Fetching items from Readeck..."
    log_info "URL: ${READECK_URL}/api/bookmarks?is_archived=false&limit=${MAX_ITEMS}"

    local response
    response=$(curl -s -H "Authorization: Bearer $READECK_API_KEY" \
        "${READECK_URL}/api/bookmarks?is_archived=false&limit=${MAX_ITEMS}")

    local curl_exit=$?
    if [ $curl_exit -ne 0 ]; then
        log_error "Failed to connect to Readeck at $READECK_URL"
        log_error "curl exit code: $curl_exit"
        exit 1
    fi

    # Debug: first 200 chars
    log_info "Response (first 200 chars): ${response:0:200}"

    # Validate JSON
    local jq_err
    jq_err=$(echo "$response" | jq empty 2>&1) || true
    if [ -n "$jq_err" ]; then
        log_error "Invalid JSON response from Readeck"
        log_error "jq error: $jq_err"
        log_error "Full response: $response"
        exit 1
    fi

    echo "$response"
}

# Extract video URLs - matches YouTube and other typical domains handled by yt-dlp
extract_video_urls() {
    local data="$1"
    # Extract possible URLs from 'url' and 'content' fields if present
    local urls
    urls=$(echo "$data" | jq -r '.[]? | .url, .content' 2>/dev/null || echo "")

    if [ -z "$urls" ]; then
        log_warn "No items found"
        return
    fi

    # Match typical video URLs (YouTube, youtu.be, vimeo, twitch, etc.)
    # Allow any URL yt-dlp can handle by default, but filter a set of common hosts
    # Use double quotes for the regex to avoid embedded single-quote issues
    echo "$urls" | grep -oE "https?://[^ \"\)'>]+" | grep -Ei 'youtube\.com|youtu\.be|vimeo\.com|twitch\.tv|dailymotion\.com|rutube\.ru|soundcloud\.com|podcasters\.org' || true
}

# Download a video URL using yt-dlp
download_video() {
    local url="$1"
    log_info "Downloading: $url"

    # Use yt-dlp output template to avoid collisions and let yt-dlp skip existing files
    # --no-overwrites prevents overwriting existing files; --download-archive can track
    local out_template="$DOWNLOAD_DIR/%(title)s-%(id)s.%(ext)s"

    yt-dlp \
        -f 'bestvideo[height<=1080]+bestaudio/best[height<=1080]' \
        --merge-output-format mp4 \
        -o "$out_template" \
        --no-playlist \
        --write-thumbnail \
        --embed-metadata \
        --no-overwrites \
        --download-archive "$ARCHIVE_FILE" \
        "$url"

    if [ $? -eq 0 ]; then
        log_info "Successfully downloaded: $url"
        return 0
    else
        log_error "Failed to download: $url"
        return 1
    fi
}

# Main
main() {
    log_info "Starting Readeck Video Downloader"
    log_info "Readeck URL: $READECK_URL"
    log_info "Download directory: $DOWNLOAD_DIR"

    check_dependencies
    check_config
    create_download_dir
    ensure_archive_file

    local items
    items=$(fetch_readeck_items)

    # Extract URLs
    local urls
    urls=$(extract_video_urls "$items")

    if [ -z "$urls" ]; then
        log_info "No video URLs found to download"
        exit 0
    fi

    # Unique URLs
    urls=$(echo "$urls" | sort -u)

    local downloaded=0
    local failed=0

    while IFS= read -r url; do
        if [ -n "$url" ]; then
            if download_video "$url"; then
                ((downloaded++))
            else
                ((failed++))
            fi
        fi
    done <<< "$urls"

    log_info "Done. Downloaded: $downloaded, Failed: $failed"
}

main "$@"
