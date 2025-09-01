#!/bin/bash

# Общие функции для всех установщиков

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

copy_config() {
    local source_dir="$1"
    local target_dir="$2"
    local exclude_files="$3"
    
    if [ ! -d "$source_dir" ]; then
        print_error "Исходная директория не найдена: $source_dir"
        return 1
    fi
    
    local expanded_target=$(eval echo "$target_dir")
    
    if [ -d "$expanded_target" ]; then
        print_warning "Удаление существующей конфигурации: $expanded_target"
        rm -rf "$expanded_target"
    fi
    
    print_info "Копирование конфигурации: $source_dir -> $expanded_target"
    
    if [ -n "$exclude_files" ]; then
        mkdir -p "$expanded_target"
        rsync -av --exclude="$exclude_files" "$source_dir/" "$expanded_target/"
    else
        cp -r "$source_dir" "$expanded_target"
    fi
    
    print_success "Конфигурация скопирована: $expanded_target"
}

create_backup() {
    local config_path="$1"
    local expanded_config=$(eval echo "$config_path")
    
    if [ -d "$expanded_config" ]; then
        local backup_dir="$HOME/.config_backup_$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$backup_dir"
        
        print_info "Создание резервной копии: $expanded_config"
        cp -r "$expanded_config" "$backup_dir/"
        print_success "Резервная копия создана: $backup_dir/$(basename $expanded_config)"
    fi
}

check_package_installed() {
    local package="$1"
    if pacman -Q "$package" &>/dev/null || yay -Q "$package" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

install_package() {
    local package="$1"
    local use_aur="$2"
    
    if check_package_installed "$package"; then
        print_success "Пакет $package уже установлен"
        return 0
    fi
    
    print_info "Установка пакета: $package"
    
    if [ "$use_aur" = "true" ]; then
        if ! command -v yay &> /dev/null; then
            print_error "yay не установлен, не могу установить AUR пакет"
            return 1
        fi
        yay -S --noconfirm "$package"
    else
        sudo pacman -S --needed "$package"
    fi
    
    if check_package_installed "$package"; then
        print_success "Пакет $package успешно установлен"
        return 0
    else
        print_error "Ошибка установки пакета $package"
        return 1
    fi
}
