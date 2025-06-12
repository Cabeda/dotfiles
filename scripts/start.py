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


def main():
    platform = sys.argv[1] if len(sys.argv) > 1 else "mac"
    
    if platform == "windows":
        print("Starting windows")
    else:
        open_mac_apps()


if __name__ == "__main__":
    main()
