#!/usr/bin/env bash

# Readeck Video Downloader
# Fetches items from a Readeck reading list, filters non-archived items,
# extracts video links (YouTube and other yt-dlp-compatible URLs),
# and downloads them using yt-dlp.
# Requirements: curl, jq, yt-dlp

set -euo pipefail

# Improve error visibility: log the failing command and line when ERR occurs
trap 'log_error "Error on line ${LINENO}: ${BASH_COMMAND}"' ERR
trap 'log_info "Script exiting with status $?"' EXIT

# Configuration
READECK_URL="${READECK_URL:-https://read.cabeda.dev}"
READECK_API_KEY="${READECK_API_KEY:-}"
DOWNLOAD_DIR="${READECK_DOWNLOAD_DIR:-$HOME/Downloads/readeck-videos}"
# Path to yt-dlp download archive file (keeps track of downloaded IDs)
ARCHIVE_FILE="${READECK_ARCHIVE_FILE:-$DOWNLOAD_DIR/.yt-dlp-archive.txt}"
# Maximum number of items to fetch (if API supports pagination/limit)
MAX_ITEMS="${MAX_ITEMS:-100}"
# Dry run mode: when true, the script will only print discovered URLs
# and won't invoke yt-dlp.
DRY_RUN="${DRY_RUN:-false}"
# Host filter: a regex of hosts to match for typical video providers.
# Can be overridden by setting READECK_VIDEO_HOSTS env var.
VIDEO_HOSTS="${READECK_VIDEO_HOSTS:-youtube\.com|youtu\.be|vimeo\.com|twitch\.tv|dailymotion\.com|rutube\.ru|soundcloud\.com|podcasters\.org|omny\.fm}"
# If set to true, do not filter by host (all discovered URLs will be considered).
ALLOW_ALL_HOSTS="${ALLOW_ALL_HOSTS:-false}"

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
            # Re-enable errexit after the download block
            set -e
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
    # Collect URLs from common fields that can contain video links
    # - top-level .url
    # - resources.*.src (article, log, props, thumbnail)
    # - .content (may contain inlined links)
    urls=$(echo "$data" | jq -r '.[]? | (.url // empty), (.resources.article.src // empty), (.resources.log.src // empty), (.resources.props.src // empty), (.resources.thumbnail.src // empty), (.content // empty)' 2>/dev/null || echo "")

    if [ -z "$urls" ]; then
        log_warn "No items found"
        return
    fi

    # Debug: log number of raw candidate url lines we extracted
    local raw_count
    raw_count=$(echo "$urls" | grep -cE '\S' || true)
    log_info "Found ${raw_count} raw URL/content lines; filter to video hosts..."

    # Match typical video URLs (YouTube, youtu.be, vimeo, twitch, etc.)
    # Allow any URL yt-dlp can handle by default, but filter a set of common hosts
    # Use double quotes for the regex to avoid embedded single-quote issues
    # Unescape any embedded JSON-escaped slashes to ensure URLs are matched
    local all_urls
    all_urls=$(echo "$urls" | sed -E 's/\\\//\//g' | grep -oE "https?://[^ \"\)'>]+" || true)
    if [ "$ALLOW_ALL_HOSTS" = "true" ]; then
        echo "$all_urls"
    else
        echo "$all_urls" | grep -Ei "$VIDEO_HOSTS" || true
    fi
}

# Download a video URL using yt-dlp
download_video() {
    local url="$1"
    log_info "Downloading: $url"
    log_info "Starting yt-dlp for URL: $url"

    # Use yt-dlp output template to avoid collisions and let yt-dlp skip existing files
    # --no-overwrites prevents overwriting existing files; --download-archive can track
    local out_template="$DOWNLOAD_DIR/%(title)s-%(id)s.%(ext)s"

    # Capture yt-dlp output so we can detect when a URL is skipped
    # because it's already recorded in the download archive. We
    # distinguish three outcomes:
    #  - return 0: successful download
    #  - return 2: skipped because already in archive
    #  - return 1: failure
    local out
    if out=$(yt-dlp \
        -f 'bestvideo[height<=1080]+bestaudio/best[height<=1080]' \
        --merge-output-format mp4 \
        -o "$out_template" \
        --no-playlist \
        --write-thumbnail \
        --embed-metadata \
        --no-overwrites \
        --download-archive "$ARCHIVE_FILE" \
        "$url" < /dev/null 2>&1); then
        # Check for common yt-dlp message that indicates the URL
        # was already recorded in the archive and therefore skipped.
        if echo "$out" | grep -qi "has already been recorded in the archive"; then
            log_info "Skipped (already in archive): $url"
            return 2
        fi

        log_info "Successfully downloaded: $url"
        log_info "yt-dlp output (first 300 chars): ${out:0:300}"
        return 0
    else
        log_error "Failed to download: $url"
        log_error "$out"
        return 1
    fi
}

