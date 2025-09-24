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
    log_info "Устанавливаю пакет шрифтов: $font_package"
    
    if pacman -Qi "$font_package" &> /dev/null; then
        log_success "$font_package уже установлен"
        INSTALLED_FONTS+=("$font_package")
        return 0
    fi
    
    if sudo pacman -S --noconfirm "$font_package" 2>/dev/null; then
        log_success "Пакет шрифтов $font_package установлен"
        INSTALLED_FONTS+=("$font_package")
        return 0
    elif command -v yay &> /dev/null && yay -S --noconfirm "$font_package" 2>/dev/null; then
        log_success "Пакет шрифтов $font_package установлен через AUR"
        INSTALLED_FONTS+=("$font_package")
        return 0
    else
        log_error "Не удалось установить пакет шрифтов: $font_package"
        FAILED_FONTS+=("$font_package")
        return 1
    fi
}

# Function to download and install Nerd Fonts manually
install_nerd_font() {
    local font_name=$1
    local download_url=$2
    local font_dir="$HOME/.local/share/fonts"
    
    log_info "Устанавливаю Nerd Font: $font_name"
    
    # Create fonts directory
    mkdir -p "$font_dir"
    
    # Check if font is already installed
    if find "$font_dir" -name "*$font_name*" | grep -q .; then
        log_success "Nerd Font $font_name уже установлен"
        INSTALLED_FONTS+=("$font_name")
        return 0
    fi
    
    # Download and install font
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    if curl -fLo "$font_name.zip" "$download_url" 2>/dev/null; then
        if unzip -q "$font_name.zip" -d "$font_name" 2>/dev/null; then
            find "$font_name" -name "*.ttf" -o -name "*.otf" | while read font_file; do
                cp "$font_file" "$font_dir/"
            done
            log_success "Nerd Font $font_name установлен"
            INSTALLED_FONTS+=("$font_name")
            cd - > /dev/null
            rm -rf "$temp_dir"
            return 0
        else
            log_error "Не удалось распаковать Nerd Font: $font_name"
            FAILED_FONTS+=("$font_name")
            cd - > /dev/null
            rm -rf "$temp_dir"
            return 1
        fi
    else
        log_error "Не удалось скачать Nerd Font: $font_name"
        FAILED_FONTS+=("$font_name")
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
}

# Main installation function
install_fonts() {
    log_info "Начинаю установку шрифтов для dotfiles..."
    
    # Install required packages for font management
    sudo pacman -S --noconfirm fontconfig unzip curl 2>/dev/null
    
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
    for font_package in "${font_packages[@]}"; do
        install_font_package "$font_package"
    done
    
    # Try to install JetBrains Mono from AUR
    install_font_package "ttf-jetbrains-mono"
    install_font_package "ttf-jetbrains-mono-nerd"
    
    # If AUR installation failed, install manually
    if [[ " ${FAILED_FONTS[@]} " =~ " ttf-jetbrains-mono-nerd " ]]; then
        log_info "Устанавливаю JetBrains Mono Nerd Font вручную..."
        install_nerd_font "JetBrainsMono" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    fi
    
    # Install other essential Nerd Fonts
    install_nerd_font "FiraCode" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip"
    install_nerd_font "Hack" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip"
    install_nerd_font "SourceCodePro" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/SourceCodePro.zip"
    
    # Icon fonts for waybar and rofi
    install_font_package "ttf-font-awesome"
    install_font_package "otf-font-awesome"
    
    # Install Papirus icon theme (referenced in rofi config)
    install_font_package "papirus-icon-theme"
    
    # Refresh font cache
    log_info "Обновляю кэш шрифтов..."
    fc-cache -fv > /dev/null 2>&1
    log_success "Кэш шрифтов обновлен"
    
    log_success "Установка шрифтов завершена!"
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
