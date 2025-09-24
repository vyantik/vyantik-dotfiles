#!/bin/bash

# Fonts installer for dotfiles
# Installs required fonts for the dotfiles configuration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging arrays
INSTALLED_FONTS=()
FAILED_FONTS=()

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

# Function to install fonts using pacman/yay
install_font_package() {
    local font_package=$1
    log_info "Проверяю пакет шрифтов: $font_package"
    
    # Check if already installed
    if pacman -Qi "$font_package" &> /dev/null; then
        log_success "Пакет $font_package уже установлен"
        INSTALLED_FONTS+=("$font_package")
        echo "INSTALLED: $font_package (already installed)"
        return 0
    fi
    
    log_info "Устанавливаю пакет шрифтов: $font_package"
    
    # Try pacman first
    echo -e "${BLUE}[PACMAN]${NC} Выполняю: sudo pacman -S --noconfirm $font_package"
    if sudo pacman -S --noconfirm "$font_package" 2>&1; then
        log_success "Пакет шрифтов $font_package установлен через pacman"
        INSTALLED_FONTS+=("$font_package")
        echo "INSTALLED: $font_package (via pacman)"
        return 0
    else
        local pacman_exit_code=$?
        log_warning "Pacman не смог установить $font_package (код выхода: $pacman_exit_code)"
        
        # Try yay if available
        if command -v yay &> /dev/null; then
            log_info "Пробую установить через AUR (yay)..."
            echo -e "${BLUE}[YAY]${NC} Выполняю: yay -S --noconfirm $font_package"
            
            if yay -S --noconfirm "$font_package" 2>&1; then
                log_success "Пакет шрифтов $font_package установлен через AUR"
                INSTALLED_FONTS+=("$font_package")
                echo "INSTALLED: $font_package (via AUR)"
                return 0
            else
                local yay_exit_code=$?
                log_error "Не удалось установить $font_package через AUR (код выхода: $yay_exit_code)"
                FAILED_FONTS+=("$font_package")
                echo "FAILED: $font_package (pacman: $pacman_exit_code, yay: $yay_exit_code)"
                return 1
            fi
        else
            log_error "yay не найден, не могу установить из AUR"
            log_error "Не удалось установить пакет шрифтов: $font_package"
            FAILED_FONTS+=("$font_package")
            echo "FAILED: $font_package (no yay available)"
            return 1
        fi
    fi
}

# Function to download and install Nerd Fonts manually
install_nerd_font() {
    local font_name=$1
    local download_url=$2
    local font_dir="$HOME/.local/share/fonts"
    
    log_info "Проверяю Nerd Font: $font_name"
    
    # Create fonts directory
    log_info "Создаю директорию шрифтов: $font_dir"
    mkdir -p "$font_dir"
    
    # Check if font is already installed
    local existing_fonts=$(find "$font_dir" -name "*$font_name*" 2>/dev/null | wc -l)
    if [ "$existing_fonts" -gt 0 ]; then
        log_success "Nerd Font $font_name уже установлен ($existing_fonts файлов)"
        INSTALLED_FONTS+=("$font_name")
        echo "INSTALLED: $font_name (already installed, $existing_fonts files)"
        return 0
    fi
    
    log_info "Скачиваю и устанавливаю Nerd Font: $font_name"
    log_info "URL: $download_url"
    
    # Download and install font
    local temp_dir=$(mktemp -d)
    local original_dir=$(pwd)
    
    log_info "Временная директория: $temp_dir"
    cd "$temp_dir"
    
    log_info "Скачиваю архив шрифта..."
    echo -e "${BLUE}[CURL]${NC} Выполняю: curl -fLo '$font_name.zip' '$download_url'"
    
    if curl -fL --progress-bar -o "$font_name.zip" "$download_url"; then
        log_success "Архив скачан успешно ($(du -h "$font_name.zip" | cut -f1))"
        
        log_info "Распаковываю архив..."
        if unzip -q "$font_name.zip" -d "$font_name"; then
            log_success "Архив распакован успешно"
            
            # Count and install font files
            local font_files=$(find "$font_name" -name "*.ttf" -o -name "*.otf" 2>/dev/null)
            local font_count=$(echo "$font_files" | grep -v '^$' | wc -l)
            
            if [ "$font_count" -gt 0 ]; then
                log_info "Найдено $font_count файлов шрифтов, копирую в $font_dir"
                
                echo "$font_files" | while read font_file; do
                    if [ -n "$font_file" ]; then
                        local basename=$(basename "$font_file")
                        log_info "Копирую: $basename"
                        cp "$font_file" "$font_dir/"
                    fi
                done
                
                log_success "Nerd Font $font_name установлен ($font_count файлов)"
                INSTALLED_FONTS+=("$font_name")
                echo "INSTALLED: $font_name ($font_count files)"
                
                cd "$original_dir"
                rm -rf "$temp_dir"
                return 0
            else
                log_error "В архиве не найдено файлов шрифтов (.ttf/.otf)"
                FAILED_FONTS+=("$font_name")
                echo "FAILED: $font_name (no font files found)"
                cd "$original_dir"
                rm -rf "$temp_dir"
                return 1
            fi
        else
            local unzip_exit_code=$?
            log_error "Не удалось распаковать архив: $font_name (код выхода: $unzip_exit_code)"
            FAILED_FONTS+=("$font_name")
            echo "FAILED: $font_name (unzip failed: $unzip_exit_code)"
            cd "$original_dir"
            rm -rf "$temp_dir"
            return 1
        fi
    else
        local curl_exit_code=$?
        log_error "Не удалось скачать Nerd Font: $font_name (код выхода: $curl_exit_code)"
        log_error "URL: $download_url"
        FAILED_FONTS+=("$font_name")
        echo "FAILED: $font_name (curl failed: $curl_exit_code)"
        cd "$original_dir"
        rm -rf "$temp_dir"
        return 1
    fi
}

