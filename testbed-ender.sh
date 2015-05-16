#!/usr/bin/env bash

# Kill the Nat Daemon
sudo killall natd

# Delete all firewall rules
sudo ipfw -q flush

# Disable IP Forwarding
sudo sysctl -w net.inet.ip.forwarding=0
