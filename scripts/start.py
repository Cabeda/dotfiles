#!/usr/bin/env -S uv run

"""
Required parameters:
@raycast.schemaVersion 1
@raycast.title start
@raycast.mode silent

Optional parameters:
@raycast.icon 🤖

Documentation:
@raycast.author José cabeda
"""

import sys
import subprocess
from typing import List


def open_mac_apps():
    apps: List[tuple[str, List[str]]] = [
        ("ghostty", []),
        ("slack", ["-g"]),
        ("Visual Studio Code", ["-g"]),
        ("Microsoft Outlook", []),
        ("Microsoft Teams", []),
        ("todoist", []),
        ("zen", []),
        ("anytype", []),
    ]

    for app, args in apps:
        subprocess.run(["open", "-a", app] + args)

    print("Good work and have a nice dev day!")

def open_links(links: List[str]):
    for link in links:
        subprocess.run(["open", link])

def aws_login():
    subprocess.run(["aws", "sso", "login"])  # type: ignore

def main():
    platform = sys.argv[1] if len(sys.argv) > 1 else "mac"
    
    if platform == "windows":
        print("Starting windows")
    else:
        open_mac_apps()

        links = [
            "https://gitlab.cicd.man/dashboard/merge_requests?reviewer_username=jose.cabeda",
            "https://jira.collaboration-man.com/secure/RapidBoard.jspa?rapidView=2470&projectKey=MANAI&quickFilter=12286#"
            "https://mail.google.com",
            "https://mail.proton.me"
        ]

        open_links(links)

        aws_login()

if __name__ == "__main__":
    main()
