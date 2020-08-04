#!/bin/bash

REALPATH="$(readlink -e "$0")"
BASEDIR="$(dirname "${REALPATH}")"

WT_HEIGHT=40
WT_WIDTH=120
WT_MENU_HEIGHT=20

while true; do
    FUN=$(whiptail --title "System Configuration" --menu "Setup Options" \
          "$WT_HEIGHT" "$WT_WIDTH" "$WT_MENU_HEIGHT" \
          --cancel-button Finish --ok-button Select -- \
          "1 " "Dummy" \
          3>&1 1>&2 2>&3)

    RET=$?
    if [ $RET -eq 1 ]; then
        exit 0
    fi
done

