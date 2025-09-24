#!/bin/bash

# Define colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting Docker installation on Arch Linux...${NC}"

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}This script must be run as root. Please use sudo.${NC}"
    exit 1
fi

# 1. Update system packages
echo -e "${GREEN}Updating system packages...${NC}"
pacman -Syu --noconfirm || { echo -e "${RED}Failed to update system packages.${NC}"; exit 1; }
echo -e "${GREEN}System packages updated.${NC}"

# 2. Install Docker package
echo -e "${GREEN}Installing Docker package...${NC}"
pacman -S docker --noconfirm || { echo -e "${RED}Failed to install Docker package.${NC}"; exit 1; }
echo -e "${GREEN}Docker package installed.${NC}"

# 3. Install Docker Compose (V2 as a plugin)
echo -e "${GREEN}Installing Docker Compose (V2 plugin)...${NC}"
pacman -S docker-compose --noconfirm || { echo -e "${RED}Failed to install Docker Compose.${NC}"; exit 1; }
echo -e "${GREEN}Docker Compose installed.${NC}"

# 4. Enable and start the Docker daemon
echo -e "${GREEN}Enabling and starting Docker daemon...${NC}"
systemctl enable docker.service || { echo -e "${RED}Failed to enable Docker service.${NC}"; exit 1; }
systemctl start docker.service || { echo -e "${RED}Failed to start Docker service.${NC}"; exit 1; }
echo -e "${GREEN}Docker daemon enabled and started.${NC}"

# 5. Add current user to the 'docker' group to run Docker commands without sudo
# We need to get the original user who ran sudo, not root.
SUDO_USER=${SUDO_USER:-$(whoami)}
echo -e "${GREEN}Adding user '${SUDO_USER}' to the 'docker' group...${NC}"
usermod -aG docker "$SUDO_USER" || { echo -e "${RED}Failed to add user '${SUDO_USER}' to 'docker' group.${NC}"; exit 1; }
echo -e "${GREEN}User '${SUDO_USER}' added to the 'docker' group.${NC}"
echo -e "${YELLOW}You need to log out and log back in (or reboot) for the group changes to take effect.${NC}"

# 6. Verify Docker installation
echo -e "${GREEN}Verifying Docker installation...${NC}"
systemctl status docker --no-pager

echo -e "${GREEN}Docker installation complete!${NC}"
echo -e "${YELLOW}Remember to log out and log back in or reboot for group changes to apply.${NC}"
echo -e "${YELLOW}After logging back in, test Docker with: docker run hello-world${NC}"
echo -e "${YELLOW}Test Docker Compose with: docker compose version${NC}"