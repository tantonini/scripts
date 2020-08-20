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

do_applets_install() {
    if ! command -v volumeicon; then
        echo ""
        echo "Install volumeicon applet"
        sudo apt-get install -y volumeicon-alsa
    fi

    whiptail --title "System Configuration" --msgbox "System tray applets installed" \
    "$WT_HEIGHT" "$WT_WIDTH"
}

do_disk_tools_menu() {
    while true; do
        FUN=$(whiptail --title "System Configuration" --menu "Disk tools menu" \
              "$WT_HEIGHT" "$WT_WIDTH" "$WT_MENU_HEIGHT" \
              --cancel-button Return --ok-button Select -- \
              "1 udiskie" "- Install udiskie" \
              3>&1 1>&2 2>&3)

        RET=$?
        if [ $RET -eq 1 ]; then
            return 0
        fi

        case $FUN in
            1\ *) do_udiskie_install ;;
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

do_i3_config_dependencies_menu() {
    while true; do
        FUN=$(whiptail --title "System Configuration" --menu "i3 wm config dependencies setup" \
              "$WT_HEIGHT" "$WT_WIDTH" "$WT_MENU_HEIGHT" \
              --cancel-button Return --ok-button Select -- \
              "1 Install applets" "- Install system tray applets" \
              "2 Install polkit" "- Install gnome policy kit" \
              3>&1 1>&2 2>&3)

        RET=$?
        if [ $RET -eq 1 ]; then
            return 0
        fi

        case $FUN in
            1\ *) do_applets_install ;;
            2\ *) do_polkit_gnome_install ;;
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
              "2 Config dependencies menu" "- Install polkit, etc..." \
              3>&1 1>&2 2>&3)

        RET=$?
        if [ $RET -eq 1 ]; then
            return 0
        fi

        case $FUN in
            1\ *) do_i3_install ;;
            2\ *) do_i3_config_dependencies_menu ;;
        esac
    done
}

do_multimedia_menu() {
    while true; do
        FUN=$(whiptail --title "System Configuration" --menu "Multimedia setup" \
              "$WT_HEIGHT" "$WT_WIDTH" "$WT_MENU_HEIGHT" \
              --cancel-button Return --ok-button Select -- \
              "1 Spotify" "- Install Spotify" \
              3>&1 1>&2 2>&3)

        RET=$?
        if [ $RET -eq 1 ]; then
            return 0
        fi

        case $FUN in
            1\ *) do_spotify_install ;;
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
              "2 Install vim plug" "- Install neovim plugin manager" \
              "3 Optimize nvim" "- Install neovim checkhealth + vimrc required packages" \
              3>&1 1>&2 2>&3)

        RET=$?
        if [ $RET -eq 1 ]; then
            return 0
        fi

        case $FUN in
            1\ *) do_nvim_install ;;
            2\ *) do_nvim_vim_plug_install ;;
            3\ *) do_nvim_optimize ;;
        esac
    done
}

do_nvim_optimize() {
    if ! [ "$(command -v xclip)" ]; then
        sudo apt-get install -y xclip
    fi

    if ! [ "$(command -v pip3)" ]; then
        sudo apt-get install -y python3-pip
    fi

    if ! [ "$(python3 -m pip show pynvim)" ]; then
        python3 -m pip install --user --upgrade pynvim
    fi

    if ! [ "$(command -v node)" ]; then
        sudo apt-get install -y nodejs
    fi

    if ! [ "$(command -v npm)" ]; then
        sudo apt-get install -y npm
    fi

    if ! [ "$(command -v neovim-node-host)" ]; then
        sudo npm install -g neovim
    fi

    if ! [ "$(command -v ruby)" ]; then
        sudo apt-get install -y ruby-dev
    fi

    if ! [ "$(command -v gem)" ]; then
        sudo apt-get install -y gem
    fi

    if ! gem list --local | grep -q neovim; then
        sudo gem install neovim
    fi

    if ! [ "$(command -v ccls)" ]; then
        sudo apt-get install -y ccls
    fi

    if ! [ "$(command -v bash-language-server)" ]; then
        sudo npm i -g bash-language-server
    fi

    whiptail --title "System configuration" --msgbox "Nvim optimized" \
    "$WT_HEIGHT" "$WT_WIDTH"
}

