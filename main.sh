#!/bin/bash

# Dotfiles Installation CLI
# Comprehensive installer for custom dotfiles configuration
# Author: vyantik
# Description: Interactive CLI for installing dotfiles with dependencies and fonts

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Installation status tracking
declare -A INSTALL_STATUS=()
declare -A INSTALL_DETAILS=()

# Available components
COMPONENTS=(
    "base:Базовые утилиты:install_base_utils.sh"
    "fonts:Шрифты и иконки:install_fonts.sh"
    "fish:Fish Shell:install_fish.sh"
    "kitty:Kitty Terminal:install_kitty.sh"
    "hypr:Hyprland WM:install_hypr.sh"
    "nvim:Neovim Editor:install_nvim.sh"
    "thunar:Thunar File Manager:install_thunar.sh"
    "yazi:Yazi File Manager:install_yazi.sh"
    "docker:Docker & Docker Compose:install_docker.sh"
    "pokemon:Pokemon для Fastfetch:install_pokemon.sh"
    "cli:CLI утилиты:install_cli_tools.sh"
)

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    echo -e "\n${BOLD}${CYAN}$1${NC}"
    echo -e "${CYAN}$(printf '=%.0s' {1..60})${NC}\n"
}

# Function to display banner
show_banner() {
    clear
    echo -e "${BOLD}${MAGENTA}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                    DOTFILES INSTALLER                        ║
║                                                              ║
║  Автоматическая установка конфигураций для Arch Linux        ║
║  • Hyprland + Waybar + Rofi + SwayNC                         ║
║  • Fish Shell + Fastfetch + Pokemon                          ║
║  • Kitty Terminal                                            ║
║  • Neovim с плагинами                                        ║
║  • Thunar File Manager                                       ║
║  • Шрифты Nerd Fonts + CLI утилиты                           ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}\n"
}

# Function to show main menu
show_menu() {
    echo -e "${BOLD}${YELLOW}Выберите действие:${NC}\n"
    echo -e "${GREEN}1.${NC} Установить все компоненты"
    echo -e "${GREEN}2.${NC} Выборочная установка"
    echo -e "${GREEN}3.${NC} Показать статус установки"
    echo -e "${GREEN}4.${NC} Показать справку"
    echo -e "${GREEN}5.${NC} Выход"
    echo ""
    read -p "Введите ваш выбор [1-5]: " choice
}

# Function to show component selection menu
show_component_menu() {
    echo -e "${BOLD}${YELLOW}Выберите компоненты для установки:${NC}\n"
    local index=1
    for component in "${COMPONENTS[@]}"; do
        IFS=':' read -r key name script <<< "$component"
        echo -e "${GREEN}$index.${NC} $name"
        ((index++))
    done
    echo -e "${GREEN}0.${NC} Назад в главное меню"
    echo ""
}

# Function to install a component
install_component() {
    local script_name=$1
    local component_name=$2
    local script_path="$SCRIPTS_DIR/$script_name"
    local log_file="/tmp/install_${component_name}.log"
    
    if [ ! -f "$script_path" ]; then
        log_error "Скрипт не найден: $script_path"
        INSTALL_STATUS["$component_name"]="FAILED"
        INSTALL_DETAILS["$component_name"]="Script not found"
        return 1
    fi
    
    log_info "Запускаю установку: $component_name"
    log_info "Скрипт: $script_path"
    log_info "Лог-файл: $log_file"
    
    # Clear previous log
    > "$log_file"
    
    # Add header to log file
    echo "=== Установка компонента: $component_name ===" >> "$log_file"
    echo "Время: $(date)" >> "$log_file"
    echo "Скрипт: $script_path" >> "$log_file"
    echo "=========================================" >> "$log_file"
    
    # Run script with verbose output
    log_info "Выполняю: bash '$script_path'"
    
    # Use unbuffer if available for real-time output, otherwise use stdbuf
    if command -v unbuffer &> /dev/null; then
        unbuffer bash "$script_path" 2>&1 | tee -a "$log_file"
        local exit_code=${PIPESTATUS[0]}
    elif command -v stdbuf &> /dev/null; then
        stdbuf -o0 -e0 bash "$script_path" 2>&1 | tee -a "$log_file"
        local exit_code=${PIPESTATUS[0]}
    else
        bash "$script_path" 2>&1 | tee -a "$log_file"
        local exit_code=${PIPESTATUS[0]}
    fi
    
    # Add footer to log file
    echo "=========================================" >> "$log_file"
    echo "Время завершения: $(date)" >> "$log_file"
    echo "Код выхода: $exit_code" >> "$log_file"
    
    if [ $exit_code -eq 0 ]; then
        INSTALL_STATUS["$component_name"]="SUCCESS"
        
        # Parse installation details from script output
        local details=$(tail -30 "$log_file" | grep -E "(SUCCESS|INSTALLED|установлен)" | tail -5 | tr '\n' '; ')
        INSTALL_DETAILS["$component_name"]="${details:-"Установлено успешно"}"
        
        log_success "Компонент $component_name установлен успешно"
        log_info "Детали установки сохранены в: $log_file"
        return 0
    else
        INSTALL_STATUS["$component_name"]="FAILED"
        
        # Get error details from log
        local error_details=$(tail -20 "$log_file" | grep -E "(ERROR|FAILED|error|failed)" | tail -3 | tr '\n' '; ')
        if [ -z "$error_details" ]; then
            error_details="Код выхода: $exit_code. Проверьте лог: $log_file"
        fi
        INSTALL_DETAILS["$component_name"]="$error_details"
        
        log_error "Не удалось установить компонент: $component_name (код выхода: $exit_code)"
        log_error "Последние ошибки из лога:"
        tail -10 "$log_file" | grep -E "(ERROR|FAILED|error|failed)" | head -5 | while read line; do
            echo -e "${RED}  > ${line}${NC}"
        done
        log_info "Полный лог ошибок доступен в: $log_file"
        return 1
    fi
}

