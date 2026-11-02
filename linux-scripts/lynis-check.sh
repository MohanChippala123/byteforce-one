#!/usr/bin/env bash
set -x
set -uo pipefail
#so the idea for this script is to kinda run some audits of the system mainly lynis
if [ "$EUID" -ne 0 ]; then
  echo "run as root"
  exit 1
fi
#gets our system ready
sudo apt install lynis
sudo apt update && upgrade
#runs a lynis full system audit in quick mode (doesn't ask for all the annoying enter keypresses) while also filtering out all the suggestions and only having warnings and critical stuff.
#and puts it in a txt file and no colors is so it doesnt break the txt file.
sudo lynis audit system -Q --warnings-only --no-colors > ~/lynis_warnings.txt
echo "the audit results are at ~/lynis_warnings.txt"