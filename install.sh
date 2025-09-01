#!/bin/bash

# 🎨 Dotfiles Installer - Главный установщик
# Модульная система установки и настройки dotfiles

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
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

print_header() {
    echo -e "${CYAN}$1${NC}"
}

check_arch() {
    if ! grep -q "Arch Linux" /etc/os-release 2>/dev/null; then
        print_warning "Этот скрипт оптимизирован для Arch Linux"
        read -p "Продолжить установку? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

show_main_menu() {
    clear
    echo -e "${MAGENTA}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║                 🎨 Dotfiles Installer                ║"
    echo "║              Модульная система установки             ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo
    echo "Выберите компоненты для установки:"
    echo
    echo "1) 📦 Установить базовые зависимости"
    echo "2) 🖥️  Настроить Hyprland"
    echo "3) 🐚 Настроить Fish shell"
    echo "4) 🎨 Настроить Waybar"
    echo "5) 🔍 Настроить Wofi"
    echo "6) 🔔 Настроить SwayNC"
    echo "7) 💻 Настроить Kitty"
    echo "8) 🖼️  Настроить FastFetch"
    echo "9) 🎯 Установить дополнительные инструменты"
    echo "10) 🎨 Настроить Pywal"
    echo
    echo "a) 🚀 Установить всё"
    echo "b) 🔧 Создать резервные копии"
    echo "c) ✅ Проверить установку"
    echo
    echo "0) ❌ Выход"
    echo
    read -p "Ваш выбор: " choice
}

run_installer() {
    local installer_name="$1"
    local installer_path="./installers/${installer_name}.sh"
    
    if [ -f "$installer_path" ]; then
        print_info "Запуск установщика: $installer_name"
        chmod +x "$installer_path"
        bash "$installer_path"
    else
        print_error "Установщик $installer_name не найден: $installer_path"
        return 1
    fi
}

install_all() {
    print_header "🚀 Установка всех компонентов"
    echo
    
    local installers=(
        "dependencies"
        "hyprland"
        "fish"
        "waybar"
        "wofi"
        "swaync"
        "kitty"
        "fastfetch"
        "tools"
        "pywal"
    )
    
    for installer in "${installers[@]}"; do
        if ! run_installer "$installer"; then
            print_error "Ошибка при установке $installer"
            read -p "Продолжить установку остальных компонентов? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
        echo
    done
    
    print_success "Установка всех компонентов завершена!"
}

main() {
    check_arch
    
    while true; do
        show_main_menu
        
        case $choice in
            1)
                run_installer "dependencies"
                ;;
            2)
                run_installer "hyprland"
                ;;
            3)
                run_installer "fish"
                ;;
            4)
                run_installer "waybar"
                ;;
            5)
                run_installer "wofi"
                ;;
            6)
                run_installer "swaync"
                ;;
            7)
                run_installer "kitty"
                ;;
            8)
                run_installer "fastfetch"
                ;;
            9)
                run_installer "tools"
                ;;
            10)
                run_installer "pywal"
                ;;
            a|A)
                install_all
                ;;
            b|B)
                run_installer "backup"
                ;;
            c|C)
                run_installer "check"
                ;;
            0)
                print_info "Выход из установщика"
                exit 0
                ;;
            *)
                print_error "Неверный выбор. Попробуйте снова."
                ;;
        esac
        
        echo
        read -p "Нажмите Enter для продолжения..."
    done
}

main "$@"