# Function to install all components
install_all() {
    log_header "УСТАНОВКА ВСЕХ КОМПОНЕНТОВ"
    
    local total=${#COMPONENTS[@]}
    local current=1
    
    for component in "${COMPONENTS[@]}"; do
        IFS=':' read -r key name script <<< "$component"
        
        echo -e "${CYAN}[$current/$total]${NC} Устанавливаю: $name"
        install_component "$script" "$key"
        
        ((current++))
        echo ""
    done
    
    show_installation_report
}

# Function to install selected components
install_selected() {
    while true; do
        clear
        show_banner
        show_component_menu
        
        read -p "Введите номера компонентов через пробел (например: 1 3 5): " selections
        
        if [[ "$selections" == "0" ]]; then
            return
        fi
        
        # Validate input
        local valid=true
        for selection in $selections; do
            if ! [[ "$selection" =~ ^([1-9]|1[01])$ ]]; then
                log_error "Неверный выбор: $selection"
                valid=false
                break
            fi
        done
        
        if [ "$valid" = false ]; then
            read -p "Нажмите Enter для продолжения..."
            continue
        fi
        
        log_header "ВЫБОРОЧНАЯ УСТАНОВКА"
        
        for selection in $selections; do
            local index=$((selection - 1))
            if [ $index -ge 0 ] && [ $index -lt ${#COMPONENTS[@]} ]; then
                IFS=':' read -r key name script <<< "${COMPONENTS[$index]}"
                echo -e "${CYAN}Устанавливаю:${NC} $name"
                install_component "$script" "$key"
                echo ""
            fi
        done
        
        show_installation_report
        break
    done
}

# Function to show installation status
show_status() {
    log_header "СТАТУС УСТАНОВКИ КОМПОНЕНТОВ"
    
    # Check if array is empty or unset
    if [ ${#INSTALL_STATUS[@]} -eq 0 ] 2>/dev/null; then
        log_warning "Установка еще не выполнялась"
        return
    fi
    
    # Create status table
    printf "${BOLD}%-20s %-15s %-30s${NC}\n" "КОМПОНЕНТ" "СТАТУС" "ДЕТАЛИ"
    printf "%-20s %-15s %-30s\n" "$(printf '─%.0s' {1..20})" "$(printf '─%.0s' {1..15})" "$(printf '─%.0s' {1..30})"
    
    for component in "${COMPONENTS[@]}"; do
        IFS=':' read -r key name script <<< "$component"
        
        local status="${INSTALL_STATUS[$key]:-"NOT_INSTALLED"}"
        local status_color=""
        local status_symbol=""
        
        case "$status" in
            "SUCCESS")
                status_color="${GREEN}"
                status_symbol="✓ УСПЕШНО"
                ;;
            "FAILED")
                status_color="${RED}"
                status_symbol="✗ ОШИБКА"
                ;;
            *)
                status_color="${YELLOW}"
                status_symbol="○ НЕ УСТАНОВЛЕН"
                ;;
        esac
        
        printf "%-20s ${status_color}%-15s${NC} %-30s\n" "$name" "$status_symbol" "${INSTALL_DETAILS[$key]:-"N/A"}"
    done
    
    echo ""
}

# Function to show detailed installation report
show_installation_report() {
    log_header "ОТЧЕТ ОБ УСТАНОВКЕ"
    
    local success_count=0
    local failed_count=0
    local total_count=0
    
    # Check if array exists and get count
    if [ ${#INSTALL_STATUS[@]} -gt 0 ] 2>/dev/null; then
        total_count=${#INSTALL_STATUS[@]}
    fi
    
    # Count successes and failures
    if [ ${#INSTALL_STATUS[@]} -gt 0 ] 2>/dev/null; then
        for status in "${INSTALL_STATUS[@]}"; do
            case "$status" in
                "SUCCESS") ((success_count++)) ;;
                "FAILED") ((failed_count++)) ;;
            esac
        done
    fi
    
    # Summary
    echo -e "${BOLD}Сводка установки:${NC}"
    echo -e "${GREEN}✓ Успешно установлено: $success_count${NC}"
    echo -e "${RED}✗ Ошибки установки: $failed_count${NC}"
    echo -e "${CYAN}○ Всего компонентов: $total_count${NC}"
    echo ""
    
    # Detailed status table
    show_status
    
    # Recommendations
    if [ $failed_count -gt 0 ]; then
        echo -e "${YELLOW}Рекомендации:${NC}"
        echo "• Проверьте логи в /tmp/install_*.log для диагностики ошибок"
        echo "• Убедитесь, что у вас есть права sudo"
        echo "• Проверьте подключение к интернету"
        echo "• Попробуйте переустановить проблемные компоненты"
        echo ""
    fi
    
    if [ $success_count -gt 0 ]; then
        echo -e "${GREEN}Что дальше:${NC}"
        echo "• Перезапустите терминал для применения изменений Fish shell"
        echo "• Запустите Hyprland: выберите его в менеджере дисплея"
        echo "• Откройте Neovim - плагины установятся автоматически"
        echo "• Настройте мониторы в ~/.config/hypr/monitors.conf"
        echo ""
    fi
    
    read -p "Нажмите Enter для продолжения..."
}

# Function to show help
show_help() {
    log_header "СПРАВКА ПО ИСПОЛЬЗОВАНИЮ"
    
    echo -e "${BOLD}Описание компонентов:${NC}\n"
    
    echo -e "${YELLOW}1. Базовые утилиты${NC}"
    echo "   • fd, ripgrep - быстрый поиск файлов и текста"
    echo "   • fzf - интерактивный фильтр"
    echo "   • bat, exa - улучшенные cat и ls"
    echo "   • zoxide - умная навигация по папкам"
    echo "   • git, curl, wget, htop и другие"
    echo ""
    
    echo -e "${YELLOW}2. Шрифты и иконки${NC}"
    echo "   • Nerd Fonts (JetBrains Mono, Fira Code, Hack)"
    echo "   • Font Awesome для иконок"
    echo "   • Papirus icon theme"
    echo ""
    
    echo -e "${YELLOW}3. Fish Shell${NC}"
    echo "   • Современная командная оболочка"
    echo "   • Fastfetch для системной информации"
    echo "   • Интеграция с Bun, Go, Rust, Spicetify"
    echo ""
    
    echo -e "${YELLOW}4. Kitty Terminal${NC}"
    echo "   • GPU-ускоренный терминал"
    echo "   • Поддержка pywal для цветовых схем"
    echo "   • Прозрачность и кастомизация"
    echo ""
    
    echo -e "${YELLOW}5. Hyprland WM${NC}"
    echo "   • Wayland композитор"
    echo "   • Waybar (панель), Rofi (лаунчер)"
    echo "   • SwayNC (уведомления), Wlogout (меню выхода)"
    echo "   • Поддержка скриншотов и буфера обмена"
    echo ""
    
    echo -e "${YELLOW}6. Neovim Editor${NC}"
    echo "   • Конфигурация на базе AstroNvim"
    echo "   • LSP серверы для разных языков"
    echo "   • Автоматическая установка плагинов"
    echo ""
    
    echo -e "${YELLOW}7. Thunar File Manager${NC}"
    echo "   • Файловый менеджер для XFCE"
    echo "   • Поддержка архивов и медиа-тегов"
    echo "   • Интеграция с GVFS"
    echo ""
    
    echo -e "${YELLOW}8. Yazi File Manager${NC}"
    echo "   • Современный файловый менеджер для терминала"
    echo "   • Быстрая навигация с Vim-подобными клавишами"
    echo "   • Превью файлов (изображения, видео, текст)"
    echo "   • Интеграция с fd, ripgrep, zoxide, fzf"
    echo ""
    
    echo -e "${YELLOW}9. Docker & Docker Compose${NC}"
    echo "   • Платформа контейнеризации приложений"
    echo "   • Docker Compose для многоконтейнерных приложений"
    echo "   • Автоматическая настройка сервиса и групп"
    echo "   • Готовность к использованию без sudo"
    echo ""
    
    echo -e "${YELLOW}10. Pokemon для Fastfetch${NC}"
    echo "   • Pokeget утилита для отображения Pokemon"
    echo "   • Интеграция с fastfetch для красивого вывода"
    echo "   • Поддержка различных Pokemon"
    echo ""
    
    echo -e "${YELLOW}11. CLI утилиты${NC}"
    echo "   • chpaper - утилита для смены обоев"
    echo "   • json-parse - парсер JSON файлов"
    echo "   • cursor - быстрый запуск Cursor IDE"
    echo "   • Автоматическое скачивание Cursor AppImage"
    echo "   • Установка в /usr/local/bin для глобального доступа"
    echo ""
    
    echo -e "${BOLD}Системные требования:${NC}"
    echo "• Arch Linux или производная"
    echo "• Права sudo"
    echo "• Подключение к интернету"
    echo "• Git для клонирования репозиториев"
    echo "• yay AUR helper (устанавливается автоматически)"
    echo ""
    
    echo -e "${BOLD}Важные файлы:${NC}"
    echo "• Конфигурации: ./dotfiles/"
    echo "• Скрипты установки: ./scripts/"
    echo "• Логи установки: /tmp/install_*.log"
    echo ""
    
    read -p "Нажмите Enter для возврата в главное меню..."
}

# Function to install yay AUR helper globally
install_yay_helper() {
    if command -v yay &> /dev/null; then
        log_success "yay AUR helper уже установлен"
        return 0
    fi
    
    log_info "Устанавливаю yay AUR helper глобально..."
    
    # Install base development tools
    echo -e "${BLUE}[PACMAN]${NC} sudo pacman -S --needed --noconfirm base-devel git"
    if ! sudo pacman -S --needed --noconfirm base-devel git; then
        log_error "Не удалось установить base-devel"
        return 1
    fi
    
    # Clone yay repository
    local temp_dir=$(mktemp -d)
    local current_dir=$(pwd)
    
    echo -e "${BLUE}[GIT]${NC} git clone https://aur.archlinux.org/yay.git $temp_dir/yay"
    if ! git clone https://aur.archlinux.org/yay.git "$temp_dir/yay"; then
        log_error "Не удалось клонировать yay репозиторий"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Build and install yay
    cd "$temp_dir/yay"
    echo -e "${BLUE}[MAKEPKG]${NC} makepkg -si --noconfirm"
    if makepkg -si --noconfirm; then
        log_success "yay AUR helper установлен глобально"
        cd "$current_dir"
        rm -rf "$temp_dir"
        return 0
    else
        log_error "Не удалось собрать yay"
        cd "$current_dir"
        rm -rf "$temp_dir"
        return 1
    fi
}

# Function to check system requirements
check_requirements() {
    log_info "Проверяю системные требования..."
    
    # Check if running on Arch Linux
    if [ ! -f /etc/arch-release ]; then
        log_warning "Этот установщик предназначен для Arch Linux"
        read -p "Продолжить? [y/N]: " continue_install
        if [[ ! "$continue_install" =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi
    
    # Check for sudo
    if ! sudo -n true 2>/dev/null; then
        log_info "Для установки требуются права sudo"
        sudo -v || {
            log_error "Не удалось получить права sudo"
            exit 1
        }
    fi
    
    # Check for internet connection
    if ! ping -c 1 google.com &> /dev/null; then
        log_warning "Проблемы с подключением к интернету"
        log_warning "Некоторые компоненты могут не установиться"
    fi
    
    # Check for git
    if ! command -v git &> /dev/null; then
        log_info "Устанавливаю Git..."
        echo -e "${BLUE}[PACMAN]${NC} sudo pacman -S --noconfirm git"
        sudo pacman -S --noconfirm git || {
            log_error "Не удалось установить Git"
            exit 1
        }
    fi
    
    log_success "Базовые системные требования проверены"
}

# Main function
main() {
    # Trap to cleanup on exit
    trap 'echo -e "\n${YELLOW}Установка прервана${NC}"; exit 1' INT TERM
    
    # Check requirements
    check_requirements
    
    # Install yay AUR helper globally before anything else
    log_header "ПОДГОТОВКА СИСТЕМЫ"
    install_yay_helper || {
        log_warning "Не удалось установить yay, некоторые AUR пакеты могут быть недоступны"
    }
    
    while true; do
        show_banner
        show_menu
        
        case $choice in
            1)
                install_all
                ;;
            2)
                install_selected
                ;;
            3)
                clear
                show_banner
                show_status
                read -p "Нажмите Enter для продолжения..."
                ;;
            4)
                clear
                show_banner
                show_help
                ;;
            5)
                log_info "Выход из установщика"
                exit 0
                ;;
            *)
                log_error "Неверный выбор. Пожалуйста, выберите 1-5."
                read -p "Нажмите Enter для продолжения..."
                ;;
        esac
    done
}

# Run main function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
