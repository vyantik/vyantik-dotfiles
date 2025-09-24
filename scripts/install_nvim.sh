#!/bin/bash

# Neovim dotfiles installer
# Dependencies: neovim, git, nodejs, npm, python, python-pip, lua

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

# Function to install LSPs and formatters
install_lsp_tools() {
    log_info "Устанавливаю LSP серверы и инструменты форматирования..."
    
    # Node.js based tools
    if command -v npm &> /dev/null; then
        npm install -g typescript-language-server typescript prettier eslint &>/dev/null && log_success "TypeScript LSP установлен" || log_warning "Не удалось установить TypeScript LSP"
        npm install -g lua-language-server &>/dev/null && log_success "Lua LSP установлен" || log_warning "Не удалось установить Lua LSP"
        npm install -g bash-language-server &>/dev/null && log_success "Bash LSP установлен" || log_warning "Не удалось установить Bash LSP"
    fi
    
    # Python tools
    if command -v pip &> /dev/null; then
        pip install --user pylsp black isort &>/dev/null && log_success "Python LSP установлен" || log_warning "Не удалось установить Python LSP"
    fi
    
    # Rust analyzer
    if command -v rustup &> /dev/null; then
        rustup component add rust-analyzer &>/dev/null && log_success "Rust Analyzer установлен" || log_warning "Не удалось установить Rust Analyzer"
    fi
}

# Main installation function
install_nvim() {
    log_info "Начинаю установку Neovim и связанных компонентов..."
    
    # Required packages
    local packages=(
        "neovim"
        "git"
        "nodejs"
        "npm"
        "python"
        "python-pip"
        "lua"
        "tree-sitter"
        "ripgrep"
        "fd"
        "unzip"
        "gcc"
        "make"
    )
    
    # Install packages
    for package in "${packages[@]}"; do
        install_package "$package"
    done
    
    # Create config directory
    mkdir -p "$CONFIG_DIR"
    
    # Copy configurations
    copy_config "$DOTFILES_DIR/nvim" "$CONFIG_DIR/nvim" "Neovim"
    
    # Install LSP tools
    install_lsp_tools
    
    # Setup Lazy.nvim on first run
    log_info "Настраиваю Lazy.nvim плагин-менеджер..."
    if [ -d "$CONFIG_DIR/nvim" ]; then
        log_success "Neovim настроен. Lazy.nvim установится при первом запуске nvim"
    fi
    
    log_success "Установка Neovim завершена!"
}

# Function to return installation status
get_install_status() {
    echo "NVIM_INSTALLED_PACKAGES:(${INSTALLED_PACKAGES[*]})"
    echo "NVIM_FAILED_PACKAGES:(${FAILED_PACKAGES[*]})"
    echo "NVIM_INSTALLED_CONFIGS:(${INSTALLED_CONFIGS[*]})"
    echo "NVIM_FAILED_CONFIGS:(${FAILED_CONFIGS[*]})"
}

# Run installation if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_nvim
    get_install_status
fi
