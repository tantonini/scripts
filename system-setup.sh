#!/bin/bash

REALPATH="$(readlink -e "$0")"
BASEDIR="$(dirname "${REALPATH}")"

WT_HEIGHT=40
WT_WIDTH=120
WT_MENU_HEIGHT=20

do_alacritty_install() {
    ALACRITTY_VERSION=v0.5.0
    if (whiptail --title "System Configuration" --yesno "Do you want to install Alacritty now?" \
        "$WT_HEIGHT" "$WT_WIDTH"); then
        if command -v alacritty > /dev/null; then
            whiptail --title "System Configuration" --msgbox "Alacritty is already installed on the system" \
            "$WT_HEIGHT" "$WT_WIDTH"

            return 0
        fi

        echo ""
        echo "Install dependencies to build Alacritty"
        sudo apt-get install -y curl git cmake pkg-config libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev python3 gzip
        echo "Alacritty dependencies installed"

        echo ""
        echo "Install Rust compiler and cargo"
        if ! command -v cargo rustup > /dev/null; then
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
            # shellcheck source=/dev/null
            source "$HOME"/.cargo/env

            echo "Rust compiler and cargo installed"
        else
            echo "Rust compiler and cargo already installed"
        fi

        mkdir -p "$HOME"/sources
        cd "$HOME"/sources || (echo "Error: cannot cd $HOME/sources"; exit 1)

        echo ""
        echo "Get Alacritty sources"
        if ! [[ -d alacritty ]]; then
            git clone https://github.com/alacritty/alacritty.git
        fi

        cd alacritty || (echo "Error: cannot cd $HOME/sources"; exit 1)
        git checkout "$ALACRITTY_VERSION"

        echo ""
        echo "Build and install Alacritty"
        cargo build --release

        echo ""
        echo "Add desktop entries"
        sudo cp target/release/alacritty /usr/local/bin
        sudo cp extra/logo/alacritty-term.svg /usr/share/pixmaps/Alacritty.svg
        sudo desktop-file-install extra/linux/Alacritty.desktop
        sudo update-desktop-database

        echo ""
        echo "Add manual page"
        sudo mkdir -p /usr/local/share/man/man1
        gzip -c extra/alacritty.man | sudo tee /usr/local/share/man/man1/alacritty.1.gz > /dev/null

        echo ""
        echo "Alacritty $ALACRITTY_VERSION installed"

        cd "$BASEDIR" || exit 1

        whiptail --title "System Configuration" --msgbox "Alacritty $ALACRITTY_VERSION installed" \
        "$WT_HEIGHT" "$WT_WIDTH"

        return 0
    else
        return 1
    fi
}

do_alacritty_menu() {
    while true; do
        FUN=$(whiptail --title "System Configuration" --menu "Alacritty setup" \
              "$WT_HEIGHT" "$WT_WIDTH" "$WT_MENU_HEIGHT" \
              --cancel-button Return --ok-button Select -- \
              "1 Install" "- Install Alacritty" \
              3>&1 1>&2 2>&3)

        RET=$?
        if [ $RET -eq 1 ]; then
            return 0
        fi

        case $FUN in
            1\ *) do_alacritty_install ;;
        esac
    done
}

do_dotfiles_git_bare() {
    if ! command -v dotfiles; then
        echo "alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'" >> "$HOME"/.bash_aliases
    fi

    if [ -d "$HOME"/.dotfiles ]; then
        whiptail --title "System Configuration" --msgbox "Dotfiles repository is already configured" \
        "$WT_HEIGHT" "$WT_WIDTH"

        return 0
    fi

    if ! command -v git > /dev/null; then
        echo ""
        echo "Install git"
        sudo apt-get install -y git
    fi

    git clone --bare https://github.com/tantonini/dotfiles.git "$HOME"/.dotfiles
    whiptail --title "System Configuration" --msgbox "Dotfiles repository configured" \
    "$WT_HEIGHT" "$WT_WIDTH"
}

do_dotfiles_menu() {
    while true; do
        FUN=$(whiptail --title "System Configuration" --menu "Dotfiles setup" \
              "$WT_HEIGHT" "$WT_WIDTH" "$WT_MENU_HEIGHT" \
              --cancel-button Return --ok-button Select -- \
              "1 Git bare repo" "- Use git bare repository for managing dotfiles" \
              3>&1 1>&2 2>&3)

        RET=$?
        if [ $RET -eq 1 ]; then
            return 0
        fi

        case $FUN in
            1\ *) do_dotfiles_git_bare ;;
        esac
    done
}

do_editors_menu() {
    while true; do
        FUN=$(whiptail --title "System Configuration" --menu "Editors setup" \
              "$WT_HEIGHT" "$WT_WIDTH" "$WT_MENU_HEIGHT" \
              --cancel-button Return --ok-button Select -- \
              "1 nvim" "- Install and configure neovim" \
              3>&1 1>&2 2>&3)

        RET=$?
        if [ $RET -eq 1 ]; then
            return 0
        fi

        case $FUN in
            1\ *) do_nvim_menu ;;
        esac
    done
}

