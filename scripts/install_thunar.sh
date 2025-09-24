#!/bin/bash

# Thunar file manager dotfiles installer
# Dependencies: thunar, thunar-volman, tumbler, file-roller

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")/dotfiles"
CONFIG_DIR="$HOME/.config"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging arrays
INSTALLED_PACKAGES=()
FAILED_PACKAGES=()
INSTALLED_CONFIGS=()
FAILED_CONFIGS=()

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

# Function to install packages using pacman/yay
install_package() {
    local package=$1
    log_info "Устанавливаю пакет: $package"
    
    if pacman -Qi "$package" &> /dev/null; then
        log_success "$package уже установлен"
        INSTALLED_PACKAGES+=("$package")
        return 0
    fi
    
    echo -e "${BLUE}[PACMAN]${NC} sudo pacman -S --noconfirm $package"
    if sudo pacman -S --noconfirm "$package"; then
        log_success "Пакет $package установлен"
        INSTALLED_PACKAGES+=("$package")
        return 0
    elif command -v yay &> /dev/null; then
        echo -e "${BLUE}[YAY]${NC} yay -S --noconfirm $package"
        if yay -S --noconfirm "$package"; then
            log_success "Пакет $package установлен через AUR"
            INSTALLED_PACKAGES+=("$package")
            return 0
        else
            log_error "Не удалось установить пакет через AUR: $package"
            FAILED_PACKAGES+=("$package")
            return 1
        fi
    else
        log_error "Не удалось установить пакет: $package"
        FAILED_PACKAGES+=("$package")
        return 1
    fi
}

# Function to copy config files
copy_config() {
    local source_dir=$1
    local dest_dir=$2
    local config_name=$3
    
    log_info "Копирую конфигурацию: $config_name"
    
    # Create backup if config exists
    if [ -d "$dest_dir" ]; then
        log_warning "Создаю резервную копию: $dest_dir.backup.$(date +%Y%m%d_%H%M%S)"
        mv "$dest_dir" "$dest_dir.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Copy new config
    if cp -r "$source_dir" "$dest_dir" 2>/dev/null; then
        log_success "Конфигурация $config_name скопирована"
        INSTALLED_CONFIGS+=("$config_name")
        return 0
    else
        log_error "Не удалось скопировать конфигурацию: $config_name"
        FAILED_CONFIGS+=("$config_name")
        return 1
    fi
}

# Main installation function
install_thunar() {
    log_info "Начинаю установку Thunar file manager и связанных компонентов..."
    
    # Required packages
    local packages=(
        "thunar"
        "thunar-volman"
        "thunar-archive-plugin"
        "thunar-media-tags-plugin"
        "tumbler"
        "file-roller"
        "gvfs"
        "gvfs-mtp"
        "gvfs-afc"
        "gvfs-smb"
        "gvfs-nfs"
    )
    
    # Install packages
    for package in "${packages[@]}"; do
        install_package "$package"
    done
    
    # Create config directory
    mkdir -p "$CONFIG_DIR/Thunar"
    
    # Copy configurations
    copy_config "$DOTFILES_DIR/Thunar" "$CONFIG_DIR/Thunar" "Thunar File Manager"
    
    log_success "Установка Thunar file manager завершена!"
}

# Function to return installation status
get_install_status() {
    echo "THUNAR_INSTALLED_PACKAGES:(${INSTALLED_PACKAGES[*]})"
    echo "THUNAR_FAILED_PACKAGES:(${FAILED_PACKAGES[*]})"
    echo "THUNAR_INSTALLED_CONFIGS:(${INSTALLED_CONFIGS[*]})"
    echo "THUNAR_FAILED_CONFIGS:(${FAILED_CONFIGS[*]})"
}

# Run installation if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_thunar
    get_install_status
fi
