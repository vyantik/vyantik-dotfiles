#!/bin/bash

# Установка и настройка Kitty

source "$(dirname "$0")/common.sh"

setup_kitty() {
    print_info "Настройка Kitty..."
    
    local source_dir="../kitty"
    local target_dir="~/.config/kitty"
    
    create_backup "$target_dir"
    copy_config "$source_dir" "$target_dir"
    
    local kitty_scripts_dir="$HOME/.config/kitty"
    if [ -d "$kitty_scripts_dir" ]; then
        find "$kitty_scripts_dir" -name "*.py" -type f -exec chmod +x {} \;
        print_success "Установлены права доступа для скриптов Kitty"
    fi
    
    print_success "Kitty настроен"
}

main() {
    print_info "💻 Настройка Kitty"
    echo
    
    setup_kitty
    
    print_success "Настройка Kitty завершена!"
}

main "$@"
