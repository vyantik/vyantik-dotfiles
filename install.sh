#!/bin/bash

# 🎨 Dotfiles Installer
# Скрипт для установки и настройки dotfiles

set -e  # Остановка при ошибке

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функции для вывода
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Проверка на Arch Linux
check_arch() {
    if ! grep -q "Arch Linux" /etc/os-release 2>/dev/null; then
        print_warning "Этот скрипт оптимизирован для Arch Linux"
        read -p "Продолжить установку? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Проверка и установка зависимостей
install_dependencies() {
    print_info "Проверка и установка зависимостей..."
    
    # Основные пакеты
    local packages=(
        "hyprland"
        "kitty"
        "fish"
        "waybar"
        "wofi"
        "swaync"
        "hyprpaper"
        "hyprlock"
        "fastfetch"
        "polkit-gnome"
        "pulseaudio-alsa"
        "networkmanager"
        "python"
        "python-pip"
        "go"
        "ttf-font-awesome"
        "otf-font-awesome"
        "ttf-jetbrains-mono"
        "pkgfile"
        "ttf-dejavu"
        "powerline-fonts"
        "nwg-look"
        "papirus-icon-theme"
    )
    
    # Проверяем, какие пакеты уже установлены
    local missing_packages=()
    for package in "${packages[@]}"; do
        if ! pacman -Q "$package" &>/dev/null; then
            missing_packages+=("$package")
        fi
    done
    
    if [ ${#missing_packages[@]} -gt 0 ]; then
        print_info "Установка недостающих пакетов: ${missing_packages[*]}"
        sudo pacman -S --needed "${missing_packages[@]}"
    else
        print_success "Все основные пакеты уже установлены"
    fi
    
    # Проверяем yay для AUR пакетов
    if ! command -v yay &> /dev/null; then
        print_info "Установка yay для AUR пакетов..."
        sudo pacman -S --needed git base-devel
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay
        makepkg -si --noconfirm
        cd - > /dev/null
        rm -rf /tmp/yay
        print_success "yay установлен успешно"
    else
        print_success "yay уже установлен"
    fi
    
    # Установка AUR пакетов
    local aur_packages=("pokeget" "hyprpicker" "otf-codenewroman-nerd" "pywal")
    for package in "${aur_packages[@]}"; do
        if ! yay -Q "$package" &>/dev/null; then
            print_info "Установка AUR пакета: $package"
            yay -S --noconfirm "$package"
        else
            print_success "AUR пакет $package уже установлен"
        fi
    done
}

# Создание резервных копий
create_backups() {
    print_info "Создание резервных копий существующих конфигов..."
    
    local configs=(
        "~/.config/hypr"
        "~/.config/kitty"
        "~/.config/waybar"
        "~/.config/wofi"
        "~/.config/swaync"
        "~/.config/fish"
        "~/.config/fastfetch"
    )
    
    local backup_dir="$HOME/.config_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    for config in "${configs[@]}"; do
        local expanded_config=$(eval echo "$config")
        if [ -d "$expanded_config" ]; then
            print_info "Резервная копия: $expanded_config"
            cp -r "$expanded_config" "$backup_dir/"
        fi
    done
    
    print_success "Резервные копии сохранены в: $backup_dir"
}

# Создание символических ссылок
create_symlinks() {
    print_info "Создание символических ссылок..."
    
    local current_dir=$(pwd)
    local configs=(
        "hypr:~/.config/hypr"
        "kitty:~/.config/kitty"
        "waybar:~/.config/waybar"
        "wofi:~/.config/wofi"
        "swaync:~/.config/swaync"
        "fish:~/.config/fish"
        "fastfetch:~/.config/fastfetch"
    )
    
    for config in "${configs[@]}"; do
        IFS=':' read -r source target <<< "$config"
        local expanded_target=$(eval echo "$target")
        
        # Удаляем существующие директории/файлы
        if [ -e "$expanded_target" ]; then
            rm -rf "$expanded_target"
        fi
        
        # Создаем символическую ссылку
        ln -sf "$current_dir/$source" "$expanded_target"
        print_success "Создана ссылка: $source -> $expanded_target"
    done
}

# Установка прав доступа для скриптов
set_permissions() {
    print_info "Установка прав доступа для скриптов..."
    
    # Делаем скрипты исполняемыми
    find . -name "*.sh" -type f -exec chmod +x {} \;
    find . -name "*.py" -type f -exec chmod +x {} \;
    
    print_success "Права доступа установлены"
}

# Настройка Fish как оболочки по умолчанию
setup_fish() {
    print_info "Настройка Fish shell..."
    
    # Проверяем, является ли Fish оболочкой по умолчанию
    if [ "$SHELL" != "/usr/bin/fish" ]; then
        print_info "Установка Fish как оболочки по умолчанию..."
        chsh -s /usr/bin/fish
        print_success "Fish установлен как оболочки по умолчанию"
        print_warning "Перезайдите в систему для применения изменений"
    else
        print_success "Fish уже является оболочкой по умолчанию"
    fi
    
    # Настройка переменных окружения для Go
    print_info "Настройка переменных окружения для Go..."
    
    # Проверяем, установлен ли Go
    if command -v go &> /dev/null; then
        # Создаем директорию для Go если её нет
        mkdir -p ~/go/{bin,src,pkg}
        
        # Добавляем переменные окружения в fish config если их нет
        local fish_config="$HOME/.config/fish/config.fish"
        if [ -f "$fish_config" ]; then
            # Проверяем, есть ли уже настройки Go
            if ! grep -q "GOPATH\|GOROOT\|GOPROXY" "$fish_config"; then
                echo "" >> "$fish_config"
                echo "# Go environment variables" >> "$fish_config"
                echo "set --export GOPATH \$HOME/go" >> "$fish_config"
                echo "set --export GOROOT /usr/lib/go" >> "$fish_config"
                echo "set --export GOPROXY https://proxy.golang.org,direct" >> "$fish_config"
                echo "set --export PATH \$GOPATH/bin \$PATH" >> "$fish_config"
                print_success "Переменные окружения Go добавлены в fish config"
            else
                print_success "Переменные окружения Go уже настроены"
            fi
        fi
    else
        print_warning "Go не установлен, пропускаем настройку переменных окружения"
    fi
}

# Настройка автозапуска для Hyprland
setup_autostart() {
    print_info "Настройка автозапуска..."
    
    # Создаем директорию для автозапуска если её нет
    mkdir -p ~/.config/hypr
    
    print_success "Автозапуск настроен"
}

# Проверка и настройка шрифтов
setup_fonts() {
    print_info "Проверка шрифтов..."
    
    # Проверяем наличие всех установленных шрифтов
    local fonts=(
        "JetBrains Mono"
        "Font Awesome"
        "DejaVu"
        "Powerline"
    )
    
    for font in "${fonts[@]}"; do
        if fc-list | grep -q "$font"; then
            print_success "Шрифт $font уже установлен"
        else
            print_warning "Шрифт $font не найден"
        fi
    done
    
    print_success "Проверка шрифтов завершена"
}

# Настройка pywal (опционально)
setup_pywal() {
    print_info "Настройка pywal для генерации цветов..."
    
    # Создаем базовую цветовую схему если её нет
    if [ ! -f ~/.cache/wal/colors.json ]; then
        print_info "Создание базовой цветовой схемы..."
        mkdir -p ~/.cache/wal
        echo '{"colors": {"color0": "#1a1a1a", "color7": "#ffffff", "color8": "#333333", "color9": "#ff6b6b"}, "special": {"background": "#1a1a1a", "foreground": "#ffffff"}}' > ~/.cache/wal/colors.json
    fi
    
    # Запускаем скрипт генерации цветов
    if [ -f ~/.config/hypr/set_wal_colors.py ]; then
        python3 ~/.config/hypr/set_wal_colors.py
    fi
    
    print_success "Pywal настроен"
}

# Установка и сборка chpaper
setup_chpaper() {
    print_info "Установка и сборка chpaper..."
    
    # Проверяем, установлен ли Go
    if ! command -v go &> /dev/null; then
        print_error "Go не установлен, пропускаем установку chpaper"
        return 1
    fi
    
    # Проверяем, есть ли уже chpaper в /usr/local/bin
    if [ -f /usr/local/bin/chpaper ]; then
        print_info "chpaper уже установлен в /usr/local/bin"
        local current_version=$(/usr/local/bin/chpaper --version 2>/dev/null || echo "unknown")
        print_success "Текущая версия chpaper: $current_version"
        return 0
    fi
    
    # Создаем временную директорию для сборки
    local temp_dir="/tmp/chpaper_build_$(date +%s)"
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    
    print_info "Клонирование репозитория chpaper..."
    if git clone https://github.com/vyantik/chpaper.git .; then
        print_success "Репозиторий успешно клонирован"
    else
        print_error "Ошибка при клонировании репозитория"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    print_info "Сборка chpaper..."
    if go build -o chpaper ./cmd; then
        print_success "chpaper успешно собран"
    else
        print_error "Ошибка при сборке chpaper"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    print_info "Установка chpaper в /usr/local/bin..."
    if sudo cp chpaper /usr/local/bin/; then
        sudo chmod +x /usr/local/bin/chpaper
        print_success "chpaper установлен в /usr/local/bin"
    else
        print_error "Ошибка при установке chpaper"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Проверяем установку
    if command -v chpaper &> /dev/null; then
        local version=$(chpaper --version 2>/dev/null || echo "unknown")
        print_success "chpaper успешно установлен (версия: $version)"
    else
        print_error "chpaper не найден в PATH"
    fi
    
    # Очищаем временную директорию
    cd - > /dev/null
    rm -rf "$temp_dir"
    
    print_success "Установка chpaper завершена"
}

# Финальная проверка
final_check() {
    print_info "Проведение финальной проверки..."
    
    local configs=(
        "~/.config/hypr/hyprland.conf"
        "~/.config/kitty/kitty.conf"
        "~/.config/waybar/config.jsonc"
        "~/.config/wofi/config"
        "~/.config/fish/config.fish"
    )
    
    local all_good=true
    for config in "${configs[@]}"; do
        local expanded_config=$(eval echo "$config")
        if [ -f "$expanded_config" ]; then
            print_success "✓ $config"
        else
            print_error "✗ $config - не найден"
            all_good=false
        fi
    done
    
    # Проверка версий установленных программ
    print_info "Проверка версий установленных программ..."
    
    if command -v go &> /dev/null; then
        local go_version=$(go version | awk '{print $3}')
        print_success "✓ Go: $go_version"
    else
        print_error "✗ Go не установлен"
        all_good=false
    fi
    
    if command -v yay &> /dev/null; then
        local yay_version=$(yay --version | head -n1)
        print_success "✓ yay: $yay_version"
    else
        print_error "✗ yay не установлен"
        all_good=false
    fi
    
    if command -v fish &> /dev/null; then
        local fish_version=$(fish --version | awk '{print $3}')
        print_success "✓ Fish: $fish_version"
    else
        print_error "✗ Fish не установлен"
        all_good=false
    fi
    
    if command -v chpaper &> /dev/null; then
        local chpaper_version=$(chpaper --version 2>/dev/null || echo "unknown")
        print_success "✓ chpaper: $chpaper_version"
    else
        print_error "✗ chpaper не установлен"
        all_good=false
    fi
    
    if command -v hyprpicker &> /dev/null; then
        local hyprpicker_version=$(hyprpicker --version 2>/dev/null || echo "unknown")
        print_success "✓ hyprpicker: $hyprpicker_version"
    else
        print_error "✗ hyprpicker не установлен"
        all_good=false
    fi
    
    if command -v wal &> /dev/null; then
        local pywal_version=$(wal --version 2>/dev/null || echo "unknown")
        print_success "✓ pywal: $pywal_version"
    else
        print_error "✗ pywal не установлен"
        all_good=false
    fi
    
    # Проверка шрифта otf-codenewroman-nerd
    if fc-list | grep -q "CodeNewRoman Nerd Font"; then
        print_success "✓ otf-codenewroman-nerd: установлен"
    else
        print_error "✗ otf-codenewroman-nerd не установлен"
        all_good=false
    fi
    
    # Проверка шрифтов Font Awesome
    if fc-list | grep -q "Font Awesome"; then
        print_success "✓ Font Awesome: установлен"
    else
        print_error "✗ Font Awesome не установлен"
        all_good=false
    fi
    
    # Проверка шрифта JetBrains Mono
    if fc-list | grep -q "JetBrains Mono"; then
        print_success "✓ JetBrains Mono: установлен"
    else
        print_error "✗ JetBrains Mono не установлен"
        all_good=false
    fi
    
    # Проверка pkgfile
    if command -v pkgfile &> /dev/null; then
        local pkgfile_version=$(pkgfile --version 2>/dev/null || echo "unknown")
        print_success "✓ pkgfile: $pkgfile_version"
    else
        print_error "✗ pkgfile не установлен"
        all_good=false
    fi
    
    # Проверка шрифта DejaVu
    if fc-list | grep -q "DejaVu"; then
        print_success "✓ DejaVu: установлен"
    else
        print_error "✗ DejaVu не установлен"
        all_good=false
    fi
    
    # Проверка Powerline шрифтов
    if fc-list | grep -q "Powerline"; then
        print_success "✓ Powerline fonts: установлены"
    else
        print_error "✗ Powerline fonts не установлены"
        all_good=false
    fi
    
    # Проверка nwg-look
    if command -v nwg-look &> /dev/null; then
        local nwg_look_version=$(nwg-look --version 2>/dev/null || echo "unknown")
        print_success "✓ nwg-look: $nwg_look_version"
    else
        print_error "✗ nwg-look не установлен"
        all_good=false
    fi
    
    # Проверка papirus-icon-theme
    if [ -d "/usr/share/icons/Papirus" ] || [ -d "/usr/share/icons/Papirus-Dark" ] || [ -d "/usr/share/icons/Papirus-Light" ]; then
        print_success "✓ papirus-icon-theme: установлен"
    else
        print_error "✗ papirus-icon-theme не установлен"
        all_good=false
    fi
    
    if [ "$all_good" = true ]; then
        print_success "Все конфигурационные файлы и программы установлены корректно!"
    else
        print_error "Некоторые файлы или программы не были установлены"
        exit 1
    fi
}

# Показ информации о следующем шаге
show_next_steps() {
    echo
    print_success "🎉 Установка завершена успешно!"
    echo
    echo "Следующие шаги:"
    echo "1. Перезагрузите систему или перезапустите сессию"
    echo "2. Войдите в Hyprland (если используете дисплейный менеджер)"
    echo "3. Или запустите Hyprland командой: Hyprland"
    echo
    echo "Основные горячие клавиши:"
    echo "- Super + Enter: Открыть терминал"
    echo "- Super + R: Открыть меню приложений"
    echo "- Super + Q: Закрыть окно"
    echo "- Super + 1-9: Переключение рабочих пространств"
    echo
    echo "Для изменения обоев:"
    echo "1. Поместите изображение в ~/.config/hypr/wallpaper/"
    echo "2. Обновите путь в ~/.config/hypr/hyprpaper.conf"
    echo "3. Перезапустите Hyprland"
    echo
    echo "Установленные инструменты разработки:"
    echo "- Go: $(go version 2>/dev/null | awk '{print $3}' || echo 'не установлен')"
    echo "- yay: $(yay --version 2>/dev/null | head -n1 || echo 'не установлен')"
    echo "- Fish: $(fish --version 2>/dev/null | awk '{print $3}' || echo 'не установлен')"
    echo "- chpaper: $(chpaper --version 2>/dev/null || echo 'не установлен')"
    echo "- hyprpicker: $(hyprpicker --version 2>/dev/null || echo 'не установлен')"
    echo "- pywal: $(wal --version 2>/dev/null || echo 'не установлен')"
    echo "- otf-codenewroman-nerd: $(fc-list | grep -q 'CodeNewRoman Nerd Font' && echo 'установлен' || echo 'не установлен')"
    echo "- Font Awesome: $(fc-list | grep -q 'Font Awesome' && echo 'установлен' || echo 'не установлен')"
    echo "- JetBrains Mono: $(fc-list | grep -q 'JetBrains Mono' && echo 'установлен' || echo 'не установлен')"
    echo "- pkgfile: $(pkgfile --version 2>/dev/null || echo 'не установлен')"
    echo "- DejaVu: $(fc-list | grep -q 'DejaVu' && echo 'установлен' || echo 'не установлен')"
    echo "- Powerline fonts: $(fc-list | grep -q 'Powerline' && echo 'установлены' || echo 'не установлены')"
    echo "- nwg-look: $(nwg-look --version 2>/dev/null || echo 'не установлен')"
    echo "- papirus-icon-theme: $([ -d '/usr/share/icons/Papirus' ] || [ -d '/usr/share/icons/Papirus-Dark' ] || [ -d '/usr/share/icons/Papirus-Light' ] && echo 'установлен' || echo 'не установлен')"
    echo
    echo "Переменные окружения Go:"
    echo "- GOPATH: ~/go"
    echo "- GOROOT: /usr/lib/go"
    echo "- GOPROXY: https://proxy.golang.org,direct"
    echo
    echo "Использование chpaper:"
    echo "- chpaper --path /path/to/image.png"
    echo "- Поддерживаемые форматы: PNG, JPEG/JPG, WebP"
    echo "- Автоматическая генерация цветовых схем через pywal"
    echo
    echo "Использование hyprpicker:"
    echo "- hyprpicker -r: выбор цвета с экрана"
    echo "- hyprpicker -a: выбор цвета с автоматическим копированием в буфер"
    echo "- hyprpicker -f hex: вывод в формате hex"
    echo
    echo "Использование pywal:"
    echo "- wal -i /path/to/image.png: генерация цветовой схемы из изображения"
    echo "- wal -l: использование светлой темы"
    echo "- wal -s: генерация схемы для конкретного терминала"
    echo
    echo "Использование pkgfile:"
    echo "- pkgfile -u: обновление базы данных пакетов"
    echo "- pkgfile <команда>: поиск пакета, содержащего команду"
    echo "- pkgfile -b <файл>: поиск пакета, содержащего файл"
    echo
    echo "Использование nwg-look:"
    echo "- nwg-look: запуск графического интерфейса для настройки GTK тем"
    echo "- nwg-look -a: применение тем автоматически"
    echo "- nwg-look -t <тема>: применение конкретной темы"
    echo
    print_info "Документация: https://wiki.hyprland.org/"
    print_info "Go документация: https://golang.org/doc/"
    print_info "chpaper репозиторий: https://github.com/vyantik/chpaper"
    print_info "hyprpicker документация: https://github.com/hyprwm/hyprpicker"
    print_info "pywal документация: https://github.com/dylanaraps/pywal"
}

# Главная функция
main() {
    echo "🎨 Установщик Dotfiles"
    echo "======================"
    echo
    
    check_arch
    install_dependencies
    create_backups
    create_symlinks
    set_permissions
    setup_fonts
    setup_pywal
    setup_autostart
    setup_fish
    setup_chpaper    
    final_check
    show_next_steps
}

# Запуск главной функции
main "$@" 
