#!/bin/bash

# Pokemon script installer for fastfetch
# Dependencies: pokeget

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

# Function to install pokeget
install_pokeget() {
    log_info "Устанавливаю pokeget для Pokemon в fastfetch..."
    
    if command -v pokeget &> /dev/null; then
        log_success "Pokeget уже установлен"
        INSTALLED_PACKAGES+=("pokeget")
        return 0
    fi
    
    # Try to install via AUR
    if command -v yay &> /dev/null && yay -S --noconfirm pokeget-git 2>/dev/null; then
        log_success "Pokeget установлен через AUR"
        INSTALLED_PACKAGES+=("pokeget")
        return 0
    fi
    
    # Try to install manually from GitHub
    log_info "Устанавливаю pokeget вручную..."
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    echo -e "${BLUE}[GIT]${NC} git clone https://github.com/talwat/pokeget.git"
    if git clone https://github.com/talwat/pokeget.git; then
        cd pokeget
        if cargo build --release 2>/dev/null; then
            sudo cp target/release/pokeget /usr/local/bin/
            sudo chmod +x /usr/local/bin/pokeget
            log_success "Pokeget установлен вручную"
            INSTALLED_PACKAGES+=("pokeget")
            cd - > /dev/null
            rm -rf "$temp_dir"
            return 0
        else
            log_error "Не удалось скомпилировать pokeget"
            FAILED_PACKAGES+=("pokeget")
            cd - > /dev/null
            rm -rf "$temp_dir"
            return 1
        fi
    else
        log_error "Не удалось клонировать репозиторий pokeget"
        FAILED_PACKAGES+=("pokeget")
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
}

# Main installation function
install_pokemon() {
    log_info "Начинаю установку Pokemon для fastfetch..."
    
    # Install Rust if not present (needed for pokeget)
    if ! command -v cargo &> /dev/null; then
        log_info "Устанавливаю Rust для сборки pokeget..."
    echo -e "${BLUE}[PACMAN]${NC} sudo pacman -S --noconfirm rust"
    if sudo pacman -S --noconfirm rust; then
            log_success "Rust установлен"
        else
            log_error "Не удалось установить Rust"
            return 1
        fi
    fi
    
    install_pokeget
    
    log_success "Установка Pokemon для fastfetch завершена!"
}

# Function to return installation status
get_install_status() {
    echo "POKEMON_INSTALLED_PACKAGES:(${INSTALLED_PACKAGES[*]})"
    echo "POKEMON_FAILED_PACKAGES:(${FAILED_PACKAGES[*]})"
}

# Run installation if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_pokemon
    get_install_status
fi
