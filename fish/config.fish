if status is-interactive
    # Commands to run in interactive sessions can go here
    fastfetch
end

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

fish_add_path /home/vyantik/.spicetify
