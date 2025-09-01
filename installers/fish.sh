#!/bin/bash

# Установка и настройка Fish shell

source "$(dirname "$0")/common.sh"

setup_fish_config() {
    print_info "Настройка Fish shell..."
    
    local source_dir="../fish"
    local target_dir="~/.config/fish"
    
    create_backup "$target_dir"
    copy_config "$source_dir" "$target_dir"
}

setup_fish_as_default() {
    print_info "Настройка Fish как оболочки по умолчанию..."
    
    if [ "$SHELL" != "/usr/bin/fish" ]; then
        print_info "Установка Fish как оболочки по умолчанию..."
        chsh -s /usr/bin/fish
        print_success "Fish установлен как оболочка по умолчанию"
        print_warning "Перезайдите в систему для применения изменений"
    else
        print_success "Fish уже является оболочкой по умолчанию"
    fi
}

setup_go_environment() {
    print_info "Настройка переменных окружения для Go..."
    
    if ! command -v go &> /dev/null; then
        print_warning "Go не установлен, пропускаем настройку переменных окружения"
        return 0
    fi
    
    mkdir -p ~/go/{bin,src,pkg}
    
    local fish_config="$HOME/.config/fish/config.fish"
    if [ -f "$fish_config" ]; then
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
}

main() {
    print_info "🐚 Настройка Fish shell"
    echo
    
    setup_fish_config
    setup_fish_as_default
    setup_go_environment
    
    print_success "Настройка Fish shell завершена!"
}

main "$@"