# Main
main() {
    # Parse positional/long args: support --dry-run and --max-items
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --max-items)
                if [ -n "${2:-}" ]; then
                    MAX_ITEMS="$2"
                    shift 2
                else
                    shift
                fi
                ;;
            --max-items=*)
                MAX_ITEMS="${1#*=}"
                shift
                ;;
            --no-filter)
                ALLOW_ALL_HOSTS=true
                shift
                ;;
            *)
                # ignore unknown args
                shift
                ;;
        esac
    done

    log_info "Starting Readeck Video Downloader"
    log_info "Readeck URL: $READECK_URL"
    log_info "Download directory: $DOWNLOAD_DIR"

    check_dependencies
    check_config
    create_download_dir
    ensure_archive_file

    local items
    items=$(fetch_readeck_items)

    # Debug: log number of bookmarks and show id/url for each (useful for tracing)
    local bookmark_count
    bookmark_count=$(echo "$items" | jq -r 'length' 2>/dev/null || echo "0")
    log_info "Bookmarks retrieved: $bookmark_count"
    # Show id and url for each bookmark for debugging
    echo "$items" | jq -r '.[] | "[bookmark] id: \(.id) url: \(.url)"' 2>/dev/null || true

    # Debug: show per-bookmark extracted video URLs (if any)
    if [ "$DRY_RUN" = "true" ]; then
        echo "$items" | jq -c '.[]' 2>/dev/null | while IFS= read -r b; do
            local bid
            local burl
            bid=$(echo "$b" | jq -r '.id' 2>/dev/null)
            burl=$(echo "$b" | jq -r '.url' 2>/dev/null)
            local found
            found=$(extract_video_urls "$b" | sort -u | tr '\n' ' ')
            if [ -n "$found" ]; then
                log_info "Bookmark $bid ($burl) has video(s): $found"
            fi
        done
    fi

    # Extract URLs
    local urls
    urls=$(extract_video_urls "$items")

    # Debug: show how many candidate lines and unique URLs were found
    local candidate_count
    candidate_count=$(echo "$urls" | grep -cE '\S' || true)
    log_info "Candidate URL/content lines: $candidate_count"
    # Show first few candidate lines for debugging
    echo "$urls" | sed -n '1,200p' 2>/dev/null || true

    if [ -z "$urls" ]; then
        log_info "No video URLs found to download"
        exit 0
    fi

    if [ "$DRY_RUN" = "true" ]; then
        log_info "Dry run: printing discovered URLs (no downloads)"
        # Print unique URLs in a stable order
        echo "$urls" | sort -u
        local url_count
        url_count=$(echo "$urls" | grep -cE '\S' || true)
        log_info "Dry run complete. URLs found: $url_count"
        exit 0
    fi

    # Unique URLs
    urls=$(echo "$urls" | sort -u)
    local unique_count
    unique_count=$(echo "$urls" | grep -cE '\S' || true)
    log_info "Unique video URLs to process: $unique_count"

    local downloaded=0
    local failed=0
    local skipped=0

    # Iterate safely over URLs using process substitution so the loop's
    # stdin can't be consumed by inner commands.
    while IFS= read -r url; do
        # Trim possible carriage returns
        url=$(echo "$url" | tr -d '\r')
        if [ -n "$url" ]; then
            # Temporarily disable errexit around the download to ensure
            # any non-zero status from inner commands do not abort the whole script.
            set +e
            if download_video "$url"; then
            set -e
                ((downloaded++))
                rc=0
            else
                rc=$?
                if [ $rc -eq 2 ]; then
                    ((skipped++))
                else
                    ((failed++))
                fi
            fi
            log_info "Processed URL: $url; rc=$rc; totals D:$downloaded F:$failed S:$skipped"
        fi
    done < <(printf '%s\n' "$urls")

    log_info "Done. Downloaded: $downloaded, Failed: $failed, Skipped: $skipped"

}

main "$@"