# Main installation function
install_fonts() {
    log_info "Начинаю установку шрифтов для dotfiles..."
    echo "========================================="
    
    # Install required packages for font management
    log_info "Устанавливаю необходимые пакеты: fontconfig, unzip, curl"
    echo -e "${BLUE}[PACMAN]${NC} Выполняю: sudo pacman -S --noconfirm fontconfig unzip curl"
    if sudo pacman -S --noconfirm fontconfig unzip curl; then
        log_success "Зависимости установлены"
    else
        log_warning "Некоторые зависимости могут отсутствовать"
    fi
    
    echo ""
    log_info "Устанавливаю системные шрифты..."
    echo "========================================="
    
    # System font packages
    local font_packages=(
        "ttf-dejavu"
        "ttf-liberation" 
        "noto-fonts"
        "noto-fonts-emoji"
        "noto-fonts-cjk"
        "ttf-roboto"
        "ttf-roboto-mono"
        "adobe-source-code-pro-fonts"
    )
    
    # Install system font packages
    local total_packages=${#font_packages[@]}
    local current_package=1
    
    for font_package in "${font_packages[@]}"; do
        echo ""
        log_info "[$current_package/$total_packages] Обрабатываю: $font_package"
        install_font_package "$font_package"
        ((current_package++))
    done
    
    echo ""
    log_info "Устанавливаю JetBrains Mono..."
    echo "========================================="
    
    # Try to install JetBrains Mono from packages
    install_font_package "ttf-jetbrains-mono"
    install_font_package "ttf-jetbrains-mono-nerd"
    
    # If AUR installation failed, install manually
    if [[ " ${FAILED_FONTS[@]} " =~ " ttf-jetbrains-mono-nerd " ]]; then
        log_info "Пакет ttf-jetbrains-mono-nerd недоступен, устанавливаю вручную..."
        install_nerd_font "JetBrainsMono" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    fi
    
    echo ""
    log_info "Устанавливаю дополнительные Nerd Fonts..."
    echo "========================================="
    
    # Install other essential Nerd Fonts
    local nerd_fonts=(
        "FiraCode:https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip"
        "Hack:https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip"
        "SourceCodePro:https://github.com/ryanoasis/nerd-fonts/releases/latest/download/SourceCodePro.zip"
    )
    
    for nerd_font_entry in "${nerd_fonts[@]}"; do
        IFS=':' read -r font_name font_url <<< "$nerd_font_entry"
        echo ""
        install_nerd_font "$font_name" "$font_url"
    done
    
    echo ""
    log_info "Устанавливаю иконочные шрифты..."
    echo "========================================="
    
    # Icon fonts for waybar and rofi
    install_font_package "ttf-font-awesome"
    install_font_package "otf-font-awesome"
    
    echo ""
    log_info "Устанавливаю темы иконок..."
    install_font_package "papirus-icon-theme"
    
    echo ""
    log_info "Финализация установки..."
    echo "========================================="
    
    # Refresh font cache
    log_info "Обновляю кэш шрифтов..."
    echo -e "${BLUE}[FC-CACHE]${NC} Выполняю: fc-cache -fv"
    if fc-cache -fv; then
        log_success "Кэш шрифтов обновлен"
    else
        log_warning "Возможны проблемы с обновлением кэша шрифтов"
    fi
    
    echo ""
    log_success "Установка шрифтов завершена!"
    echo ""
    
    # Summary
    local installed_count=${#INSTALLED_FONTS[@]}
    local failed_count=${#FAILED_FONTS[@]}
    
    echo "========================================="
    echo -e "${GREEN}Установлено шрифтов: $installed_count${NC}"
    echo -e "${RED}Ошибок установки: $failed_count${NC}"
    
    if [ $installed_count -gt 0 ]; then
        echo ""
        echo -e "${GREEN}Успешно установленные шрифты:${NC}"
        for font in "${INSTALLED_FONTS[@]}"; do
            echo -e "  ✓ $font"
        done
    fi
    
    if [ $failed_count -gt 0 ]; then
        echo ""
        echo -e "${RED}Неустановленные шрифты:${NC}"
        for font in "${FAILED_FONTS[@]}"; do
            echo -e "  ✗ $font"
        done
    fi
    echo "========================================="
}

# Function to return installation status
get_install_status() {
    echo "FONTS_INSTALLED:(${INSTALLED_FONTS[*]})"
    echo "FONTS_FAILED:(${FAILED_FONTS[*]})"
}

# Run installation if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_fonts
    get_install_status
fi
