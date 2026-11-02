#!/usr/bin/env bash

set -x
set -uo pipefail

# Ensure the script is run with superuser privileges to access /etc/shadow
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root or with sudo." >&2
    exit 1
fi

echo "[+] Searching for user accounts without passwords..."

# Query /etc/shadow for accounts where the second field (password hash) is empty
NO_PASSWORD_USERS=$(awk -F: '$2 == "" { print $1 }' /etc/shadow)

if [ -n "$NO_PASSWORD_USERS" ]; then
    echo "[!] Warning: The following user accounts have NO password set:"
    echo "$NO_PASSWORD_USERS"
else
    echo "[+] No user accounts with empty passwords were found."
fi