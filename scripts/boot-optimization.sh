#!/bin/bash
#
# Boot Optimization Script for Pi Dashboard
# Optimizes Raspberry Pi boot time for quick startup in vehicle
#

set -e

echo "=== Pi Dashboard Boot Optimization ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "Please run as root (use sudo)"
    exit 1
fi

# Disable unnecessary services
log_info "Disabling unnecessary services..."
SERVICES_TO_DISABLE=(
    "bluetooth.service"
    "hciuart.service"
    "triggerhappy.service"
    "avahi-daemon.service"
    "apt-daily.timer"
    "apt-daily-upgrade.timer"
)

for service in "${SERVICES_TO_DISABLE[@]}"; do
    if systemctl is-enabled "$service" 2>/dev/null | grep -q "enabled"; then
        log_info "  Disabling $service"
        systemctl disable "$service" 2>/dev/null || log_warn "  Could not disable $service"
    fi
done

# Optimize boot config
log_info "Optimizing /boot/config.txt..."
CONFIG_FILE="/boot/config.txt"

# Backup original config
if [ ! -f "${CONFIG_FILE}.bak" ]; then
    cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"
    log_info "  Backed up original config to ${CONFIG_FILE}.bak"
fi

# Add boot optimizations
cat >> "$CONFIG_FILE" <<EOF

# Pi Dashboard Boot Optimizations
# Disable rainbow splash
disable_splash=1

# Reduce boot delay
boot_delay=0

# Disable Bluetooth (if not needed)
dtoverlay=disable-bt

# Set GPU memory (adjust as needed for video)
gpu_mem=128

# Disable audio if not needed (uncomment if needed for media)
# dtparam=audio=off
EOF

log_info "  Boot config optimized"

# Optimize cmdline.txt for faster boot
log_info "Optimizing /boot/cmdline.txt..."
CMDLINE_FILE="/boot/cmdline.txt"

if [ ! -f "${CMDLINE_FILE}.bak" ]; then
    cp "$CMDLINE_FILE" "${CMDLINE_FILE}.bak"
    log_info "  Backed up original cmdline to ${CMDLINE_FILE}.bak"
fi

# Remove quiet and add loglevel=3 for faster boot
sed -i 's/quiet //g' "$CMDLINE_FILE"
sed -i 's/splash //g' "$CMDLINE_FILE"

if ! grep -q "loglevel=3" "$CMDLINE_FILE"; then
    sed -i 's/$/ loglevel=3/' "$CMDLINE_FILE"
fi

# Disable HDMI on boot to save time (will be enabled by dashboard)
log_info "Setting up fast boot sequence..."
cat > /usr/local/bin/pi-dashboard-boot <<'EOF'
#!/bin/bash
# Fast boot script for Pi Dashboard
# Turn on HDMI
tvservice -p
fbset -depth 8
fbset -depth 16
EOF

chmod +x /usr/local/bin/pi-dashboard-boot

# Enable filesystem optimizations
log_info "Optimizing filesystem..."
if ! grep -q "noatime" /etc/fstab; then
    sed -i 's/defaults/defaults,noatime/g' /etc/fstab
    log_info "  Added noatime to fstab"
fi

# Set up journald for reduced writes
log_info "Configuring systemd journal..."
mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/pi-dashboard.conf <<EOF
[Journal]
Storage=volatile
RuntimeMaxUse=10M
EOF

log_info "  Journal configured for RAM storage"

# Disable swapping (optional, saves SD card writes)
log_info "Disabling swap..."
dphys-swapfile swapoff 2>/dev/null || true
dphys-swapfile uninstall 2>/dev/null || true
systemctl disable dphys-swapfile 2>/dev/null || log_warn "  Could not disable swap"

echo ""
log_info "Boot optimization complete!"
log_warn "A reboot is required for changes to take effect"
echo ""
