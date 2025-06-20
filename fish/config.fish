if status is-interactive
    # Commands to run in interactive sessions can go here
    fastfetch
end

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

fish_add_path /home/vyantik/.spicetify

# Go environment variables
set --export GOPATH $HOME/go
set --export GOROOT /usr/lib/go
set --export GOPROXY https://proxy.golang.org,direct
set --export PATH $GOPATH/bin $PATH
