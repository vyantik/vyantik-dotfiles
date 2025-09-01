#!/bin/bash

# Установка и настройка Waybar

source "$(dirname "$0")/common.sh"

setup_waybar() {
    print_info "Настройка Waybar..."
    
    local source_dir="../waybar"
    local target_dir="~/.config/waybar"
    
    create_backup "$target_dir"
    copy_config "$source_dir" "$target_dir"
    
    local waybar_scripts_dir="$HOME/.config/waybar/scripts"
    if [ -d "$waybar_scripts_dir" ]; then
        find "$waybar_scripts_dir" -name "*.sh" -type f -exec chmod +x {} \;
        print_success "Установлены права доступа для скриптов Waybar"
    fi
    
    print_success "Waybar настроен"
}

main() {
    print_info "🎨 Настройка Waybar"
    echo
    
    setup_waybar
    
    print_success "Настройка Waybar завершена!"
}

main "$@"
