#!/bin/bash

# Установка и настройка Hyprland

source "$(dirname "$0")/common.sh"

setup_hyprland() {
    print_info "Настройка Hyprland..."
    
    local source_dir="../hypr"
    local target_dir="~/.config/hypr"
    
    create_backup "$target_dir"
    
    copy_config "$source_dir" "$target_dir" "monitors.conf"
    
    setup_hyprpaper_config
    
    print_success "Hyprland настроен"
}

setup_hyprpaper_config() {
    print_info "Настройка hyprpaper и monitors.conf..."
    
    local monitors_conf="$HOME/.config/hypr/monitors.conf"
    
    if [ ! -f "$monitors_conf" ]; then
        print_warning "monitors.conf не найден, создаю шаблон"
        cat > "$monitors_conf" << 'EOF'
# Конфигурация мониторов
# Этот файл создается автоматически nwg-displays
# Вы можете редактировать его вручную

# Пример конфигурации:
# monitor=eDP-1,1920x1080@60,0x0,1.0
monitor=,preferred,auto,1.0
EOF
        print_success "Создан шаблон monitors.conf"
    else
        print_success "monitors.conf уже существует, сохраняю текущую конфигурацию"
    fi
    
    print_info "hyprpaper.conf настроен для автоматического применения обоев на все мониторы"
}

main() {
    print_info "🖥️ Настройка Hyprland"
    echo
    
    setup_hyprland
    
    print_success "Настройка Hyprland завершена!"
    echo
    print_info "Важно: monitors.conf НЕ копируется из dotfiles"
    print_info "Используйте nwg-displays для настройки мониторов"
    print_info "Или отредактируйте ~/.config/hypr/monitors.conf вручную"
}

main "$@"
