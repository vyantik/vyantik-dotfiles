#!/bin/bash

# Проверка установки

source "$(dirname "$0")/common.sh"

check_configs() {
    print_info "Проверка конфигурационных файлов..."
    
    local configs=(
        "~/.config/hypr/hyprland.conf"
        "~/.config/kitty/kitty.conf"
        "~/.config/waybar/config.jsonc"
        "~/.config/wofi/config"
        "~/.config/fish/config.fish"
        "~/.config/fastfetch/config.jsonc"
        "~/.config/swaync/config.json"
    )
    
    local all_good=true
    for config in "${configs[@]}"; do
        local expanded_config=$(eval echo "$config")
        if [ -f "$expanded_config" ]; then
            print_success "✓ $config"
        else
            print_error "✗ $config - не найден"
            all_good=false
        fi
    done
    
    return $all_good
}

check_programs() {
    print_info "Проверка установленных программ..."
    
    local programs=(
        "go:Go"
        "yay:yay"
        "fish:Fish"
        "chpaper:chpaper"
        "hyprpicker:hyprpicker"
        "wal:pywal"
        "pkgfile:pkgfile"
        "nwg-look:nwg-look"
    )
    
    local all_good=true
    
    for program_info in "${programs[@]}"; do
        IFS=':' read -r cmd name <<< "$program_info"
        
        if command -v "$cmd" &> /dev/null; then
            local version=$($cmd --version 2>/dev/null | head -n1 || echo "установлен")
            print_success "✓ $name: $version"
        else
            print_error "✗ $name не установлен"
            all_good=false
        fi
    done
    
    return $all_good
}

check_fonts() {
    print_info "Проверка шрифтов..."
    
    local fonts=(
        "JetBrains Mono"
        "Font Awesome"
        "DejaVu"
        "Powerline"
        "CodeNewRoman Nerd Font"
    )
    
    local all_good=true
    
    for font in "${fonts[@]}"; do
        if fc-list | grep -q "$font"; then
            print_success "✓ $font: установлен"
        else
            print_error "✗ $font не установлен"
            all_good=false
        fi
    done
    
    if [ -d "/usr/share/icons/Papirus" ] || [ -d "/usr/share/icons/Papirus-Dark" ] || [ -d "/usr/share/icons/Papirus-Light" ]; then
        print_success "✓ papirus-icon-theme: установлен"
    else
        print_error "✗ papirus-icon-theme не установлен"
        all_good=false
    fi
    
    return $all_good
}

show_next_steps() {
    echo
    print_success "🎉 Информация о следующих шагах:"
    echo
    echo "Основные горячие клавиши Hyprland:"
    echo "- Super + Enter: Открыть терминал"
    echo "- Super + R: Открыть меню приложений"
    echo "- Super + Q: Закрыть окно"
    echo "- Super + 1-9: Переключение рабочих пространств"
    echo
    echo "Для изменения обоев:"
    echo "1. Поместите изображение в ~/.config/hypr/wallpaper/"
    echo "2. Используйте chpaper: chpaper --path /path/to/image.png"
    echo "3. Или обновите путь в ~/.config/hypr/hyprpaper.conf"
    echo
    echo "Переменные окружения Go:"
    echo "- GOPATH: ~/go"
    echo "- GOROOT: /usr/lib/go"
    echo "- GOPROXY: https://proxy.golang.org,direct"
    echo
    print_info "Документация: https://wiki.hyprland.org/"
    print_info "chpaper репозиторий: https://github.com/vyantik/chpaper"
}

main() {
    print_info "✅ Проверка установки"
    echo
    
    local configs_ok=true
    local programs_ok=true
    local fonts_ok=true
    
    check_configs || configs_ok=false
    echo
    check_programs || programs_ok=false
    echo
    check_fonts || fonts_ok=false
    
    echo
    if [ "$configs_ok" = true ] && [ "$programs_ok" = true ] && [ "$fonts_ok" = true ]; then
        print_success "Все компоненты установлены и настроены корректно!"
        show_next_steps
    else
        print_error "Некоторые компоненты не установлены или настроены неправильно"
        echo "Запустите соответствующие модули установки для исправления проблем"
    fi
}

main "$@"
