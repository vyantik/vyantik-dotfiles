#!/bin/bash

# Установка и настройка FastFetch

source "$(dirname "$0")/common.sh"

setup_fastfetch() {
    print_info "Настройка FastFetch..."
    
    local source_dir="../fastfetch"
    local target_dir="~/.config/fastfetch"
    
    create_backup "$target_dir"
    copy_config "$source_dir" "$target_dir"
    
    print_success "FastFetch настроен"
}

main() {
    print_info "🖼️ Настройка FastFetch"
    echo
    
    setup_fastfetch
    
    print_success "Настройка FastFetch завершена!"
}

main "$@"
