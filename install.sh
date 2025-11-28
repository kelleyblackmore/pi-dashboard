#!/bin/bash
#
# Pi Dashboard Installation Script
# Installs and configures the Pi Dashboard system
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

INSTALL_DIR="/opt/pi-dashboard"
CONFIG_DIR="/etc/pi-dashboard"
LOG_DIR="/var/log/pi-dashboard"

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "\n${BLUE}==== $1 ====${NC}\n"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "Please run as root (use sudo)"
    exit 1
fi

# Check if running on Raspberry Pi
if ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
    log_warn "This doesn't appear to be a Raspberry Pi"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

cat << "EOF"
╔═══════════════════════════════════════════╗
║                                           ║
║        Pi Dashboard Installer             ║
║        Version 0.1.0                      ║
║                                           ║
╚═══════════════════════════════════════════╝
EOF

echo ""
log_info "This script will install the Pi Dashboard system"
log_info "Installation directory: $INSTALL_DIR"
echo ""

# Confirm installation
read -p "Do you want to continue? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Installation cancelled"
    exit 0
fi

# Update system
log_step "Updating System"
log_info "Updating package lists..."
apt-get update -qq

log_info "Upgrading packages..."
apt-get upgrade -y -qq

# Install dependencies
log_step "Installing Dependencies"
log_info "Installing Python and system packages..."
apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    git \
    chromium-browser \
    unclutter \
    x11-xserver-utils \
    xinit \
    openbox \
    watchdog \
    > /dev/null 2>&1

log_info "Dependencies installed successfully"

# Create directories
log_step "Creating Directories"
mkdir -p "$INSTALL_DIR"
mkdir -p "$CONFIG_DIR"
mkdir -p "$LOG_DIR"
chown pi:pi "$LOG_DIR"

# Copy files if running from repo
log_step "Installing Pi Dashboard"
if [ -f "setup.py" ] && [ -f "pyproject.toml" ]; then
    log_info "Installing from local repository..."
    pip3 install -e . > /dev/null 2>&1
    
    # Copy files to install directory
    cp -r . "$INSTALL_DIR/"
    chown -R pi:pi "$INSTALL_DIR"
else
    log_error "setup.py not found. Please run this script from the pi-dashboard directory"
    exit 1
fi

# Configure system
log_step "Configuring Dashboard"

# Copy default config
if [ ! -f "$CONFIG_DIR/config.json" ]; then
    log_info "Creating default configuration..."
    cp "$INSTALL_DIR/config/default.json" "$CONFIG_DIR/config.json"
    chown pi:pi "$CONFIG_DIR/config.json"
else
    log_info "Config file already exists, skipping"
fi

# Install systemd services
log_step "Installing System Services"
log_info "Installing pi-dashboard service..."
cp "$INSTALL_DIR/systemd/pi-dashboard.service" /etc/systemd/system/
cp "$INSTALL_DIR/systemd/pi-dashboard-shutdown.service" /etc/systemd/system/
cp "$INSTALL_DIR/scripts/pi-dashboard-shutdown" /usr/local/bin/
chmod +x /usr/local/bin/pi-dashboard-shutdown

systemctl daemon-reload
systemctl enable pi-dashboard.service
systemctl enable pi-dashboard-shutdown.service

log_info "Services installed and enabled"

# Run system configuration scripts
log_step "Optimizing System Configuration"
log_info "This will optimize boot time and power management"
echo ""
read -p "Run boot optimization? (Y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    bash "$INSTALL_DIR/scripts/boot-optimization.sh"
fi

echo ""
read -p "Run power management setup? (Y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    bash "$INSTALL_DIR/scripts/power-management.sh"
fi

echo ""
read -p "Enable read-only filesystem? (y/N) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    bash "$INSTALL_DIR/scripts/readonly-fs.sh"
fi

# Configure auto-start on boot
log_step "Configuring Auto-Start"
log_info "Setting up kiosk mode for touchscreen..."

# Create autostart directory for pi user
mkdir -p /home/pi/.config/openbox
cat > /home/pi/.config/openbox/autostart <<EOF
# Disable screen blanking
xset s off
xset -dpms
xset s noblank

# Hide cursor
unclutter -idle 0.1 &

# Start Chromium in kiosk mode
chromium-browser --kiosk --noerrdialogs --disable-infobars --disable-session-crashed-bubble http://localhost:5000 &
EOF

chown -R pi:pi /home/pi/.config

# Enable auto-login
log_info "Configuring auto-login..."
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin pi --noclear %I \$TERM
EOF

# Auto-startx
if ! grep -q "startx" /home/pi/.bash_profile 2>/dev/null; then
    log_info "Configuring auto-start X server..."
    cat >> /home/pi/.bash_profile <<EOF

# Auto-start X server on login
if [ -z "\$DISPLAY" ] && [ "\$(tty)" = "/dev/tty1" ]; then
    startx
fi
EOF
    chown pi:pi /home/pi/.bash_profile
fi

# Set up SSH for remote access
log_step "Enabling Remote Access"
log_info "Enabling SSH for remote updates..."
systemctl enable ssh
systemctl start ssh

log_info "Configuring firewall for SSH and dashboard..."
# Basic firewall rules (if ufw is available)
if command -v ufw >/dev/null 2>&1; then
    ufw allow 22/tcp   # SSH
    ufw allow 5000/tcp # Dashboard
fi

# Installation complete
log_step "Installation Complete!"
echo ""
log_info "Pi Dashboard has been installed successfully!"
echo ""
log_info "Configuration file: $CONFIG_DIR/config.json"
log_info "Log directory: $LOG_DIR"
echo ""
log_info "To start the dashboard manually:"
log_info "  sudo systemctl start pi-dashboard"
echo ""
log_info "To view logs:"
log_info "  sudo journalctl -u pi-dashboard -f"
echo ""
log_warn "A reboot is recommended for all changes to take effect"
echo ""
read -p "Reboot now? (Y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    log_info "Rebooting in 5 seconds..."
    sleep 5
    reboot
else
    log_info "Please reboot manually when ready"
fi
