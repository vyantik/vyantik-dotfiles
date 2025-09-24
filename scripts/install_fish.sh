#!/bin/bash

# Fish shell dotfiles installer
# Dependencies: fish, fastfetch, bun, go, rust (cargo), spicetify

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
    
    if sudo pacman -S --noconfirm "$package" 2>/dev/null; then
        log_success "Пакет $package установлен"
        INSTALLED_PACKAGES+=("$package")
        return 0
    elif command -v yay &> /dev/null && yay -S --noconfirm "$package" 2>/dev/null; then
        log_success "Пакет $package установлен через AUR"
        INSTALLED_PACKAGES+=("$package")
        return 0
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

# Function to install Bun
install_bun() {
    log_info "Устанавливаю Bun..."
    if [ ! -d "$HOME/.bun" ]; then
        curl -fsSL https://bun.sh/install | bash
        if [ $? -eq 0 ]; then
            log_success "Bun установлен"
            INSTALLED_PACKAGES+=("bun")
        else
            log_error "Не удалось установить Bun"
            FAILED_PACKAGES+=("bun")
        fi
    else
        log_success "Bun уже установлен"
        INSTALLED_PACKAGES+=("bun")
    fi
}

# Function to install Spicetify
install_spicetify() {
    log_info "Устанавливаю Spicetify..."
    if ! command -v spicetify &> /dev/null; then
        curl -fsSL https://raw.githubusercontent.com/spicetify/spicetify-cli/master/install.sh | sh
        if [ $? -eq 0 ]; then
            log_success "Spicetify установлен"
            INSTALLED_PACKAGES+=("spicetify")
        else
            log_error "Не удалось установить Spicetify"
            FAILED_PACKAGES+=("spicetify")
        fi
    else
        log_success "Spicetify уже установлен"
        INSTALLED_PACKAGES+=("spicetify")
    fi
}

# Main installation function
install_fish() {
    log_info "Начинаю установку Fish shell и связанных компонентов..."
    
    # Required packages
    local packages=(
        "fish"
        "fastfetch"
        "go"
        "rust"
        "fd"
        "ripgrep"
    )
    
    # Install packages
    for package in "${packages[@]}"; do
        install_package "$package"
    done
    
    # Install special packages
    install_bun
    install_spicetify
    
    # Create config directory
    mkdir -p "$CONFIG_DIR"
    
    # Copy configurations
    copy_config "$DOTFILES_DIR/fish" "$CONFIG_DIR/fish" "Fish Shell"
    copy_config "$DOTFILES_DIR/fastfetch" "$CONFIG_DIR/fastfetch" "Fastfetch"
    
    # Set fish as default shell
    if command -v fish &> /dev/null; then
        log_info "Устанавливаю Fish как оболочку по умолчанию..."
        if ! grep -q "$(which fish)" /etc/shells; then
            echo "$(which fish)" | sudo tee -a /etc/shells
        fi
        if chsh -s "$(which fish)" 2>/dev/null; then
            log_success "Fish установлен как оболочка по умолчанию"
        else
            log_warning "Не удалось установить Fish как оболочку по умолчанию. Выполните: chsh -s \$(which fish)"
        fi
    fi
    
    log_success "Установка Fish shell завершена!"
}

# Function to return installation status
get_install_status() {
    echo "FISH_INSTALLED_PACKAGES:(${INSTALLED_PACKAGES[*]})"
    echo "FISH_FAILED_PACKAGES:(${FAILED_PACKAGES[*]})"
    echo "FISH_INSTALLED_CONFIGS:(${INSTALLED_CONFIGS[*]})"
    echo "FISH_FAILED_CONFIGS:(${FAILED_CONFIGS[*]})"
}

# Run installation if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_fish
    get_install_status
fi
