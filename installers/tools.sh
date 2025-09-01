#!/bin/bash

# Установка дополнительных инструментов

source "$(dirname "$0")/common.sh"

setup_chpaper() {
    print_info "Установка и сборка chpaper..."
    
    if ! command -v go &> /dev/null; then
        print_error "Go не установлен, пропускаем установку chpaper"
        return 1
    fi
    
    if [ -f /usr/local/bin/chpaper ]; then
        print_info "chpaper уже установлен в /usr/local/bin"
        local current_version=$(/usr/local/bin/chpaper --version 2>/dev/null || echo "unknown")
        print_success "Текущая версия chpaper: $current_version"
        return 0
    fi
    
    local temp_dir="/tmp/chpaper_build_$(date +%s)"
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    
    print_info "Клонирование репозитория chpaper..."
    if git clone https://github.com/vyantik/chpaper.git .; then
        print_success "Репозиторий успешно клонирован"
    else
        print_error "Ошибка при клонировании репозитория"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    print_info "Сборка chpaper..."
    if go build -o chpaper ./cmd; then
        print_success "chpaper успешно собран"
    else
        print_error "Ошибка при сборке chpaper"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    print_info "Установка chpaper в /usr/local/bin..."
    if sudo cp chpaper /usr/local/bin/; then
        sudo chmod +x /usr/local/bin/chpaper
        print_success "chpaper установлен в /usr/local/bin"
    else
        print_error "Ошибка при установке chpaper"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    if command -v chpaper &> /dev/null; then
        local version=$(chpaper --version 2>/dev/null || echo "unknown")
        print_success "chpaper успешно установлен (версия: $version)"
    else
        print_error "chpaper не найден в PATH"
    fi
    
    cd - > /dev/null
    rm -rf "$temp_dir"
    
    print_success "Установка chpaper завершена"
}

setup_fonts() {
    print_info "Проверка шрифтов..."
    
    local fonts=(
        "JetBrains Mono"
        "Font Awesome"
        "DejaVu"
        "Powerline"
        "CodeNewRoman Nerd Font"
    )
    
    for font in "${fonts[@]}"; do
        if fc-list | grep -q "$font"; then
            print_success "Шрифт $font установлен"
        else
            print_warning "Шрифт $font не найден"
        fi
    done
    
    print_success "Проверка шрифтов завершена"
}

main() {
    print_info "🎯 Установка дополнительных инструментов"
    echo
    
    setup_chpaper
    setup_fonts
    
    print_success "Установка дополнительных инструментов завершена!"
    
    echo
    print_info "Установленные инструменты:"
    echo "- chpaper: $(chpaper --version 2>/dev/null || echo 'не установлен')"
    echo "- hyprpicker: $(hyprpicker --version 2>/dev/null || echo 'не установлен')"
    echo "- pkgfile: $(pkgfile --version 2>/dev/null || echo 'не установлен')"
    echo "- nwg-look: $(nwg-look --version 2>/dev/null || echo 'не установлен')"
}

main "$@"
