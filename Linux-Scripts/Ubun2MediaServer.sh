#!/bin/bash

# Define variables
USER="media"
HOME_DIR="/home/$USER"

# Function to check if a command is available
command_exists() {
    command -v "$1" &> /dev/null
}

# List of dependencies to check
DEPENDENCIES=(
    "curl"
    "git"
    "lsb-release"
    "ca-certificates"
    "apt-transport-https"
    "software-properties-common"
    "docker"
    "jq"
)

MISSING_DEPENDENCIES=()

# Check each dependency
for DEP in "${DEPENDENCIES[@]}"; do
    if ! command_exists "$DEP"; then
        MISSING_DEPENDENCIES+=("$DEP")
    fi
done

# If there are missing dependencies, ask the user for confirmation
if [ ${#MISSING_DEPENDENCIES[@]} -gt 0 ]; then
    echo "The following dependencies are missing or outdated:"
    for dep in "${MISSING_DEPENDENCIES[@]}"; do
        echo "- $dep"
    done
    
    read -p "Do you want to install the missing dependencies? (y/n): " INSTALL_CONFIRMATION
    
    if [[ "$INSTALL_CONFIRMATION" =~ ^[Yy]$ ]]; then
        echo "Updating package lists and upgrading existing packages..."
        sudo apt update && sudo apt upgrade -y
        
        # Install missing dependencies
        for DEP in "${MISSING_DEPENDENCIES[@]}"; do
            case "$DEP" in
                "curl")
                    echo "Installing curl..."
                    sudo apt install -y curl
                ;;
                "git")
                    echo "Installing git..."
                    sudo apt install -y git
                ;;
                "lsb-release")
                    echo "Installing lsb-release..."
                    sudo apt install -y lsb-release
                ;;
                "ca-certificates")
                    echo "Installing ca-certificates..."
                    sudo apt install -y ca-certificates
                ;;
                "apt-transport-https")
                    echo "Installing apt-transport-https..."
                    sudo apt install -y apt-transport-https
                ;;
                "software-properties-common")
                    echo "Installing software-properties-common..."
                    sudo apt install -y software-properties-common
                ;;
                "docker")
                    echo "Installing Docker..."
                    sudo apt install -y docker.io
                ;;
                "jq")
                    echo "Installing jq..."
                    sudo apt install -y jq
                ;;
                *)
                    echo "Unknown dependency: $DEP"
                ;;
            esac
        done
    else
        echo "Skipping installation of missing dependencies. The setup cannot proceed without them."
        exit 1
    fi
else
    echo "All required dependencies are already installed."
fi

# Add current user to Docker group if not already added
if ! groups $USER | grep -q "\bdocker\b"; then
    echo "Adding $USER to the docker group..."
    sudo usermod -aG docker $USER
else
    echo "$USER is already in the docker group."
fi

# Create media user if not exists
if ! id -u $USER &>/dev/null; then
    echo "Creating media user..."
    sudo useradd -m $USER
else
    echo "Media user already exists."
fi

# Create necessary directories if they don't exist
mkdir -p $HOME_DIR/data/torrents/tmp
mkdir -p $HOME_DIR/data/torrents/movies
mkdir -p $HOME_DIR/data/torrents/tv
mkdir -p $HOME_DIR/data/media/movies
mkdir -p $HOME_DIR/data/media/tv

# Set correct ownership for the media user
sudo chown -R $USER:$USER $HOME_DIR

# Create Docker Compose file
cat <<EOF > $HOME_DIR/docker-compose.yml
services:
  qbittorrent:
    image: linuxserver/qbittorrent
    container_name: qbittorrent
    environment:
      - WEBUI_PORT=8080
      - USERNAME=admin
      - PASSWORD=admin
    volumes:
      - $HOME_DIR/data/torrents:/downloads
      - $HOME_DIR/data/torrents/tmp:/tmp
    ports:
      - 8080:8080
    restart: unless-stopped

  radarr:
    image: linuxserver/radarr
    container_name: radarr
    volumes:
      - $HOME_DIR/data/media/movies:/movies
      - $HOME_DIR/data/torrents:/downloads
    ports:
      - 7878:7878
    restart: unless-stopped

  sonarr:
    image: linuxserver/sonarr
    container_name: sonarr
    volumes:
      - $HOME_DIR/data/media/tv:/tv
      - $HOME_DIR/data/torrents:/downloads
    ports:
      - 8989:8989
    restart: unless-stopped

  jackett:
    image: linuxserver/jackett
    container_name: jackett
    volumes:
      - $HOME_DIR/data/jackett:/config
    ports:
      - 9117:9117
    restart: unless-stopped
EOF

# Change permissions of docker-compose.yml
sudo chown $USER:$USER $HOME_DIR/docker-compose.yml

# Prompt to start Docker containers
read -p "Do you want to start the Docker containers now? (y/n): " START_CONTAINERS

if [[ "$START_CONTAINERS" =~ ^[Yy]$ ]]; then
    # Start Docker containers
    sudo -u $USER docker-compose -f $HOME_DIR/docker-compose.yml up -d
    echo "Docker containers started."
else
    echo "Docker containers were not started."
    echo "To start the containers manually, run the following command:"
    echo "  sudo -u $USER docker-compose -f $HOME_DIR/docker-compose.yml up -d"
fi

# DNS Setup instructions
echo "Please set up local DNS records for:"
echo "Torrents.local -> <server-ip>:8080"
echo "Radarr.local -> <server-ip>:7878"
echo "Sonarr.local -> <server-ip>:8989"
echo "Jackett.local -> <server-ip>:9117"

echo "Setup complete. Your Seedbox/Media server is now ready."

echo "For more information, visit the github page here:"
echo "!!INSERT GITHUB LINK!!"
