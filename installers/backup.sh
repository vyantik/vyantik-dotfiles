#!/bin/bash

# Создание резервных копий конфигураций

source "$(dirname "$0")/common.sh"

create_backups() {
    print_info "Создание резервных копий существующих конфигов..."
    
    local configs=(
        "~/.config/hypr"
        "~/.config/kitty"
        "~/.config/waybar"
        "~/.config/wofi"
        "~/.config/swaync"
        "~/.config/fish"
        "~/.config/fastfetch"
    )
    
    local backup_dir="$HOME/.config_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    local backed_up=false
    
    for config in "${configs[@]}"; do
        local expanded_config=$(eval echo "$config")
        if [ -d "$expanded_config" ]; then
            print_info "Резервная копия: $expanded_config"
            cp -r "$expanded_config" "$backup_dir/"
            backed_up=true
        fi
    done
    
    if [ "$backed_up" = true ]; then
        print_success "Резервные копии сохранены в: $backup_dir"
    else
        print_warning "Нет конфигураций для резервного копирования"
        rmdir "$backup_dir" 2>/dev/null
    fi
}

main() {
    print_info "🔧 Создание резервных копий"
    echo
    
    create_backups
    
    print_success "Создание резервных копий завершено!"
}

main "$@"
