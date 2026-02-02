#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║   ₿  OpenClaw + aibtc VPS Setup                           ║"
echo "║                                                           ║"
echo "║   Bitcoin & Stacks blockchain agent for your VPS          ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo -e "${RED}Cannot detect OS. Please install Docker manually.${NC}"
    exit 1
fi

echo -e "${BLUE}Detected OS: ${OS}${NC}"

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
else
    SUDO=""
fi

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}Docker not found. Installing...${NC}"

    case $OS in
        ubuntu|debian)
            $SUDO apt-get update
            $SUDO apt-get install -y ca-certificates curl gnupg
            $SUDO install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/$OS/gpg | $SUDO gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            $SUDO chmod a+r /etc/apt/keyrings/docker.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$OS $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null
            $SUDO apt-get update
            $SUDO apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        centos|rhel|fedora)
            $SUDO dnf -y install dnf-plugins-core
            $SUDO dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            $SUDO dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        *)
            echo -e "${YELLOW}Attempting generic Docker install...${NC}"
            curl -fsSL https://get.docker.com | $SUDO sh
            ;;
    esac

    # Start and enable Docker
    $SUDO systemctl start docker
    $SUDO systemctl enable docker

    # Add current user to docker group if not root
    if [ "$EUID" -ne 0 ]; then
        $SUDO usermod -aG docker $USER
        echo -e "${YELLOW}Added $USER to docker group. You may need to log out and back in.${NC}"
    fi

    echo -e "${GREEN}✓ Docker installed successfully${NC}"
else
    echo -e "${GREEN}✓ Docker is already installed${NC}"
fi

# Check Docker is running
if ! docker info &> /dev/null; then
    $SUDO systemctl start docker
fi

# Install git if not present
if ! command -v git &> /dev/null; then
    echo -e "${YELLOW}Installing git...${NC}"
    case $OS in
        ubuntu|debian)
            $SUDO apt-get install -y git
            ;;
        centos|rhel|fedora)
            $SUDO dnf install -y git
            ;;
    esac
fi

# Determine install directory
if [ "$EUID" -eq 0 ]; then
    INSTALL_DIR="/opt/openclaw-aibtc"
else
    INSTALL_DIR="$HOME/openclaw-aibtc"
fi

# Clone or update repo
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}Found existing installation at $INSTALL_DIR${NC}"
    read -p "Update existing installation? (y/N): " UPDATE
    if [[ "$UPDATE" =~ ^[Yy]$ ]]; then
        cd "$INSTALL_DIR"
        git pull
    fi
else
    echo -e "${BLUE}Cloning repository...${NC}"
    git clone https://github.com/biwasxyz/openclaw-aibtc.git "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"

# Run the main setup script
echo -e "${BLUE}Running setup...${NC}"
./setup.sh

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   VPS Setup Complete!                                     ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Installation directory: ${YELLOW}$INSTALL_DIR${NC}"
echo ""
echo -e "${BLUE}Useful commands:${NC}"
echo "  cd $INSTALL_DIR"
echo "  docker compose logs -f     # View logs"
echo "  docker compose restart     # Restart"
echo "  docker compose down        # Stop"
echo ""
