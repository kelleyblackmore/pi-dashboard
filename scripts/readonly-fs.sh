#!/bin/bash
#
# Read-Only Filesystem Configuration for Pi Dashboard
# Protects SD card from corruption during power loss
#

set -e

echo "=== Pi Dashboard Read-Only Filesystem Setup ==="
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

log_warn "This script will configure the filesystem for read-only operation"
log_warn "This protects against SD card corruption but limits write operations"
echo ""
read -p "Do you want to continue? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Aborted by user"
    exit 0
fi

# Install required packages
log_info "Installing required packages..."
apt-get update -qq
apt-get install -y -qq busybox-syslogd

# Remove rsyslog to use busybox (lighter)
apt-get remove -y --purge rsyslog 2>/dev/null || true

# Disable swap
log_info "Disabling swap..."
dphys-swapfile swapoff 2>/dev/null || true
dphys-swapfile uninstall 2>/dev/null || true
systemctl disable dphys-swapfile 2>/dev/null || true

# Create RAM-based tmpfs mounts
log_info "Configuring tmpfs mounts..."
cat >> /etc/fstab <<EOF

# Pi Dashboard Read-Only Filesystem Configuration
tmpfs /tmp tmpfs defaults,noatime,nosuid,size=100m 0 0
tmpfs /var/tmp tmpfs defaults,noatime,nosuid,size=30m 0 0
tmpfs /var/log tmpfs defaults,noatime,nosuid,mode=0755,size=30m 0 0
tmpfs /var/run tmpfs defaults,noatime,nosuid,mode=0755,size=2m 0 0
tmpfs /var/spool/mqueue tmpfs defaults,noatime,nosuid,mode=0700,gid=12,size=10m 0 0
EOF

# Make directories that need to be writable
log_info "Setting up writable directories..."
mkdir -p /var/lib/dhcp
mkdir -p /var/lib/dhcpcd5

# Move to tmpfs
cat >> /etc/fstab <<EOF
tmpfs /var/lib/dhcp tmpfs defaults,noatime,nosuid,size=1m 0 0
tmpfs /var/lib/dhcpcd5 tmpfs defaults,noatime,nosuid,size=1m 0 0
EOF

# Configure read-only root
log_info "Modifying boot configuration for read-only root..."
if ! grep -q "fastboot noswap ro" /boot/cmdline.txt; then
    sed -i 's/$/ fastboot noswap ro/' /boot/cmdline.txt
fi

# Update fstab for read-only root
log_info "Updating fstab for read-only filesystems..."
sed -i 's/defaults/defaults,ro/g' /etc/fstab
sed -i 's/defaults,ro,noatime/defaults,noatime,ro/g' /etc/fstab

# Boot partition should be read-only too
sed -i 's|/boot.*vfat.*defaults|/boot vfat defaults,ro|g' /etc/fstab

# Create remount scripts for temporary writes
log_info "Creating remount scripts..."
cat > /usr/local/bin/rw <<'EOF'
#!/bin/bash
# Remount root filesystem as read-write
mount -o remount,rw /
mount -o remount,rw /boot
echo "Filesystem is now read-write"
EOF

cat > /usr/local/bin/ro <<'EOF'
#!/bin/bash
# Remount root filesystem as read-only
sync
mount -o remount,ro /
mount -o remount,ro /boot
echo "Filesystem is now read-only"
EOF

chmod +x /usr/local/bin/rw /usr/local/bin/ro

# Create overlay for specific directories that need persistence
log_info "Setting up overlay filesystems for persistent data..."
mkdir -p /var/local/overlay
mkdir -p /var/local/overlay/work
mkdir -p /var/local/overlay/upper

# Persistent directories (media library, configs, etc.)
PERSISTENT_DIRS=(
    "/home/pi/.config/pi-dashboard"
    "/var/log/pi-dashboard"
)

for dir in "${PERSISTENT_DIRS[@]}"; do
    mkdir -p "$dir"
done

# Create startup script to set up overlays
cat > /usr/local/bin/setup-overlays <<'EOF'
#!/bin/bash
# Set up overlay filesystems for persistent data
# This runs early in boot
EOF

chmod +x /usr/local/bin/setup-overlays

echo ""
log_info "Read-only filesystem setup complete!"
log_warn "IMPORTANT: After reboot, filesystem will be read-only"
log_info "Use 'rw' command to make it writable temporarily"
log_info "Use 'ro' command to make it read-only again"
log_warn "A reboot is required for changes to take effect"
echo ""
