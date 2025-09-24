#!/bin/bash

# Docker installer for dotfiles
# Dependencies: docker, docker-compose

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

# Function to check if running as sudo
check_sudo() {
    if [ "$EUID" -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# Function to install Docker packages
install_docker_packages() {
    log_info "Устанавливаю Docker и Docker Compose..."
    
    # Update system packages first
    log_info "Обновляю системные пакеты..."
    echo -e "${BLUE}[PACMAN]${NC} sudo pacman -Syu --noconfirm"
    if sudo pacman -Syu --noconfirm; then
        log_success "Системные пакеты обновлены"
    else
        log_warning "Не удалось обновить системные пакеты, продолжаю..."
    fi
    
    # Install Docker
    echo -e "${BLUE}[PACMAN]${NC} sudo pacman -S docker --noconfirm"
    if sudo pacman -S docker --noconfirm; then
        log_success "Docker установлен"
        INSTALLED_PACKAGES+=("docker")
    else
        log_error "Не удалось установить Docker"
        FAILED_PACKAGES+=("docker")
        return 1
    fi
    
    # Install Docker Compose
    echo -e "${BLUE}[PACMAN]${NC} sudo pacman -S docker-compose --noconfirm"
    if sudo pacman -S docker-compose --noconfirm; then
        log_success "Docker Compose установлен"
        INSTALLED_PACKAGES+=("docker-compose")
    else
        log_error "Не удалось установить Docker Compose"
        FAILED_PACKAGES+=("docker-compose")
        return 1
    fi
    
    return 0
}

# Function to configure Docker service
configure_docker_service() {
    log_info "Настраиваю Docker сервис..."
    
    # Enable Docker service
    if sudo systemctl enable docker.service 2>/dev/null; then
        log_success "Docker сервис включен для автозапуска"
        INSTALLED_CONFIGS+=("docker-service-enabled")
    else
        log_error "Не удалось включить Docker сервис"
        FAILED_CONFIGS+=("docker-service-enabled")
        return 1
    fi
    
    # Start Docker service
    if sudo systemctl start docker.service 2>/dev/null; then
        log_success "Docker сервис запущен"
        INSTALLED_CONFIGS+=("docker-service-started")
    else
        log_error "Не удалось запустить Docker сервис"
        FAILED_CONFIGS+=("docker-service-started")
        return 1
    fi
    
    return 0
}

# Function to add user to docker group
add_user_to_docker_group() {
    log_info "Добавляю пользователя в группу docker..."
    
    # Get the actual user (not root when using sudo)
    local target_user
    if [ -n "$SUDO_USER" ]; then
        target_user="$SUDO_USER"
    elif [ -n "$USER" ]; then
        target_user="$USER"
    else
        target_user="$(whoami)"
    fi
    
    # Add user to docker group
    if sudo usermod -aG docker "$target_user" 2>/dev/null; then
        log_success "Пользователь '$target_user' добавлен в группу docker"
        INSTALLED_CONFIGS+=("docker-group-$target_user")
        
        log_warning "ВАЖНО: Для применения изменений группы необходимо:"
        log_info "1. Выйти из системы и войти заново, ИЛИ"
        log_info "2. Перезагрузить систему, ИЛИ"
        log_info "3. Выполнить: newgrp docker"
        
        return 0
    else
        log_error "Не удалось добавить пользователя '$target_user' в группу docker"
        FAILED_CONFIGS+=("docker-group-$target_user")
        return 1
    fi
}

# Function to verify Docker installation
verify_docker_installation() {
    log_info "Проверяю установку Docker..."
    
    # Check Docker service status
    if systemctl is-active --quiet docker; then
        log_success "Docker сервис активен"
    else
        log_warning "Docker сервис не активен"
        return 1
    fi
    
    # Check Docker version
    if command -v docker &> /dev/null; then
        local docker_version=$(docker --version 2>/dev/null)
        log_success "Docker версия: $docker_version"
    else
        log_error "Docker команда недоступна"
        return 1
    fi
    
    # Check Docker Compose version
    if command -v docker-compose &> /dev/null; then
        local compose_version=$(docker-compose --version 2>/dev/null)
        log_success "Docker Compose версия: $compose_version"
    else
        log_warning "Docker Compose команда недоступна"
    fi
    
    # Try to run Docker hello-world (only if user is in docker group)
    local current_user=$(whoami)
    if groups "$current_user" | grep -q docker 2>/dev/null; then
        log_info "Тестирую Docker с hello-world контейнером..."
        if docker run --rm hello-world &>/dev/null; then
            log_success "Docker работает корректно!"
        else
            log_warning "Тест Docker завершился с ошибкой (возможно, нужен перелогин)"
        fi
    else
        log_warning "Пользователь не в группе docker, пропускаю тест hello-world"
    fi
    
    return 0
}

# Function to show usage examples
show_usage_examples() {
    log_info "Примеры использования Docker:"
    echo ""
    
    echo -e "${YELLOW}Основные команды Docker:${NC}"
    echo "  docker --version              # проверить версию"
    echo "  docker run hello-world        # тестовый контейнер"
    echo "  docker ps                     # список запущенных контейнеров"
    echo "  docker ps -a                  # список всех контейнеров"
    echo "  docker images                 # список образов"
    echo ""
    
    echo -e "${YELLOW}Docker Compose команды:${NC}"
    echo "  docker-compose --version      # проверить версию"
    echo "  docker-compose up -d          # запустить сервисы в фоне"
    echo "  docker-compose down           # остановить и удалить сервисы"
    echo "  docker-compose logs           # посмотреть логи"
    echo ""
    
    echo -e "${YELLOW}Полезные команды для разработки:${NC}"
    echo "  docker run -it ubuntu bash    # интерактивный Ubuntu контейнер"
    echo "  docker run -p 8080:80 nginx   # nginx на порту 8080"
    echo "  docker system prune           # очистка неиспользуемых ресурсов"
    echo ""
    
    if ! groups "$(whoami)" | grep -q docker 2>/dev/null; then
        echo -e "${YELLOW}После перелогина/перезагрузки вы сможете использовать Docker без sudo.${NC}"
    fi
}

# Function removed - no examples creation

# Main installation function
install_docker() {
    log_info "Начинаю установку Docker..."
    
    # Check if we have sudo privileges
    if ! sudo -n true 2>/dev/null; then
        log_info "Запрашиваю права sudo для установки Docker..."
        sudo -v || {
            log_error "Необходимы права sudo для установки Docker"
            return 1
        }
    fi
    
    # Install Docker packages
    if ! install_docker_packages; then
        log_error "Не удалось установить Docker пакеты"
        return 1
    fi
    
    # Configure Docker service
    if ! configure_docker_service; then
        log_error "Не удалось настроить Docker сервис"
        return 1
    fi
    
    # Add user to docker group
    add_user_to_docker_group
    
    # Wait a moment for service to fully start
    sleep 2
    
    # Verify installation
    verify_docker_installation
    
    # Show usage examples
    show_usage_examples
    
    log_success "Установка Docker завершена!"
    
    return 0
}

# Function to return installation status
get_install_status() {
    echo "DOCKER_INSTALLED_PACKAGES:(${INSTALLED_PACKAGES[*]})"
    echo "DOCKER_FAILED_PACKAGES:(${FAILED_PACKAGES[*]})"
    echo "DOCKER_INSTALLED_CONFIGS:(${INSTALLED_CONFIGS[*]})"
    echo "DOCKER_FAILED_CONFIGS:(${FAILED_CONFIGS[*]})"
}

# Run installation if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_docker
    get_install_status
fi
