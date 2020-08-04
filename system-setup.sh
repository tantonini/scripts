#!/bin/bash

REALPATH="$(readlink -e "$0")"
BASEDIR="$(dirname "${REALPATH}")"

WT_HEIGHT=40
WT_WIDTH=120
WT_MENU_HEIGHT=20

do_terminal_menu() {
    while true; do
        FUN=$(whiptail --title "System Configuration" --menu "Terminal setup" \
              "$WT_HEIGHT" "$WT_WIDTH" "$WT_MENU_HEIGHT" \
              --cancel-button Return --ok-button Select -- \
              "1 Dummy" "dummy" \
              3>&1 1>&2 2>&3)

        RET=$?
        if [ $RET -eq 1 ]; then
            return 0
        fi
    done
}

do_utilities_menu() {
    while true; do
        FUN=$(whiptail --title "System Configuration" --menu "Utilities setup" \
              "$WT_HEIGHT" "$WT_WIDTH" "$WT_MENU_HEIGHT" \
              --cancel-button Return --ok-button Select -- \
              "1 Terminal" "- Install and config terminal emulators" \
              3>&1 1>&2 2>&3)

        RET=$?
        if [ $RET -eq 1 ]; then
            return 0
        fi

        case $FUN in
            1\ *) do_terminal_menu ;;
        esac
    done
}

while true; do
    FUN=$(whiptail --title "System Configuration" --menu "Setup Options" \
          "$WT_HEIGHT" "$WT_WIDTH" "$WT_MENU_HEIGHT" \
          --cancel-button Finish --ok-button Select -- \
          "1 Utilities" "- Install and config utilities (terminal, editor, etc...)" \
          3>&1 1>&2 2>&3)

    RET=$?
    if [ $RET -eq 1 ]; then
        exit 0
    fi

    case $FUN in
        1\ *) do_utilities_menu ;;
    esac
done

