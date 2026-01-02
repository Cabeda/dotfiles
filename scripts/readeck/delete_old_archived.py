import os
import sys
import json
import datetime
import urllib.request
import urllib.parse

def main():
    # Configuration from environment variables
    readeck_url = os.environ.get('READECK_URL', 'https://read.cabeda.dev')
    readeck_token = os.environ.get('READECK_API_KEY')

    if not readeck_token:
        print("Error: READECK_API_KEY environment variable is not set.")
        print("Please set it with: export READECK_API_KEY='your_token_here'")
        sys.exit(1)

    # Calculate date 60 days ago
    sixty_days_ago = datetime.datetime.now() - datetime.timedelta(days=60)
    # Format as ISO 8601 (YYYY-MM-DD)
    range_end = sixty_days_ago.strftime('%Y-%m-%d')

    print(f"Targeting archived bookmarks created before: {range_end}")

    base_api_url = f"{readeck_url.rstrip('/')}/api"
    
    # Fetch archived bookmarks
    # We use range_end to filter by creation date and type=article
    params = {
        'is_archived': 'true',
        'range_end': range_end,
        'type': 'article',
        'limit': 100
    }
    
    bookmarks_to_delete = []
    offset = 0
    
    print("Fetching bookmarks...")
    while True:
        query_params = {**params, 'offset': offset}
        query_string = urllib.parse.urlencode(query_params)
        url = f"{base_api_url}/bookmarks?{query_string}"
        
        req = urllib.request.Request(url)
        req.add_header('Authorization', f'Bearer {readeck_token}')
        req.add_header('Accept', 'application/json')
        
        try:
            with urllib.request.urlopen(req) as response:
                data = json.loads(response.read().decode())
                if not data:
                    break
                bookmarks_to_delete.extend(data)
                
                # Check if we should continue fetching
                total_count = int(response.headers.get('Total-Count', 0))
                print(f"Fetched {len(bookmarks_to_delete)} / {total_count} bookmarks...")
                
                if len(data) < params['limit'] or len(bookmarks_to_delete) >= total_count:
                    break
                offset += params['limit']
        except Exception as e:
            print(f"Error fetching bookmarks: {e}")
            break

    if not bookmarks_to_delete:
        print("No archived bookmarks found older than 60 days.")
        return

    print(f"\nFound {len(bookmarks_to_delete)} bookmarks to delete.")
    
    # Confirm with user if running interactively? 
    # For a script like this, maybe just a dry run option or just go for it.
    # I'll add a simple check for DRY_RUN env var.
    dry_run = os.environ.get('DRY_RUN', 'false').lower() == 'true'
    if dry_run:
        print("DRY_RUN is enabled. No bookmarks will be deleted.")

    for bookmark in bookmarks_to_delete:
        bookmark_id = bookmark['id']
        title = bookmark.get('title', 'No Title')
        created = bookmark.get('created', 'Unknown date')
        
        if dry_run:
            print(f"[DRY RUN] Would delete: {title} (ID: {bookmark_id}, Created: {created})")
            continue
            
        print(f"Deleting: {title} (ID: {bookmark_id}, Created: {created})")
        
        delete_url = f"{base_api_url}/bookmarks/{bookmark_id}"
        delete_req = urllib.request.Request(delete_url, method='DELETE')
        delete_req.add_header('Authorization', f'Bearer {readeck_token}')
        
        try:
            with urllib.request.urlopen(delete_req) as response:
                if response.status == 204:
                    print(f"  Successfully deleted.")
                else:
                    print(f"  Failed to delete: HTTP {response.status}")
        except Exception as e:
            print(f"  Error deleting bookmark {bookmark_id}: {e}")

    print("\nDone.")

if __name__ == "__main__":
    main()
