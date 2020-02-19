#!/usr/bin/env python3

"""
Use this script for GNS3 console activation with TMUX.

Requires python 3.6 or higher.
"""

import argparse
import shlex
import subprocess
import sys
import time


import libtmux


def main():
    """
    Do stuff, open consoles and thangs.
    :return:
    """

    # Parse in our arguments
    argparser = argparse.ArgumentParser()
    argparser.add_argument("--name", type=str, help="What name are we giving this window?")
    argparser.add_argument("--host", type=str, help="What is the host we're connecting to?")
    argparser.add_argument("--port", type=str, help="What is the port we're connecting to?")
    args = argparser.parse_args()

    print(f"Establishing Telnet session to {args.name} at {args.host}:{args.port}")

    # Connect to local tmux instance
    t = libtmux.Server()

    # See if a GNS3 session is open, create one if not.
    gns3_session = t.find_where({"session_name": "GNS3"})
    if gns3_session is None:
        print("\t* Creating tmux session 'GNS3'...")
        gns3_session = t.new_session(
            session_name="GNS3",
            start_directory="~",
            window_name=args.name,
            window_command=f"telnet {args.host} {args.port}",
        )
        print(f"\t* Created tmux session 'GNS3': {gns3_session}")
    else:
        print(f"\t* Found existing tmux session 'GNS3': {gns3_session}")

    # See if a window for this name is already open, create one if not.
    window = gns3_session.find_where({"window_name": args.name})
    if window is None:
        print(f"\t* Creating new tmux window '{args.name}' in GNS3 session...")
        window = gns3_session.new_window(window_name=args.name, window_shell=f"telnet {args.host} {args.port}")
        print(f"\t* Created new tmux window '{args.name}: {window}")
    else:
        print(f"\t* Found existing tmux window named '{args.name}': {window}")

    # Setup our attach command
    attach_command = "tmux attach-session -t GNS3"

    # Check if existing tmux session attach has happened:
    try:
        tmux_attach_pid = subprocess.check_output(["pgrep", "-f", attach_command]).decode().strip()
    except subprocess.SubprocessError:
        tmux_attach_pid = None
    if tmux_attach_pid is None:
        # Launch a gnome-terminal session for this tmux session
        gnome_terminal = subprocess.Popen(shlex.split(f"gnome-terminal -t GNS3 -- {attach_command}"))
        print(f"\t* Attached to tmux GNS3 session in PID {gnome_terminal.pid}, please check your terminal tabs/windows")
    else:
        print(
            (
                f"\t* Found existing instance of '{attach_command}' already running in PID {tmux_attach_pid}, please"
                f" check your terminal tabs/windows"
            )
        )

    print("Sleeping 5 seconds and exiting this script...")
    time.sleep(5)
    sys.exit()


if __name__ == "__main__":
    main()
