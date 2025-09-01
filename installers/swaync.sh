#!/bin/bash

# Установка и настройка SwayNC

source "$(dirname "$0")/common.sh"

setup_swaync() {
    print_info "Настройка SwayNC..."
    
    local source_dir="../swaync"
    local target_dir="~/.config/swaync"
    
    create_backup "$target_dir"
    copy_config "$source_dir" "$target_dir"
    
    local swaync_scripts_dir="$HOME/.config/swaync"
    if [ -d "$swaync_scripts_dir" ]; then
        find "$swaync_scripts_dir" -name "*.sh" -type f -exec chmod +x {} \;
        print_success "Установлены права доступа для скриптов SwayNC"
    fi
    
    print_success "SwayNC настроен"
}

main() {
    print_info "🔔 Настройка SwayNC"
    echo
    
    setup_swaync
    
    print_success "Настройка SwayNC завершена!"
}

main "$@"
