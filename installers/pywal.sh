#!/bin/bash

# Настройка pywal

source "$(dirname "$0")/common.sh"

setup_pywal() {
    print_info "Настройка pywal для генерации цветов..."
    
    if ! command -v wal &> /dev/null; then
        print_error "pywal не установлен"
        return 1
    fi
    
    mkdir -p ~/.cache/wal
    
    if [ ! -f ~/.cache/wal/colors.json ]; then
        print_info "Создание базовой цветовой схемы..."
        echo '{"colors": {"color0": "#1a1a1a", "color7": "#ffffff", "color8": "#333333", "color9": "#ff6b6b"}, "special": {"background": "#1a1a1a", "foreground": "#ffffff"}}' > ~/.cache/wal/colors.json
    fi
    
    if [ -f ~/.config/hypr/set_wal_colors.py ]; then
        print_info "Запуск скрипта генерации цветов..."
        python3 ~/.config/hypr/set_wal_colors.py
    fi
    
    if [ -f ~/.config/kitty/set_wal_colors.py ]; then
        print_info "Обновление цветов Kitty..."
        python3 ~/.config/kitty/set_wal_colors.py
    fi
    
    print_success "Pywal настроен"
}

main() {
    print_info "🎨 Настройка Pywal"
    echo
    
    setup_pywal
    
    print_success "Настройка Pywal завершена!"
    
    echo
    print_info "Использование pywal:"
    echo "- wal -i /path/to/image.png: генерация цветовой схемы из изображения"
    echo "- wal -l: использование светлой темы"
    echo "- wal -s: генерация схемы для конкретного терминала"
}

main "$@"