do_nvim_vim_plug_install() {
    if [ -f "$HOME"/.local/share/nvim/site/autoload/plug.vim ]; then
        whiptail --title "System Configuration" --msgbox "Vim plug is already installed on the system" \
        "$WT_HEIGHT" "$WT_WIDTH"

        return 0
    fi

    sudo apt-get install -y curl
    sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

    whiptail --title "System Configuration" --msgbox "Vim plug installed on the system" \
    "$WT_HEIGHT" "$WT_WIDTH"
}

do_polkit_gnome_install() {
    if [ -f /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 ]; then
        whiptail --title "System Configuration" --msgbox "Polkit gnome authentication agent already installed" \
        "$WT_HEIGHT" "$WT_WIDTH"

        return 0
    fi

    sudo apt-get install -y policykit-1-gnome

    if [ $RET -eq 0 ];then
        whiptail --title "System Configuration" --msgbox "Polkit gnome authentication agent installed" \
        "$WT_HEIGHT" "$WT_WIDTH"
    else
        whiptail --title "System Configuration" --msgbox "ERROR: Cannot install polkit gnome authentication agent" \
        "$WT_HEIGHT" "$WT_WIDTH"
    fi
}

do_spotify_install() {
    if command -v spotify; then
        whiptail --title "System Configuration" --msgbox "Spotify is already installed" \
        "$WT_HEIGHT" "$WT_WIDTH"

        return 0
    fi

    if ! command -v curl; then
        sudo apt-get install -y curl
    fi

    if ! grep "deb http://repository.spotify.com stable non-free" /etc/apt/sources.list.d/spotify.list > /dev/null; then
        curl -sS https://download.spotify.com/debian/pubkey.gpg | sudo apt-key add -
        echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
    fi

    sudo apt-get update
    sudo apt-get install -y spotify-client

    if [ $RET -eq 0 ]; then
        whiptail --title "System Configuration" --msgbox "Spotify installed" \
        "$WT_HEIGHT" "$WT_WIDTH"
    fi
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

do_udiskie_install() {
    if command -v udiskie; then
        whiptail --title "System Configuration" --msgbox "Udiskie is already installed on the system" \
        "$WT_HEIGHT" "$WT_WIDTH"

        return 0
    fi

    echo "Install udiskie"
    sudo apt-get install -y udiskie
    whiptail --title "System Configuration" --msgbox "Udiskie installed" \
    "$WT_HEIGHT" "$WT_WIDTH"
}

do_utilities_menu() {
    while true; do
        FUN=$(whiptail --title "System Configuration" --menu "Utilities setup" \
              "$WT_HEIGHT" "$WT_WIDTH" "$WT_MENU_HEIGHT" \
              --cancel-button Return --ok-button Select -- \
              "1 Disk tools" "- Install and config disk tools" \
              "2 Editors" "- Install and config editors" \
              "3 Terminal" "- Install and config terminal emulators" \
              3>&1 1>&2 2>&3)

        RET=$?
        if [ $RET -eq 1 ]; then
            return 0
        fi

        case $FUN in
            1\ *) do_disk_tools_menu ;;
            2\ *) do_editors_menu ;;
            3\ *) do_terminal_menu ;;
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
          "3 Multimedia" "- Install and config multimedia" \
          "4 Utilities" "- Install and config utilities (terminal, editor, etc...)" \
          3>&1 1>&2 2>&3)

    RET=$?
    if [ $RET -eq 1 ]; then
        exit 0
    fi

    case $FUN in
        1\ *) do_dotfiles_menu ;;
        2\ *) do_gui_menu ;;
        3\ *) do_multimedia_menu ;;
        4\ *) do_utilities_menu ;;
    esac
done

