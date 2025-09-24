#!/bin/bash

# CLI tools installer
# Dependencies: chpaper, cursor, json-parse utilities

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
CLI_DIR="$DOTFILES_DIR/cli"
BIN_DIR="/usr/local/bin"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging arrays
INSTALLED_TOOLS=()
FAILED_TOOLS=()
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

# Function to install CLI tool
install_cli_tool() {
    local tool_name=$1
    local source_path="$CLI_DIR/$tool_name"
    local dest_path="$BIN_DIR/$tool_name"
    
    log_info "Устанавливаю CLI утилиту: $tool_name"
    
    # Check if source file exists
    if [ ! -f "$source_path" ]; then
        log_error "Файл не найден: $source_path"
        FAILED_TOOLS+=("$tool_name")
        return 1
    fi
    
    # Check if already installed and same version
    if [ -f "$dest_path" ]; then
        if cmp -s "$source_path" "$dest_path"; then
            log_success "$tool_name уже установлен (актуальная версия)"
            INSTALLED_TOOLS+=("$tool_name")
            return 0
        else
            log_warning "Обновляю $tool_name..."
        fi
    fi
    
    # Install the tool
    if sudo cp "$source_path" "$dest_path" 2>/dev/null; then
        sudo chmod +x "$dest_path"
        log_success "CLI утилита $tool_name установлена в $dest_path"
        INSTALLED_TOOLS+=("$tool_name")
        return 0
    else
        log_error "Не удалось установить CLI утилиту: $tool_name"
        FAILED_TOOLS+=("$tool_name")
        return 1
    fi
}

# Function to download and setup Cursor AppImage
download_cursor_appimage() {
    log_info "Скачиваю Cursor AppImage..."
    
    local appimage_dir="$HOME/AppImages"
    local cursor_url="https://downloads.cursor.com/production/b753cece5c67c47cb5637199a5a5de2b7100c18f/linux/x64/Cursor-1.6.35-x86_64.AppImage"
    local cursor_path="$appimage_dir/cursor.appimage"
    
    # Create AppImages directory if it doesn't exist
    if [ ! -d "$appimage_dir" ]; then
        mkdir -p "$appimage_dir"
        log_success "Создана папка $appimage_dir"
    fi
    
    # Check if cursor.appimage already exists
    if [ -f "$cursor_path" ]; then
        log_success "Cursor AppImage уже установлен"
        chmod +x "$cursor_path"
        INSTALLED_CONFIGS+=("cursor-appimage")
        return 0
    fi
    
    # Download Cursor AppImage
    log_info "Скачиваю Cursor AppImage (это может занять некоторое время)..."
    log_info "URL: $cursor_url"
    
    # Create temporary file first, then move to final location
    local temp_file="$cursor_path.tmp"
    
    echo -e "${BLUE}[WGET]${NC} wget --progress=bar:force:noscroll $cursor_url -O $temp_file"
    if wget --progress=bar:force:noscroll "$cursor_url" -O "$temp_file" 2>&1; then
        mv "$temp_file" "$cursor_path"
        # Make it executable
        chmod +x "$cursor_path"
        log_success "Cursor AppImage успешно скачан и настроен"
        INSTALLED_CONFIGS+=("cursor-appimage")
        
        # Verify the download
        if [ -x "$cursor_path" ]; then
            local file_size=$(du -h "$cursor_path" | cut -f1)
            log_success "Размер файла: $file_size"
        fi
        
        return 0
    else
        # Clean up temporary file if download failed
        [ -f "$temp_file" ] && rm -f "$temp_file"
        
        log_error "Не удалось скачать Cursor AppImage"
        log_warning "Возможные причины:"
        log_info "• Проблемы с подключением к интернету"
        log_info "• URL изменился или файл недоступен"
        log_info "• Недостаточно места на диске"
        echo ""
        log_warning "Попробуйте скачать вручную:"
        log_info "1. Перейдите на https://cursor.com"
        log_info "2. Скачайте AppImage версию"
        log_info "3. Переместите файл в $cursor_path"
        log_info "4. Сделайте его исполняемым: chmod +x $cursor_path"
        FAILED_CONFIGS+=("cursor-appimage")
        return 1
    fi
}

