#!/bin/bash

# Yazi file manager installer
# Dependencies: yazi, file, poppler, ffmpegthumbnailer, unar, jq, ripgrep, fzf, zoxide

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

# Function to create Yazi configuration
create_yazi_config() {
    local yazi_config_dir="$CONFIG_DIR/yazi"
    
    log_info "Создаю конфигурацию Yazi..."
    
    # Create yazi config directory
    mkdir -p "$yazi_config_dir"
    
    # Create yazi.toml configuration
    cat > "$yazi_config_dir/yazi.toml" << 'EOF'
[manager]
ratio          = [ 1, 4, 3 ]
sort_by        = "alphabetical"
sort_sensitive = false
sort_reverse   = false
sort_dir_first = true
sort_translit  = false
linemode       = "none"
show_hidden    = false
show_symlink   = true
scrolloff      = 5

[preview]
tab_size        = 2
max_width       = 600
max_height      = 900
cache_dir       = ""
image_filter    = "triangle"
image_quality   = 75
sixel_fraction  = 15
ueberzug_scale  = 1
ueberzug_offset = [ 0, 0 ]

[opener]
edit = [
    { run = 'nvim "$@"', desc = "Edit with Neovim", block = true, for = "unix" },
    { run = 'code "$@"', desc = "Edit with VS Code", block = false, for = "unix" },
]
open = [
    { run = 'xdg-open "$@"', desc = "Open", for = "linux" },
]
reveal = [
    { run = 'thunar "$@"', desc = "Reveal in Thunar", for = "linux" },
]

[open]
rules = [
    { name = "*/", use = [ "edit", "open", "reveal" ] },
    { mime = "text/*", use = [ "edit", "reveal" ] },
    { mime = "image/*", use = [ "open", "reveal" ] },
    { mime = "video/*", use = [ "open", "reveal" ] },
    { mime = "audio/*", use = [ "open", "reveal" ] },
    { mime = "inode/x-empty", use = [ "edit", "reveal" ] },
    { mime = "application/json", use = [ "edit", "reveal" ] },
    { mime = "*/javascript", use = [ "edit", "reveal" ] },
    { mime = "*/x-wine-extension-ini", use = [ "edit", "reveal" ] },
    { name = "*", use = [ "open", "reveal" ] },
]

[tasks]
micro_workers    = 10
macro_workers    = 25
bizarre_retry    = 5
image_alloc      = 536870912  # 512MB
image_bound      = [ 0, 0 ]
suppress_preload = false

[plugin]
prepend_preloaders = [
    { name = "*", cond = "!mime", run = "mime", multi = true, prio = "high" },
]
prepend_previewers = [
    { name = "*/", run = "folder", sync = true },
]
prepend_fetchers = [
    { id = "git", name = "*", run = "git" },
    { id = "git", name = "*/", run = "git" },
]

[input]
cd_title  = "Change directory:"
cd_origin = "top-center"
cd_offset = [ 0, 2 ]

create_title  = "Create:"
create_origin = "top-center"
create_offset = [ 0, 2 ]

rename_title  = "Rename:"
rename_origin = "hovered"
rename_offset = [ 0, 1 ]

trash_title 	= "Move {n} selected file{s} to trash? (y/N)"
trash_origin	= "top-center"
trash_offset	= [ 0, 2 ]

delete_title 	= "Delete {n} selected file{s} permanently? (y/N)"
delete_origin	= "top-center"
delete_offset	= [ 0, 2 ]

filter_title  = "Filter:"
filter_origin = "top-center"
filter_offset = [ 0, 2 ]

find_title  = [ "Find next:", "Find previous:" ]
find_origin = "top-center"
find_offset = [ 0, 2 ]

search_title  = "Search via {n}:"
search_origin = "top-center"
search_offset = [ 0, 2 ]

shell_title  = [ "Shell:", "Shell (block):" ]
shell_origin = "top-center"
shell_offset = [ 0, 2 ]

quit_title  = "{n} task{s} running, sure to quit? (y/N)"
quit_origin = "top-center"
quit_offset = [ 0, 2 ]

[select]
open_title  = "Open with:"
open_origin = "hovered"
open_offset = [ 0, 1 ]

[log]
enabled = false
EOF

    # Create keymap.toml
    cat > "$yazi_config_dir/keymap.toml" << 'EOF'
[manager]

keymap = [
    { on = [ "<Esc>" ], run = "escape",             desc = "Exit visual mode, clear selected, or cancel search" },
    { on = [ "<C-[>" ], run = "escape",             desc = "Exit visual mode, clear selected, or cancel search" },
    { on = [ "q" ],     run = "quit",               desc = "Exit the process" },
    { on = [ "Q" ],     run = "quit --no-cwd-file", desc = "Exit the process without writing cwd-file" },
    { on = [ "<C-c>" ], run = "close",              desc = "Close the current tab, or quit if it is last tab" },
    { on = [ "<C-z>" ], run = "suspend",            desc = "Suspend the process" },

    # Hopping
    { on = [ "k" ], run = "arrow -1", desc = "Move cursor up" },
    { on = [ "j" ], run = "arrow 1",  desc = "Move cursor down" },

    { on = [ "<Up>" ],   run = "arrow -1", desc = "Move cursor up" },
    { on = [ "<Down>" ], run = "arrow 1",  desc = "Move cursor down" },

    { on = [ "<C-u>" ], run = "arrow -50%", desc = "Move cursor up half page" },
    { on = [ "<C-d>" ], run = "arrow 50%",  desc = "Move cursor down half page" },

    { on = [ "<C-b>" ], run = "arrow -100%", desc = "Move cursor up one page" },
    { on = [ "<C-f>" ], run = "arrow 100%",  desc = "Move cursor down one page" },

    { on = [ "<S-Up>" ],   run = "arrow -5", desc = "Move cursor up 5 lines" },
    { on = [ "<S-Down>" ], run = "arrow 5",  desc = "Move cursor down 5 lines" },

    { on = [ "<A-k>" ], run = "arrow -5", desc = "Move cursor up 5 lines" },
    { on = [ "<A-j>" ], run = "arrow 5",  desc = "Move cursor down 5 lines" },

    # Navigation
    { on = [ "h" ], run = "leave", desc = "Go back to the parent directory" },
    { on = [ "l" ], run = "enter", desc = "Enter the child directory" },

    { on = [ "<Left>" ],  run = "leave", desc = "Go back to the parent directory" },
    { on = [ "<Right>" ], run = "enter", desc = "Enter the child directory" },

    { on = [ "H" ], run = "back",    desc = "Go back to the previous directory" },
    { on = [ "L" ], run = "forward", desc = "Go forward to the next directory" },

    # Seeking
    { on = [ "K" ], run = "seek -5", desc = "Seek up 5 units in the preview" },
    { on = [ "J" ], run = "seek 5",  desc = "Seek down 5 units in the preview" },

    { on = [ "<S-Left>" ],  run = "seek -5", desc = "Seek up 5 units in the preview" },
    { on = [ "<S-Right>" ], run = "seek 5",  desc = "Seek down 5 units in the preview" },

    # Selection
    { on = [ "<Space>" ], run = [ "select --state=none", "arrow 1" ], desc = "Toggle the current selection state" },
    { on = [ "v" ],       run = "visual_mode",                        desc = "Enter visual mode (selection mode)" },
    { on = [ "V" ],       run = "visual_mode --unset",                desc = "Enter visual mode (unset mode)" },
    { on = [ "<C-a>" ],   run = "select_all --state=true",            desc = "Select all files" },
    { on = [ "<C-r>" ],   run = "select_all --state=none",            desc = "Inverse selection of all files" },

    # Operation
    { on = [ "o" ],         run = "open",                    desc = "Open the selected files" },
    { on = [ "O" ],         run = "open --interactive",      desc = "Open the selected files interactively" },
    { on = [ "<Enter>" ],   run = "open",                    desc = "Open the selected files" },
    { on = [ "<C-Enter>" ], run = "open --interactive",      desc = "Open the selected files interactively" },
    { on = [ "y" ],         run = [ "yank", "escape --visual" ], desc = "Copy the selected files" },
    { on = [ "x" ],         run = [ "yank --cut", "escape --visual" ], desc = "Cut the selected files" },
    { on = [ "p" ],         run = "paste",                   desc = "Paste the files" },
    { on = [ "P" ],         run = "paste --force",           desc = "Paste the files (overwrite if the destination exists)" },
    { on = [ "-" ],         run = "link",                    desc = "Symlink the absolute path of files" },
    { on = [ "_" ],         run = "link --relative",         desc = "Symlink the relative path of files" },
    { on = [ "Y" ],         run = "unyank",                  desc = "Cancel the yank status of files" },
    { on = [ "d" ],         run = [ "remove", "escape --visual" ], desc = "Move the files to the trash" },
    { on = [ "D" ],         run = [ "remove --permanently", "escape --visual" ], desc = "Permanently delete the files" },
    { on = [ "a" ],         run = "create",                  desc = "Create a file or directory (ends with / for directories)" },
    { on = [ "r" ],         run = "rename --cursor=before_ext", desc = "Rename a file or directory" },
    { on = [ ";" ],         run = "shell",                   desc = "Run a shell command" },
    { on = [ ":" ],         run = "shell --block",           desc = "Run a shell command (block the UI until the command finishes)" },
    { on = [ "." ],         run = "hidden toggle",           desc = "Toggle the visibility of hidden files" },
    { on = [ "s" ],         run = "search fd",               desc = "Search files by name using fd" },
    { on = [ "S" ],         run = "search rg",               desc = "Search files by content using ripgrep" },
    { on = [ "<C-s>" ],     run = "search none",             desc = "Cancel the ongoing search" },
    { on = [ "z" ],         run = "jump zoxide",             desc = "Jump to a directory using zoxide" },
    { on = [ "Z" ],         run = "jump fzf",                desc = "Jump to a directory, or reveal a file using fzf" },

    # Linemode
    { on = [ "m", "s" ], run = "linemode size",        desc = "Set linemode to size" },
    { on = [ "m", "p" ], run = "linemode permissions", desc = "Set linemode to permissions" },
    { on = [ "m", "c" ], run = "linemode ctime",       desc = "Set linemode to ctime" },
    { on = [ "m", "m" ], run = "linemode mtime",       desc = "Set linemode to mtime" },
    { on = [ "m", "o" ], run = "linemode owner",       desc = "Set linemode to owner" },
    { on = [ "m", "n" ], run = "linemode none",        desc = "Set linemode to none" },

    # Copy
    { on = [ "c", "c" ], run = "copy path",             desc = "Copy the absolute path" },
    { on = [ "c", "d" ], run = "copy dirname",          desc = "Copy the path of the parent directory" },
    { on = [ "c", "f" ], run = "copy filename",         desc = "Copy the name of the file" },
    { on = [ "c", "n" ], run = "copy name_without_ext", desc = "Copy the name of the file without the extension" },

    # Filter
    { on = [ "f" ], run = "filter --smart", desc = "Filter the files" },

    # Find
    { on = [ "/" ], run = "find --smart",            desc = "Find next file" },
    { on = [ "?" ], run = "find --previous --smart", desc = "Find previous file" },
    { on = [ "n" ], run = "find_arrow",              desc = "Go to next found file" },
    { on = [ "N" ], run = "find_arrow --previous",   desc = "Go to previous found file" },

    # Sorting
    { on = [ ",", "m" ], run = "sort modified --reverse=no",  desc = "Sort by modified time (newest first)" },
    { on = [ ",", "M" ], run = "sort modified --reverse",     desc = "Sort by modified time (oldest first)" },
    { on = [ ",", "c" ], run = "sort created --reverse=no",   desc = "Sort by created time (newest first)" },
    { on = [ ",", "C" ], run = "sort created --reverse",      desc = "Sort by created time (oldest first)" },
    { on = [ ",", "e" ], run = "sort extension --reverse=no", desc = "Sort by extension (a-z)" },
    { on = [ ",", "E" ], run = "sort extension --reverse",    desc = "Sort by extension (z-a)" },
    { on = [ ",", "a" ], run = "sort alphabetical --reverse=no", desc = "Sort alphabetically (a-z)" },
    { on = [ ",", "A" ], run = "sort alphabetical --reverse",    desc = "Sort alphabetically (z-a)" },
    { on = [ ",", "n" ], run = "sort natural --reverse=no",     desc = "Sort naturally (a-z)" },
    { on = [ ",", "N" ], run = "sort natural --reverse",        desc = "Sort naturally (z-a)" },
    { on = [ ",", "s" ], run = "sort size --reverse=no",        desc = "Sort by size (smallest first)" },
    { on = [ ",", "S" ], run = "sort size --reverse",           desc = "Sort by size (largest first)" },

    # Tabs
    { on = [ "t" ], run = "tab_create --current", desc = "Create a new tab using the current path" },

    { on = [ "1" ], run = "tab_switch 0", desc = "Switch to the first tab" },
    { on = [ "2" ], run = "tab_switch 1", desc = "Switch to the second tab" },
    { on = [ "3" ], run = "tab_switch 2", desc = "Switch to the third tab" },
    { on = [ "4" ], run = "tab_switch 3", desc = "Switch to the fourth tab" },
    { on = [ "5" ], run = "tab_switch 4", desc = "Switch to the fifth tab" },
    { on = [ "6" ], run = "tab_switch 5", desc = "Switch to the sixth tab" },
    { on = [ "7" ], run = "tab_switch 6", desc = "Switch to the seventh tab" },
    { on = [ "8" ], run = "tab_switch 7", desc = "Switch to the eighth tab" },
    { on = [ "9" ], run = "tab_switch 8", desc = "Switch to the ninth tab" },

    { on = [ "[" ], run = "tab_switch -1 --relative", desc = "Switch to the previous tab" },
    { on = [ "]" ], run = "tab_switch 1 --relative",  desc = "Switch to the next tab" },

    { on = [ "{" ], run = "tab_swap -1", desc = "Swap the current tab with the previous tab" },
    { on = [ "}" ], run = "tab_swap 1",  desc = "Swap the current tab with the next tab" },

    # Tasks
    { on = [ "w" ], run = "tasks_show", desc = "Show the tasks manager" },

    # Goto
    { on = [ "g", "h" ],       run = "cd ~",             desc = "Go to the home directory" },
    { on = [ "g", "c" ],       run = "cd ~/.config",     desc = "Go to the config directory" },
    { on = [ "g", "d" ],       run = "cd ~/Downloads",   desc = "Go to the downloads directory" },
    { on = [ "g", "t" ],       run = "cd /tmp",          desc = "Go to the temporary directory" },
    { on = [ "g", "<Space>" ], run = "cd --interactive", desc = "Go to a directory interactively" },

    # Help
    { on = [ "~" ], run = "help", desc = "Open help" },
]

[tasks]

keymap = [
    { on = [ "<Esc>" ], run = "close", desc = "Hide the task manager" },
    { on = [ "<C-[>" ], run = "close", desc = "Hide the task manager" },
    { on = [ "<C-c>" ], run = "close", desc = "Hide the task manager" },
    { on = [ "w" ],     run = "close", desc = "Hide the task manager" },

    { on = [ "k" ], run = "arrow -1", desc = "Move cursor up" },
    { on = [ "j" ], run = "arrow 1",  desc = "Move cursor down" },

    { on = [ "<Up>" ],   run = "arrow -1", desc = "Move cursor up" },
    { on = [ "<Down>" ], run = "arrow 1",  desc = "Move cursor down" },

    { on = [ "<Enter>" ], run = "inspect", desc = "Inspect the task" },
    { on = [ "x" ],       run = "cancel",  desc = "Cancel the task" },

    { on = [ "~" ], run = "help", desc = "Open help" }
]

[select]

keymap = [
    { on = [ "<C-c>" ],   run = "close",          desc = "Cancel selection" },
    { on = [ "<Esc>" ],   run = "close",          desc = "Cancel selection" },
    { on = [ "<C-[>" ],   run = "close",          desc = "Cancel selection" },
    { on = [ "<Enter>" ], run = "close --submit", desc = "Submit the selection" },

    { on = [ "k" ], run = "arrow -1", desc = "Move cursor up" },
    { on = [ "j" ], run = "arrow 1",  desc = "Move cursor down" },

    { on = [ "<Up>" ],   run = "arrow -1", desc = "Move cursor up" },
    { on = [ "<Down>" ], run = "arrow 1",  desc = "Move cursor down" },

    { on = [ "~" ], run = "help", desc = "Open help" }
]

[input]

keymap = [
    { on = [ "<C-c>" ],   run = "close",          desc = "Cancel input" },
    { on = [ "<Esc>" ],   run = "close",          desc = "Cancel input" },
    { on = [ "<C-[>" ],   run = "close",          desc = "Cancel input" },
    { on = [ "<Enter>" ], run = "close --submit", desc = "Submit the input" },
    { on = [ "<C-u>" ],   run = "kill bol",       desc = "Kill backwards to the BOL" },

    # Mode
    { on = [ "i" ], run = "insert",                              desc = "Enter insert mode" },
    { on = [ "a" ], run = [ "move bol", "visual", "move eol" ], desc = "Enter append mode" },
    { on = [ "I" ], run = [ "move bol", "visual" ],              desc = "Move to the BOL, and enter visual mode" },
    { on = [ "A" ], run = [ "move eol", "visual" ],              desc = "Move to the EOL, and enter visual mode" },
    { on = [ "v" ], run = "visual",                              desc = "Enter visual mode" },
    { on = [ "V" ], run = [ "move bol", "visual", "move eol" ], desc = "Enter visual mode and select all" },

    # Character-wise movement
    { on = [ "h" ], run = "move -1", desc = "Move back a character" },
    { on = [ "l" ], run = "move 1",  desc = "Move forward a character" },

    { on = [ "<Left>" ],  run = "move -1", desc = "Move back a character" },
    { on = [ "<Right>" ], run = "move 1",  desc = "Move forward a character" },

    { on = [ "<C-b>" ], run = "move -1", desc = "Move back a character" },
    { on = [ "<C-f>" ], run = "move 1",  desc = "Move forward a character" },

    # Word-wise movement
    { on = [ "b" ],     run = "move -1 --in-operating=word",     desc = "Move back to the start of the current or previous word" },
    { on = [ "w" ],     run = "move 1 --in-operating=word",      desc = "Move forward to the start of the next word" },
    { on = [ "e" ],     run = "move 1 --in-operating=word-end",  desc = "Move forward to the end of the current or next word" },
    { on = [ "<A-b>" ], run = "move -1 --in-operating=word",     desc = "Move back to the start of the current or previous word" },
    { on = [ "<A-f>" ], run = "move 1 --in-operating=word-end",  desc = "Move forward to the end of the current or next word" },

    # Line-wise movement
    { on = [ "0" ],     run = "move bol",     desc = "Move to the BOL" },
    { on = [ "$" ],     run = "move eol",     desc = "Move to the EOL" },
    { on = [ "<C-a>" ], run = "move bol",     desc = "Move to the BOL" },
    { on = [ "<C-e>" ], run = "move eol",     desc = "Move to the EOL" },
    { on = [ "<Home>" ], run = "move bol",    desc = "Move to the BOL" },
    { on = [ "<End>" ],  run = "move eol",    desc = "Move to the EOL" },

    # Delete
    { on = [ "<Backspace>" ], run = "backspace",	        desc = "Delete the character before the cursor" },
    { on = [ "<Delete>" ],    run = "backspace --under", desc = "Delete the character under the cursor" },
    { on = [ "<C-h>" ],       run = "backspace",         desc = "Delete the character before the cursor" },
    { on = [ "<C-d>" ],       run = "backspace --under", desc = "Delete the character under the cursor" },

    # Kill
    { on = [ "<C-u>" ], run = "kill bol",      desc = "Kill backwards to the BOL" },
    { on = [ "<C-k>" ], run = "kill eol",      desc = "Kill forwards to the EOL" },
    { on = [ "<C-w>" ], run = "kill backward", desc = "Kill backwards to the start of the current word" },
    { on = [ "<A-d>" ], run = "kill forward",  desc = "Kill forwards to the end of the current word" },

    # Cut/Yank/Paste
    { on = [ "d" ], run = "delete --cut",                              desc = "Cut the selected characters" },
    { on = [ "D" ], run = [ "delete --cut", "move eol" ],              desc = "Cut until the EOL" },
    { on = [ "c" ], run = "delete --cut --insert",                     desc = "Cut the selected characters, and enter insert mode" },
    { on = [ "C" ], run = [ "delete --cut --insert", "move eol" ],     desc = "Cut until the EOL, and enter insert mode" },
    { on = [ "x" ], run = [ "delete --cut", "move 1 --in-operating" ], desc = "Cut the current character" },
    { on = [ "y" ], run = "yank",           desc = "Copy the selected characters" },
    { on = [ "p" ], run = "paste",          desc = "Paste the copied characters after the cursor" },
    { on = [ "P" ], run = "paste --before", desc = "Paste the copied characters before the cursor" },

    # Undo/Redo
    { on = [ "u" ],     run = "undo", desc = "Undo the last operation" },
    { on = [ "<C-r>" ], run = "redo", desc = "Redo the last operation" },

    # Help
    { on = [ "~" ], run = "help", desc = "Open help" }
]

[completion]

keymap = [
    { on = [ "<C-c>" ],   run = "close",                                      desc = "Cancel completion" },
    { on = [ "<Tab>" ],   run = "close --submit",                            desc = "Submit the completion" },
    { on = [ "<Enter>" ], run = [ "close --submit", "close_input --submit" ], desc = "Submit the completion and input" },

    { on = [ "<A-k>" ], run = "arrow -1", desc = "Move cursor up" },
    { on = [ "<A-j>" ], run = "arrow 1",  desc = "Move cursor down" },

    { on = [ "<Up>" ],   run = "arrow -1", desc = "Move cursor up" },
    { on = [ "<Down>" ], run = "arrow 1",  desc = "Move cursor down" },

    { on = [ "~" ], run = "help", desc = "Open help" }
]

[help]

keymap = [
    { on = [ "<Esc>" ], run = "escape", desc = "Clear the filter, or hide the help" },
    { on = [ "<C-[>" ], run = "escape", desc = "Clear the filter, or hide the help" },
    { on = [ "q" ],     run = "close",  desc = "Exit the process" },
    { on = [ "<C-c>" ], run = "close",  desc = "Hide the help" },

    # Navigation
    { on = [ "k" ], run = "arrow -1", desc = "Move cursor up" },
    { on = [ "j" ], run = "arrow 1",  desc = "Move cursor down" },

    { on = [ "<Up>" ],   run = "arrow -1", desc = "Move cursor up" },
    { on = [ "<Down>" ], run = "arrow 1",  desc = "Move cursor down" },

    # Filtering
    { on = [ "/" ], run = "filter", desc = "Apply a filter for the help items" },
]
EOF

    if [ $? -eq 0 ]; then
        log_success "Конфигурация Yazi создана"
        INSTALLED_CONFIGS+=("yazi-config")
        return 0
    else
        log_error "Не удалось создать конфигурацию Yazi"
        FAILED_CONFIGS+=("yazi-config")
        return 1
    fi
}

