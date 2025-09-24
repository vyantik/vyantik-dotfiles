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
    log_info "Проверяю пакет: $package"
    
    # Check if already installed
    if pacman -Qi "$package" &> /dev/null; then
        log_success "Пакет $package уже установлен"
        INSTALLED_PACKAGES+=("$package")
        echo "INSTALLED: $package (already installed)"
        return 0
    fi
    
    log_info "Устанавливаю пакет: $package"
    
    # Try pacman first
    echo -e "${BLUE}[PACMAN]${NC} Выполняю: sudo pacman -S --noconfirm $package"
    if sudo pacman -S --noconfirm "$package" 2>&1; then
        log_success "Пакет $package установлен через pacman"
        INSTALLED_PACKAGES+=("$package")
        echo "INSTALLED: $package (via pacman)"
        return 0
    else
        local pacman_exit_code=$?
        log_warning "Pacman не смог установить $package (код выхода: $pacman_exit_code)"
        
        # Try yay if available
        if command -v yay &> /dev/null; then
            log_info "Пробую установить через AUR (yay)..."
            echo -e "${BLUE}[YAY]${NC} Выполняю: yay -S --noconfirm $package"
            
            if yay -S --noconfirm "$package" 2>&1; then
                log_success "Пакет $package установлен через AUR"
                INSTALLED_PACKAGES+=("$package")
                echo "INSTALLED: $package (via AUR)"
                return 0
            else
                local yay_exit_code=$?
                log_error "Не удалось установить $package через AUR (код выхода: $yay_exit_code)"
                FAILED_PACKAGES+=("$package")
                echo "FAILED: $package (pacman: $pacman_exit_code, yay: $yay_exit_code)"
                return 1
            fi
        else
            log_error "yay не найден, не могу установить из AUR"
            log_error "Не удалось установить пакет: $package"
            FAILED_PACKAGES+=("$package")
            echo "FAILED: $package (no yay available)"
            return 1
        fi
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
    log_info "Проверяю установку Bun..."
    
    # Check if Bun is already installed
    if [ -d "$HOME/.bun" ] && [ -f "$HOME/.bun/bin/bun" ]; then
        log_success "Bun уже установлен"
        local bun_version=$("$HOME/.bun/bin/bun" --version 2>/dev/null || echo "unknown")
        log_info "Версия Bun: $bun_version"
        INSTALLED_PACKAGES+=("bun")
        echo "INSTALLED: bun (already installed, version: $bun_version)"
        return 0
    fi
    
    log_info "Устанавливаю Bun JavaScript runtime..."
    echo -e "${BLUE}[CURL]${NC} Выполняю: curl -fsSL https://bun.sh/install | bash"
    
    if curl -fsSL https://bun.sh/install | bash; then
        local bun_exit_code=$?
        if [ $bun_exit_code -eq 0 ] && [ -f "$HOME/.bun/bin/bun" ]; then
            local bun_version=$("$HOME/.bun/bin/bun" --version 2>/dev/null || echo "unknown")
            log_success "Bun установлен успешно (версия: $bun_version)"
            log_info "Путь к Bun: $HOME/.bun/bin/bun"
            INSTALLED_PACKAGES+=("bun")
            echo "INSTALLED: bun (version: $bun_version)"
            return 0
        else
            log_error "Установка Bun завершилась, но исполняемый файл не найден"
            FAILED_PACKAGES+=("bun")
            echo "FAILED: bun (installation completed but binary not found)"
            return 1
        fi
    else
        local curl_exit_code=$?
        log_error "Не удалось установить Bun (код выхода: $curl_exit_code)"
        log_error "URL: https://bun.sh/install"
        FAILED_PACKAGES+=("bun")
        echo "FAILED: bun (curl failed: $curl_exit_code)"
        return 1
    fi
}

# Function to install Spicetify
install_spicetify() {
    log_info "Проверяю установку Spicetify..."
    
    # Check if Spicetify is already installed
    if command -v spicetify &> /dev/null; then
        local spicetify_version=$(spicetify -v 2>/dev/null | head -1 || echo "unknown")
        log_success "Spicetify уже установлен"
        log_info "Версия: $spicetify_version"
        INSTALLED_PACKAGES+=("spicetify")
        echo "INSTALLED: spicetify (already installed, version: $spicetify_version)"
        return 0
    fi
    
    log_info "Устанавливаю Spicetify CLI для кастомизации Spotify..."
    echo -e "${BLUE}[CURL]${NC} Выполняю: curl -fsSL https://raw.githubusercontent.com/spicetify/spicetify-cli/master/install.sh | sh"
    
    if curl -fsSL https://raw.githubusercontent.com/spicetify/spicetify-cli/master/install.sh | sh; then
        # Refresh PATH and check if spicetify is now available
        export PATH="$HOME/.spicetify:$PATH"
        
        if command -v spicetify &> /dev/null; then
            local spicetify_version=$(spicetify -v 2>/dev/null | head -1 || echo "unknown")
            log_success "Spicetify установлен успешно"
            log_info "Версия: $spicetify_version"
            log_info "Путь: $(which spicetify)"
            INSTALLED_PACKAGES+=("spicetify")
            echo "INSTALLED: spicetify (version: $spicetify_version)"
            return 0
        else
            log_error "Установка Spicetify завершилась, но команда недоступна"
            log_warning "Возможно, требуется перезапуск терминала"
            FAILED_PACKAGES+=("spicetify")
            echo "FAILED: spicetify (installation completed but command not found)"
            return 1
        fi
    else
        local curl_exit_code=$?
        log_error "Не удалось установить Spicetify (код выхода: $curl_exit_code)"
        log_error "URL: https://raw.githubusercontent.com/spicetify/spicetify-cli/master/install.sh"
        FAILED_PACKAGES+=("spicetify")
        echo "FAILED: spicetify (curl failed: $curl_exit_code)"
        return 1
    fi
}