do_gui_menu() {
    while true; do
        FUN=$(whiptail --title "System Configuration" --menu "Graphical user interface configuration" \
              "$WT_HEIGHT" "$WT_WIDTH" "$WT_MENU_HEIGHT" \
              --cancel-button Return --ok-button Select -- \
              "1 WM" "- Window manager setup" \
              3>&1 1>&2 2>&3)

        RET=$?
        if [ $RET -eq 1 ]; then
            return 0
        fi

        case $FUN in
            1\ *) do_wm_menu ;;
        esac
    done
}

do_i3_install() {
    if command -v i3 > /dev/null; then
        whiptail --title "System Configuration" --msgbox "i3-gaps is already installed on the system" \
        "$WT_HEIGHT" "$WT_WIDTH"

        return 0
    fi

    sudo add-apt-repository -y ppa:kgilmer/speed-ricer
    sudo apt update
    sudo apt-get install -y i3-gaps

    whiptail --title "System Configuration" --msgbox "i3-gaps installed on the system" \
    "$WT_HEIGHT" "$WT_WIDTH"
}

do_i3_menu() {
    while true; do
        FUN=$(whiptail --title "System Configuration" --menu "i3 wm setup" \
              "$WT_HEIGHT" "$WT_WIDTH" "$WT_MENU_HEIGHT" \
              --cancel-button Return --ok-button Select -- \
              "1 Install" "- Install i3-gaps" \
              3>&1 1>&2 2>&3)

        RET=$?
        if [ $RET -eq 1 ]; then
            return 0
        fi

        case $FUN in
            1\ *) do_i3_install ;;
        esac
    done
}

do_nvim_install() {
    if command -v nvim > /dev/null; then
        whiptail --title "System Configuration" --msgbox "Nvim is already installed on the system" \
        "$WT_HEIGHT" "$WT_WIDTH"

        return 0
    fi

    sudo apt-get install -y curl
    mkdir -p "$HOME"/.local/bin
    cd "$HOME"/.local/bin || return
    curl -LO https://github.com/neovim/neovim/releases/download/stable/nvim.appimage
    chmod u+x nvim.appimage
    mv nvim.appimage nvim

    whiptail --title "System Configuration" --msgbox "Nvim installed on the system" \
    "$WT_HEIGHT" "$WT_WIDTH"
}

do_nvim_menu() {
    while true; do
        FUN=$(whiptail --title "System Configuration" --menu "Neovim menu" \
              "$WT_HEIGHT" "$WT_WIDTH" "$WT_MENU_HEIGHT" \
              --cancel-button Return --ok-button Select -- \
              "1 Install nvim" "- Install neovim editor" \
              3>&1 1>&2 2>&3)

        RET=$?
        if [ $RET -eq 1 ]; then
            return 0
        fi

        case $FUN in
            1\ *) do_nvim_install ;;
        esac
    done
}

do_terminal_menu() {
    while true; do
        FUN=$(whiptail --title "System Configuration" --menu "Terminal setup" \
              "$WT_HEIGHT" "$WT_WIDTH" "$WT_MENU_HEIGHT" \
              --cancel-button Return --ok-button Select -- \
              "1 Alacritty" "- Alacritty configuration" \
              3>&1 1>&2 2>&3)

        RET=$?
        if [ $RET -eq 1 ]; then
            return 0
        fi

        case $FUN in
            1\ *) do_alacritty_menu ;;
        esac
    done
}

do_utilities_menu() {
    while true; do
        FUN=$(whiptail --title "System Configuration" --menu "Utilities setup" \
              "$WT_HEIGHT" "$WT_WIDTH" "$WT_MENU_HEIGHT" \
              --cancel-button Return --ok-button Select -- \
              "1 Editors" "- Install and config editors" \
              "2 Terminal" "- Install and config terminal emulators" \
              3>&1 1>&2 2>&3)

        RET=$?
        if [ $RET -eq 1 ]; then
            return 0
        fi

        case $FUN in
            1\ *) do_editors_menu ;;
            2\ *) do_terminal_menu ;;
        esac
    done
}

do_wm_menu() {
    while true; do
        FUN=$(whiptail --title "System Configuration" --menu "Window manager setup" \
              "$WT_HEIGHT" "$WT_WIDTH" "$WT_MENU_HEIGHT" \
              --cancel-button Return --ok-button Select -- \
              "1 i3" "- i3 window manager setup" \
              3>&1 1>&2 2>&3)

        RET=$?
        if [ $RET -eq 1 ]; then
            return 0
        fi

        case $FUN in
            1\ *) do_i3_menu ;;
        esac
    done
}

while true; do
    FUN=$(whiptail --title "System Configuration" --menu "Setup Options" \
          "$WT_HEIGHT" "$WT_WIDTH" "$WT_MENU_HEIGHT" \
          --cancel-button Finish --ok-button Select -- \
          "1 Dotfiles" "- Configure dotfiles management" \
          "2 GUI" "- Configure graphical user interface" \
          "3 Utilities" "- Install and config utilities (terminal, editor, etc...)" \
          3>&1 1>&2 2>&3)

    RET=$?
    if [ $RET -eq 1 ]; then
        exit 0
    fi

    case $FUN in
        1\ *) do_dotfiles_menu ;;
        2\ *) do_gui_menu ;;
        3\ *) do_utilities_menu ;;
    esac
done

