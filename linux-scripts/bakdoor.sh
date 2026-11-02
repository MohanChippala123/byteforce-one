
#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "run as root r u too dumb to figure that out?"
  exit 1
fi

set -u

echo "[+] checking reverse shells"
PROCESS_PATTERN='nc[[:space:]].*(-e|--exec)|ncat[[:space:]].*(-e|--exec)|netcat[[:space:]].*(-e|--exec)|socat.*(EXEC|SYSTEM)|/dev/tcp/|bash[[:space:]]+-i'

if ps -eo pid=,args= | grep -E "$PROCESS_PATTERN" | grep -v -E 'grep -E|bakdoor\.sh'; then
  echo "[!] check these processes"
else
  echo "[+] reverse shells GONE"
fi

echo "[+] cleaning the users crontab"
CRON_PATTERN='(/dev/tcp/|nc[[:space:]].*(-e|--exec)|ncat[[:space:]].*(-e|--exec)|netcat[[:space:]].*(-e|--exec)|socat.*(EXEC|SYSTEM)|curl.*\|[[:space:]]*(sh|bash)|wget.*\|[[:space:]]*(sh|bash))'

if command -v crontab >/dev/null 2>&1; then
  while IFS=: read -r user _; do
    matches=$(crontab -u "$user" -l 2>/dev/null | grep -Ein "$CRON_PATTERN" || true)
    if [ -n "$matches" ]; then
      echo "[!] check cron for $user"
      printf '%s\n' "$matches"
    fi
  done < /etc/passwd
fi

for cronfile in /etc/crontab /etc/cron.d/*; do
  [ -f "$cronfile" ] || continue
  matches=$(grep -Ein "$CRON_PATTERN" "$cronfile" 2>/dev/null || true)
  if [ -n "$matches" ]; then
    echo "[!] check $cronfile"
    printf '%s\n' "$matches"
  fi
done

echo "[+] checking ssh keys"
for keyfile in /root/.ssh/authorized_keys /home/*/.ssh/authorized_keys; do
  [ -f "$keyfile" ] || continue
  echo "[!] check $keyfile"
  ls -l "$keyfile"
done

echo "[+] shell stuff"
SHELL_PATTERN='(/dev/tcp/|bash[[:space:]]+-i|nc[[:space:]].*(-e|--exec)|ncat[[:space:]].*(-e|--exec)|netcat[[:space:]].*(-e|--exec)|socat.*(EXEC|SYSTEM)|curl.*\|[[:space:]]*(sh|bash)|wget.*\|[[:space:]]*(sh|bash))'

for config in /root/.bashrc /root/.profile /home/*/.bashrc /home/*/.profile; do
  [ -f "$config" ] || continue
  matches=$(grep -Ein "$SHELL_PATTERN" "$config" 2>/dev/null || true)
  if [ -n "$matches" ]; then
    echo "[!] check $config"
    printf '%s\n' "$matches"
  fi
done

echo "[+]"
EXTRA_ROOTS=$(awk -F: '($3 == 0 && $1 != "root") { print $1 }' /etc/passwd)

if [ -n "$EXTRA_ROOTS" ]; then
  echo "[!] check these users"
  printf '%s\n' "$EXTRA_ROOTS"
else
  echo "[+] no extra root users"
fi

echo "[+] this script is done if u couldn't tell"
