#!/usr/bin/env bash

set -x
set -uo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root or with sudo." >&2
    exit 1
fi

function get_valid_count() {
    local prompt="$1"
    local count
    while true; do
        read -rp "$prompt" count
        if [[ "$count" =~ ^[1-9][0-9]*$ ]]; then
            echo "$count"
            return 0
        fi
        echo "Please enter a valid positive number." >&2
    done
}

is_valid_name() {
    local name="$1"
    [[ "$name" =~ ^[a-z_][a-z0-9_-]*\$?$ ]]
}

echo "Select an operation:"
echo "1) Add users"
echo "2) Remove users"
echo "3) List system users"
echo "4) List groups for users"
echo "5) Add user to a group"
echo "6) Remove user from a group"
read -rp "Option [1-6]: " operationType

case "$operationType" in
    1)
        count=$(get_valid_count "How many users to add? ")
        for ((i=1; i<=count; i++)); do
            read -rp "Enter username $i: " username

            if ! is_valid_name "$username"; then
                echo "Invalid username format. Skipping..."
                continue
            fi

            if id "$username" &>/dev/null; then
                echo "User '$username' already exists. Skipping..."
            else
                echo "Creating user '$username'..."
                useradd -m "$username" && echo "Successfully created '$username'."
            fi
        done
        ;;

    2)
        count=$(get_valid_count "How many users to remove? ")
        for ((i=1; i<=count; i++)); do
            read -rp "Enter username $i to remove: " username

            if ! id "$username" &>/dev/null; then
                echo "User '$username' does not exist. Skipping..."
                continue
            fi

            echo "Removing user '$username'..."
            userdel -r "$username" && echo "Successfully removed '$username'."
        done
        ;;

    3)
        echo -e "\nStandard System Users (UID >= 1000):"
        awk -F: '$3 >= 1000 && $3 != 65534 {print $1}' /etc/passwd
        ;;

    4)
        count=$(get_valid_count "How many users to check? ")
        for ((i=1; i<=count; i++)); do
            read -rp "Enter username $i: " username

            if id "$username" &>/dev/null; then
                groups "$username"
            else
                echo "User '$username' does not exist."
            fi
        done
        ;;

    5)
        count=$(get_valid_count "How many user assignments? ")
        for ((i=1; i<=count; i++)); do
            read -rp "Enter username $i: " username

            if ! id "$username" &>/dev/null; then
                echo "User '$username' does not exist. Skipping..."
                continue
            fi

            read -rp "Enter group name: " groupname

            if getent group "$groupname" &>/dev/null; then
                usermod -aG "$groupname" "$username" && echo "Added '$username' to group '$groupname'."
            else
                echo "Group '$groupname' does not exist. Skipping..."
            fi
        done
        ;;

    6)
        count=$(get_valid_count "How many user removals from groups? ")
        for ((i=1; i<=count; i++)); do
            read -rp "Enter username $i: " username

            if ! id "$username" &>/dev/null; then
                echo "User '$username' does not exist. Skipping..."
                continue
            fi

            read -rp "Enter group name: " groupname

            if getent group "$groupname" &>/dev/null; then
                gpasswd -d "$username" "$groupname" && echo "Removed '$username' from group '$groupname'."
            else
                echo "Group '$groupname' does not exist. Skipping..."
            fi
        done
        ;;

    *)
        echo "Invalid choice. Please choose a number between 1 and 6."
        exit 1
        ;;
esac