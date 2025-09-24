#!/bin/bash

# Base utilities installer
# Essential command-line utilities for development and system management

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging arrays
INSTALLED_PACKAGES=()
FAILED_PACKAGES=()

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
            log_error "Не удалось установить пакет: $package"
            FAILED_PACKAGES+=("$package")
            return 1
        fi
    else
        log_error "Не удалось установить пакет: $package"
        FAILED_PACKAGES+=("$package")
        return 1
    fi
}

# Function to test installed utilities
test_utilities() {
    log_info "Тестирую установленные утилиты..."
    
    local utilities=(
        "fd:быстрый поиск файлов"
        "rg:поиск по содержимому файлов"
        "fzf:интерактивный фильтр"
        "bat:улучшенный cat с подсветкой"
        "exa:современная замена ls"
        "zoxide:умная навигация по папкам"
        "git:система контроля версий"
        "curl:HTTP клиент"
        "wget:загрузчик файлов"
        "unzip:распаковка архивов"
        "tree:отображение структуры папок"
    )
    
    for util_desc in "${utilities[@]}"; do
        IFS=':' read -r util desc <<< "$util_desc"
        if command -v "$util" &> /dev/null; then
            log_success "$util: $desc - доступен"
        else
            log_warning "$util: $desc - не найден"
        fi
    done
}

# Function to show usage examples
show_usage_examples() {
    log_info "Примеры использования установленных утилит:"
    echo ""
    
    if command -v fd &> /dev/null; then
        echo -e "${YELLOW}fd${NC} - быстрый поиск файлов:"
        echo "  fd config                # найти файлы с 'config' в имени"
        echo "  fd -e js                 # найти все .js файлы"
        echo "  fd -t f config           # найти только файлы (не папки)"
        echo ""
    fi
    
    if command -v rg &> /dev/null; then
        echo -e "${YELLOW}ripgrep (rg)${NC} - поиск по содержимому:"
        echo "  rg 'function'            # найти 'function' во всех файлах"
        echo "  rg 'TODO' --type js      # найти TODO в JS файлах"
        echo "  rg -i 'error' src/       # поиск без учета регистра в папке src"
        echo ""
    fi
    
    if command -v fzf &> /dev/null; then
        echo -e "${YELLOW}fzf${NC} - интерактивный фильтр:"
        echo "  ls | fzf                 # интерактивный выбор из списка"
        echo "  fd | fzf                 # выбор файла из результатов fd"
        echo "  history | fzf            # поиск в истории команд"
        echo ""
    fi
    
    if command -v bat &> /dev/null; then
        echo -e "${YELLOW}bat${NC} - улучшенный cat:"
        echo "  bat file.js              # просмотр с подсветкой синтаксиса"
        echo "  bat -n file.py           # с номерами строк"
        echo ""
    fi
    
    if command -v exa &> /dev/null; then
        echo -e "${YELLOW}exa${NC} - современный ls:"
        echo "  exa -la                  # список с деталями"
        echo "  exa --tree               # в виде дерева"
        echo "  exa --git                # с Git статусом"
        echo ""
    fi
    
    if command -v zoxide &> /dev/null; then
        echo -e "${YELLOW}zoxide${NC} - умная навигация:"
        echo "  z projects               # быстрый переход в папку projects"
        echo "  zi                       # интерактивный выбор"
        echo ""
    fi
}

# Main installation function
install_base_utils() {
    log_info "Начинаю установку базовых утилит..."
    
    # Essential command-line utilities
    local packages=(
        "fd"                    # Fast file finder
        "ripgrep"              # Fast text search
        "fzf"                  # Fuzzy finder
        "bat"                  # Better cat with syntax highlighting
        "exa"                  # Modern ls replacement
        "zoxide"               # Smart cd command
        "git"                  # Version control
        "curl"                 # HTTP client
        "wget"                 # File downloader
        "unzip"                # Archive extraction
        "tree"                 # Directory tree display
        "htop"                 # Process monitor
        "neofetch"             # System info
        "jq"                   # JSON processor
        "vim"                  # Text editor
        "nano"                 # Simple text editor
        "rsync"                # File synchronization
        "diff"                 # File comparison
        "grep"                 # Text search
        "sed"                  # Stream editor
        "awk"                  # Text processing
    )
    
    # Install packages
    for package in "${packages[@]}"; do
        install_package "$package"
    done
    
    # Test installations
    test_utilities
    
    # Show usage examples
    show_usage_examples
    
    # Setup shell integrations
    if command -v zoxide &> /dev/null; then
        log_info "Настраиваю интеграцию zoxide с fish shell..."
        if command -v fish &> /dev/null; then
            echo "zoxide init fish | source" >> "$HOME/.config/fish/config.fish" 2>/dev/null || true
            log_success "Zoxide интегрирован с Fish shell"
        fi
    fi
    
    log_success "Установка базовых утилит завершена!"
}

# Function to return installation status
get_install_status() {
    echo "BASE_INSTALLED_PACKAGES:(${INSTALLED_PACKAGES[*]})"
    echo "BASE_FAILED_PACKAGES:(${FAILED_PACKAGES[*]})"
}

# Run installation if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_base_utils
    get_install_status
fi