# Function to test Yazi installation
test_yazi() {
    log_info "Тестирую установку Yazi..."
    
    if command -v yazi &> /dev/null; then
        local version=$(yazi --version 2>/dev/null | head -1)
        log_success "Yazi установлен: $version"
        
        # Test configuration
        if [ -f "$CONFIG_DIR/yazi/yazi.toml" ]; then
            log_success "Конфигурация Yazi найдена"
        else
            log_warning "Конфигурация Yazi не найдена"
        fi
        
        return 0
    else
        log_error "Yazi не найден в PATH"
        return 1
    fi
}

# Function to show usage examples
show_usage_examples() {
    log_info "Примеры использования Yazi:"
    echo ""
    echo -e "${YELLOW}Основные команды:${NC}"
    echo "  yazi                      # открыть Yazi в текущей папке"
    echo "  yazi ~/Documents          # открыть в определенной папке"
    echo "  yazi --cwd-file=/tmp/cwd  # сохранить текущую папку при выходе"
    echo ""
    echo -e "${YELLOW}Горячие клавиши в Yazi:${NC}"
    echo "  j/k или ↑/↓              # навигация вверх/вниз"
    echo "  h/l или ←/→              # вход/выход из папки"
    echo "  Space                    # выбор файла"
    echo "  y                        # копировать"
    echo "  x                        # вырезать"
    echo "  p                        # вставить"
    echo "  d                        # удалить в корзину"
    echo "  a                        # создать файл/папку"
    echo "  r                        # переименовать"
    echo "  .                        # показать/скрыть скрытые файлы"
    echo "  s                        # поиск по имени (fd)"
    echo "  S                        # поиск по содержимому (ripgrep)"
    echo "  z                        # быстрый переход (zoxide)"
    echo "  q                        # выход"
    echo ""
}

# Main installation function
install_yazi() {
    log_info "Начинаю установку Yazi file manager..."
    
    # Required packages
    local packages=(
        "yazi"
        "file"
        "poppler"
        "ffmpegthumbnailer"
        "unar"
        "jq"
        "ripgrep"
        "fzf"
        "zoxide"
        "fd"
    )
    
    # Install packages
    for package in "${packages[@]}"; do
        install_package "$package"
    done
    
    # Create config directory
    mkdir -p "$CONFIG_DIR"
    
    # Create Yazi configuration
    create_yazi_config
    
    # Test installation
    test_yazi
    
    # Show usage examples
    show_usage_examples
    
    log_success "Установка Yazi завершена!"
}

# Function to return installation status
get_install_status() {
    echo "YAZI_INSTALLED_PACKAGES:(${INSTALLED_PACKAGES[*]})"
    echo "YAZI_FAILED_PACKAGES:(${FAILED_PACKAGES[*]})"
    echo "YAZI_INSTALLED_CONFIGS:(${INSTALLED_CONFIGS[*]})"
    echo "YAZI_FAILED_CONFIGS:(${FAILED_CONFIGS[*]})"
}

# Run installation if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_yazi
    get_install_status
fi
