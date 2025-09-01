#!/bin/bash

# Установка и настройка Wofi

source "$(dirname "$0")/common.sh"

setup_wofi() {
    print_info "Настройка Wofi..."
    
    local source_dir="../wofi"
    local target_dir="~/.config/wofi"
    
    create_backup "$target_dir"
    copy_config "$source_dir" "$target_dir"
    
    local wofi_scripts_dir="$HOME/.config/wofi"
    if [ -d "$wofi_scripts_dir" ]; then
        find "$wofi_scripts_dir" -name "*.sh" -type f -exec chmod +x {} \;
        print_success "Установлены права доступа для скриптов Wofi"
    fi
    
    print_success "Wofi настроен"
}

main() {
    print_info "🔍 Настройка Wofi"
    echo
    
    setup_wofi
    
    print_success "Настройка Wofi завершена!"
}

main "$@"