# Main installation function
install_fish() {
    log_info "Начинаю установку Fish shell и связанных компонентов..."
    echo "========================================="
    
    # Required packages
    local packages=(
        "fish"
        "fastfetch"
        "go"
        "rust"
        "fd"
        "ripgrep"
    )
    
    echo ""
    log_info "Устанавливаю основные пакеты..."
    echo "========================================="
    
    # Install packages
    local total_packages=${#packages[@]}
    local current_package=1
    
    for package in "${packages[@]}"; do
        echo ""
        log_info "[$current_package/$total_packages] Обрабатываю: $package"
        install_package "$package"
        ((current_package++))
    done
    
    echo ""
    log_info "Устанавливаю дополнительные компоненты..."
    echo "========================================="
    
    # Install special packages
    echo ""
    install_bun
    echo ""
    install_spicetify
    
    echo ""
    log_info "Копирую конфигурационные файлы..."
    echo "========================================="
    
    # Create config directory
    log_info "Создаю директорию конфигурации: $CONFIG_DIR"
    mkdir -p "$CONFIG_DIR"
    
    # Copy configurations
    echo ""
    copy_config "$DOTFILES_DIR/fish" "$CONFIG_DIR/fish" "Fish Shell"
    echo ""
    copy_config "$DOTFILES_DIR/fastfetch" "$CONFIG_DIR/fastfetch" "Fastfetch"
    
    echo ""
    log_info "Настройка Fish как оболочки по умолчанию..."
    echo "========================================="
    
    # Set fish as default shell
    if command -v fish &> /dev/null; then
        log_info "Настраиваю Fish как оболочку по умолчанию..."
        
        local fish_path="$(which fish)"
        log_info "Путь к Fish: $fish_path"
        
        # Add fish to /etc/shells if not present
        if ! grep -q "$fish_path" /etc/shells; then
            log_info "Добавляю Fish в /etc/shells..."
            echo -e "${BLUE}[SUDO]${NC} Выполняю: echo '$fish_path' | sudo tee -a /etc/shells"
            if echo "$fish_path" | sudo tee -a /etc/shells > /dev/null; then
                log_success "Fish добавлен в /etc/shells"
            else
                log_error "Не удалось добавить Fish в /etc/shells"
                return 1
            fi
        else
            log_success "Fish уже присутствует в /etc/shells"
        fi
        
        # Change default shell for current user
        log_info "Настраиваю Fish как оболочку по умолчанию..."
        log_info "Для смены оболочки потребуется ввести ваш пароль"
        echo -e "${BLUE}[CHSH]${NC} Выполняю: chsh -s '$fish_path'"
        
        if chsh -s "$fish_path"; then
            log_success "Fish установлен как оболочка по умолчанию"
            log_info "Изменения вступят в силу при следующем входе в систему"
            log_info "Для немедленного применения выполните: exec fish"
        else
            local chsh_exit_code=$?
            log_error "Не удалось установить Fish как оболочку по умолчанию (код выхода: $chsh_exit_code)"
            log_warning "Вы можете попробовать выполнить вручную: chsh -s $fish_path"
            log_info "Или просто запускайте Fish командой: fish"
        fi
    else
        log_error "Fish не найден в системе"
        return 1
    fi
    
    echo ""
    log_info "Финализация установки..."
    echo "========================================="
    
    log_success "Установка Fish shell завершена!"
    echo ""
    
    # Summary
    local installed_packages_count=${#INSTALLED_PACKAGES[@]}
    local failed_packages_count=${#FAILED_PACKAGES[@]}
    local installed_configs_count=${#INSTALLED_CONFIGS[@]}
    local failed_configs_count=${#FAILED_CONFIGS[@]}
    
    echo "========================================="
    echo -e "${GREEN}Установлено пакетов: $installed_packages_count${NC}"
    echo -e "${RED}Ошибок установки пакетов: $failed_packages_count${NC}"
    echo -e "${GREEN}Скопировано конфигураций: $installed_configs_count${NC}"
    echo -e "${RED}Ошибок копирования конфигураций: $failed_configs_count${NC}"
    
    if [ $installed_packages_count -gt 0 ]; then
        echo ""
        echo -e "${GREEN}Успешно установленные пакеты:${NC}"
        for package in "${INSTALLED_PACKAGES[@]}"; do
            echo -e "  ✓ $package"
        done
    fi
    
    if [ $failed_packages_count -gt 0 ]; then
        echo ""
        echo -e "${RED}Неустановленные пакеты:${NC}"
        for package in "${FAILED_PACKAGES[@]}"; do
            echo -e "  ✗ $package"
        done
    fi
    
    if [ $installed_configs_count -gt 0 ]; then
        echo ""
        echo -e "${GREEN}Успешно скопированные конфигурации:${NC}"
        for config in "${INSTALLED_CONFIGS[@]}"; do
            echo -e "  ✓ $config"
        done
    fi
    
    if [ $failed_configs_count -gt 0 ]; then
        echo ""
        echo -e "${RED}Ошибки конфигурации:${NC}"
        for config in "${FAILED_CONFIGS[@]}"; do
            echo -e "  ✗ $config"
        done
    fi
    
    echo ""
    echo -e "${YELLOW}Что дальше:${NC}"
    echo "• Выполните 'exec fish' для переключения на Fish в текущем терминале"
    echo "• Перезапустите терминал - Fish станет оболочкой по умолчанию"
    echo "• Fastfetch будет показывать информацию о системе при запуске Fish"
    echo "• Настройки Fish находятся в ~/.config/fish/"
    echo "• Для возврата в bash выполните: exec bash"
    echo "========================================="
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
