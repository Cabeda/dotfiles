#!/usr/bin/env bash

# Miniflux YouTube Downloader
# Downloads YouTube videos from Miniflux RSS feed entries
# Requirements: curl, jq, yt-dlp

set -euo pipefail

# Configuration
MINIFLUX_URL="${MINIFLUX_URL:-https://feed.cabeda.dev}"
MINIFLUX_API_KEY="${MINIFLUX_API_KEY:-}"
DOWNLOAD_DIR="${MINIFLUX_DOWNLOAD_DIR:-$HOME/Downloads/miniflux-videos}"
# Path to yt-dlp download archive file (keeps track of downloaded IDs)
ARCHIVE_FILE="${MINIFLUX_ARCHIVE_FILE:-$DOWNLOAD_DIR/.yt-dlp-archive.txt}"
# Maximum number of entries to fetch (optional)
MAX_ENTRIES="${MAX_ENTRIES:-100}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

# Check required commands
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

# Check configuration
check_config() {
    if [ -z "$MINIFLUX_API_KEY" ]; then
        log_error "MINIFLUX_API_KEY is not set"
        log_info "Set it with: export MINIFLUX_API_KEY=your_api_key"
        log_info "Get your API key from Miniflux: Settings > API Keys"
        exit 1
    fi
}

# Create download directory
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

# Extract YouTube URLs from text
extract_youtube_urls() {
    local text="$1"
    echo "$text" | grep -oE 'https?://(www\.)?(youtube\.com/watch\?v=|youtu\.be/)[A-Za-z0-9_-]+' || true
}

# Fetch unread entries from Miniflux
fetch_miniflux_entries() {
    log_info "Fetching entries from Miniflux..."
    log_info "URL: ${MINIFLUX_URL}/v1/entries?status=unread&limit=${MAX_ENTRIES}"
    
    local response
    response=$(curl -s -H "X-Auth-Token: $MINIFLUX_API_KEY" \
        "${MINIFLUX_URL}/v1/entries?status=unread&limit=${MAX_ENTRIES}")
    
    local curl_exit=$?
    
    if [ $curl_exit -ne 0 ]; then
        log_error "Failed to connect to Miniflux at $MINIFLUX_URL"
        log_error "curl exit code: $curl_exit"
        exit 1
    fi
    
    # Debug: show first 200 chars of response
    log_info "Response (first 200 chars): ${response:0:200}"
    
    # Check if response is valid JSON
    local jq_error
    jq_error=$(echo "$response" | jq empty 2>&1)
    if [ $? -ne 0 ]; then
        log_error "Invalid JSON response from Miniflux"
        log_error "jq error: $jq_error"
        log_error "Full response: $response"
        exit 1
    fi
    
    echo "$response"
}

# Extract YouTube links from entries
extract_youtube_links() {
    local entries="$1"
    local youtube_links=()
    
    # Extract URLs from entry content and URLs
    local all_urls
    all_urls=$(echo "$entries" | jq -r '.entries[]? | .url, .content' 2>/dev/null || echo "")
    
    if [ -z "$all_urls" ]; then
        log_warn "No entries found"
        return
    fi
    
    # Find YouTube URLs
    local youtube_urls
    youtube_urls=$(extract_youtube_urls "$all_urls")
    
    if [ -z "$youtube_urls" ]; then
        log_info "No YouTube links found in entries"
        return
    fi
    
    # Remove duplicates
    youtube_urls=$(echo "$youtube_urls" | sort -u)
    
    echo "$youtube_urls"
}

# Download a YouTube video
download_video() {
    local url="$1"
    local video_id
    video_id=$(echo "$url" | grep -oE '[A-Za-z0-9_-]{11}' | head -1)
    
    log_info "Downloading: $url"
    
    # Check if already downloaded
    if ls "$DOWNLOAD_DIR"/*"$video_id"* 1> /dev/null 2>&1; then
        log_warn "Video already exists, skipping: $video_id"
        return 0
    fi
    
    # Download with yt-dlp
    # Options:
    # -f bestvideo[height<=1080]+bestaudio/best[height<=1080]: Max 1080p quality
    # --merge-output-format mp4: Output as MP4
    # -o: Output template
    # --no-playlist: Don't download playlists
    # --write-thumbnail: Save thumbnail
    # --embed-metadata: Embed metadata
    yt-dlp \
        -f 'bestvideo[height<=1080]+bestaudio/best[height<=1080]' \
        --merge-output-format mp4 \
        -o "$DOWNLOAD_DIR/%(title)s-%(id)s.%(ext)s" \
        --no-playlist \
        --write-thumbnail \
        --embed-metadata \
        --download-archive "$ARCHIVE_FILE" \
        "$url"
    
    if [ $? -eq 0 ]; then
        log_info "Successfully downloaded: $video_id"
        return 0
    else
        log_error "Failed to download: $url"
        return 1
    fi
}

# Mark entry as read in Miniflux (optional)
mark_as_read() {
    local entry_id="$1"
    
    curl -s -X PUT \
        -H "X-Auth-Token: $MINIFLUX_API_KEY" \
        -H "Content-Type: application/json" \
        -d '{"entry_ids": ['"$entry_id"'], "status": "read"}' \
        "${MINIFLUX_URL}/v1/entries" > /dev/null
    
    log_info "Marked entry $entry_id as read"
}

# Main function
main() {
    log_info "Starting Miniflux YouTube Downloader"
    log_info "Miniflux URL: $MINIFLUX_URL"
    log_info "Download directory: $DOWNLOAD_DIR"
    
    check_dependencies
    check_config
    create_download_dir
    ensure_archive_file
    
    # Fetch entries
    local entries
    entries=$(fetch_miniflux_entries)
    
    local total_entries
    total_entries=$(echo "$entries" | jq -r '.total // 0')
    log_info "Found $total_entries total unread entries"
    
    # Extract YouTube links
    local youtube_urls
    youtube_urls=$(extract_youtube_links "$entries")
    
    if [ -z "$youtube_urls" ]; then
        log_info "No YouTube videos to download"
        exit 0
    fi
    
    local video_count
    video_count=$(echo "$youtube_urls" | wc -l | tr -d ' ')
    log_info "Found $video_count YouTube videos to download"
    
    # Download each video
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
    done <<< "$youtube_urls"
    
    log_info "Download complete!"
    log_info "Successfully downloaded: $downloaded"
    if [ $failed -gt 0 ]; then
        log_warn "Failed downloads: $failed"
    fi
}

# Run main function
main "$@"
