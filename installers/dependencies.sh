#!/bin/bash

# Установка базовых зависимостей

source "$(dirname "$0")/common.sh"

install_dependencies() {
    print_info "Установка базовых зависимостей..."
    
    local packages=(
        "hyprland"
        "kitty"
        "fish"
        "waybar"
        "wofi"
        "swaync"
        "hyprpaper"
        "hyprlock"
        "fastfetch"
        "polkit-gnome"
        "pulseaudio-alsa"
        "networkmanager"
        "python"
        "python-pip"
        "go"
        "ttf-font-awesome"
        "otf-font-awesome"
        "ttf-jetbrains-mono"
        "ttf-jetbrains-mono-nerd"
        "pkgfile"
        "ttf-dejavu"
        "powerline-fonts"
        "nwg-look"
        "papirus-icon-theme"
        "rsync"
        "xdg-desktop-portal"
        "xdg-desktop-portal-gtk"
        "xdg-desktop-portal-hyprland"
        "fuse2"
    )
    
    local missing_packages=()
    for package in "${packages[@]}"; do
        if ! check_package_installed "$package"; then
            missing_packages+=("$package")
        fi
    done
    
    if [ ${#missing_packages[@]} -gt 0 ]; then
        print_info "Установка недостающих пакетов: ${missing_packages[*]}"
        sudo pacman -S --needed "${missing_packages[@]}"
    else
        print_success "Все основные пакеты уже установлены"
    fi
}

install_yay() {
    if command -v yay &> /dev/null; then
        print_success "yay уже установлен"
        return 0
    fi
    
    print_info "Установка yay для AUR пакетов..."
    sudo pacman -S --needed git base-devel
    
    local temp_dir="/tmp/yay_$(date +%s)"
    git clone https://aur.archlinux.org/yay.git "$temp_dir"
    cd "$temp_dir"
    makepkg -si --noconfirm
    cd - > /dev/null
    rm -rf "$temp_dir"
    
    if command -v yay &> /dev/null; then
        print_success "yay установлен успешно"
        return 0
    else
        print_error "Ошибка установки yay"
        return 1
    fi
}

install_aur_packages() {
    local aur_packages=("pokeget" "hyprpicker" "otf-codenewroman-nerd" "pywal")
    
    for package in "${aur_packages[@]}"; do
        install_package "$package" "true"
    done
}

main() {
    print_info "🔧 Установка базовых зависимостей"
    echo
    
    install_dependencies
    install_yay
    install_aur_packages
    
    print_success "Установка базовых зависимостей завершена!"
}

main "$@"