# Function to setup Cursor AppImage directory (legacy)
setup_cursor_dependencies() {
    log_info "Настраиваю зависимости для Cursor..."
    
    # Try to download Cursor AppImage automatically
    if download_cursor_appimage; then
        return 0
    fi
    
    # If download failed, provide manual instructions
    log_warning "Автоматическая установка не удалась"
    return 1
}

# Function to test installed tools
test_cli_tools() {
    log_info "Тестирую установленные CLI утилиты..."
    
    # Test chpaper
    if command -v chpaper &> /dev/null; then
        log_success "chpaper: доступен в PATH"
    else
        log_warning "chpaper: не найден в PATH"
    fi
    
    # Test json-parse
    if command -v json-parse &> /dev/null; then
        log_success "json-parse: доступен в PATH"
    else
        log_warning "json-parse: не найден в PATH"
    fi
    
    # Test cursor
    if command -v cursor &> /dev/null; then
        log_success "cursor: доступен в PATH"
        # Test if AppImage exists
        if [ -f "$HOME/AppImages/cursor.appimage" ]; then
            log_success "cursor: AppImage найден"
        else
            log_warning "cursor: AppImage не найден - скрипт может не работать"
        fi
    else
        log_warning "cursor: не найден в PATH"
    fi
}

# Function to show usage examples
show_usage_examples() {
    log_info "Примеры использования установленных утилит:"
    echo ""
    
    if [[ " ${INSTALLED_TOOLS[@]} " =~ " chpaper " ]]; then
        echo -e "${YELLOW}chpaper${NC} - утилита для смены обоев:"
        echo "  chpaper ~/Pictures/wallpaper.jpg"
        echo ""
    fi
    
    if [[ " ${INSTALLED_TOOLS[@]} " =~ " json-parse " ]]; then
        echo -e "${YELLOW}json-parse${NC} - парсер JSON:"
        echo "  echo '{\"key\": \"value\"}' | json-parse"
        echo "  cat config.json | json-parse .key"
        echo ""
    fi
    
    if [[ " ${INSTALLED_TOOLS[@]} " =~ " cursor " ]]; then
        echo -e "${YELLOW}cursor${NC} - запуск Cursor IDE:"
        echo "  cursor                    # открыть Cursor"
        echo "  cursor /path/to/project   # открыть проект"
        echo "  cursor file.txt           # открыть файл"
        echo ""
    fi
}

# Function to install required packages
install_required_packages() {
    log_info "Проверяю необходимые пакеты..."
    
    # Check and install wget if not present
    if ! command -v wget &> /dev/null; then
        log_info "Устанавливаю wget..."
        echo -e "${BLUE}[PACMAN]${NC} sudo pacman -S --noconfirm wget"
        if sudo pacman -S --noconfirm wget; then
            log_success "wget установлен"
        else
            log_error "Не удалось установить wget"
            return 1
        fi
    else
        log_success "wget уже установлен"
    fi
    
    return 0
}

# Main installation function
install_cli_tools() {
    log_info "Начинаю установку CLI утилит..."
    
    # Install required packages first
    if ! install_required_packages; then
        log_error "Не удалось установить необходимые пакеты"
        return 1
    fi
    
    # Check if CLI directory exists
    if [ ! -d "$CLI_DIR" ]; then
        log_error "Папка CLI не найдена: $CLI_DIR"
        return 1
    fi
    
    # Install CLI tools
    local cli_tools=("chpaper" "cursor" "json-parse")
    
    for tool in "${cli_tools[@]}"; do
        install_cli_tool "$tool"
    done
    
    # Setup special dependencies (download Cursor AppImage)
    setup_cursor_dependencies
    
    # Test installations
    test_cli_tools
    
    # Show usage examples
    show_usage_examples
    
    log_success "Установка CLI утилит завершена!"
}

# Function to return installation status
get_install_status() {
    echo "CLI_INSTALLED_TOOLS:(${INSTALLED_TOOLS[*]})"
    echo "CLI_FAILED_TOOLS:(${FAILED_TOOLS[*]})"
    echo "CLI_INSTALLED_CONFIGS:(${INSTALLED_CONFIGS[*]})"
    echo "CLI_FAILED_CONFIGS:(${FAILED_CONFIGS[*]})"
}

# Run installation if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_cli_tools
    get_install_status
fi
