#!/bin/bash

echo " this checks for services running on weird directories"

if ! command -v systemctl >/dev/null 2>&1; then
    echo "[!] systemctl is NOT found btw"
    exit 1
fi

while IFS= read -r svc; do
    [ -n "$svc" ] || continue

    cmd=$(systemctl show "$svc" -p ExecStart --no-pager 2>/dev/null)

    if printf '%s\n' "$cmd" | grep -qE '(/tmp/|/var/tmp/|/dev/shm/|/home/)'; then
        echo "--> FLAG: $svc isnt in place ig"
        echo "    $cmd"
    fi
done < <(systemctl list-unit-files --type=service --no-legend --no-pager | awk 'NF {print $1}')

echo ""
echo "services that run at boot basically startup apps"
systemctl list-unit-files --type=service --state=enabled --no-legend --no-pager | awk 'NF {print $1}'

echo ""
echo "stuff running rn"
systemctl list-units --type=service --state=running --no-legend --no-pager | awk 'NF {print $1}'

echo ""
echo "stuff that crashed"
systemctl list-units --type=service --state=failed --no-legend --no-pager

echo ""
echo "[+] done if u couldn't tell"