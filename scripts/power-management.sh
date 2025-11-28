#!/bin/bash
#
# Power Management Script for Pi Dashboard
# Configures power management for vehicle environment
#

set -e

echo "=== Pi Dashboard Power Management Setup ==="
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

# Install power monitoring tools
log_info "Installing power management tools..."
apt-get update -qq
apt-get install -y -qq watchdog > /dev/null 2>&1 || log_warn "Could not install watchdog"

# Configure watchdog
log_info "Configuring hardware watchdog..."
if ! grep -q "^dtparam=watchdog=on" /boot/config.txt; then
    echo "dtparam=watchdog=on" >> /boot/config.txt
    log_info "  Enabled hardware watchdog in boot config"
fi

# Set up watchdog daemon
cat > /etc/watchdog.conf <<EOF
# Pi Dashboard Watchdog Configuration
watchdog-device = /dev/watchdog
watchdog-timeout = 15
realtime = yes
priority = 1

# Check if dashboard is running
pidfile = /var/run/pi-dashboard.pid

# System checks
max-load-1 = 24
EOF

systemctl enable watchdog 2>/dev/null || log_warn "Could not enable watchdog service"

# Create power monitoring script
log_info "Creating power monitoring script..."
cat > /usr/local/bin/pi-dashboard-power-monitor <<'EOF'
#!/bin/bash
#
# Monitor power state and trigger graceful shutdown if needed
# This is a placeholder - in production, you would monitor GPIO pins
# connected to your vehicle's ignition signal
#

SHUTDOWN_DELAY=30
LOG_FILE="/var/log/pi-dashboard/power.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# TODO: Implement actual power monitoring
# For now, this is a template

# Example: Monitor GPIO pin for ignition signal
# while true; do
#     if [ "$(gpio read 17)" -eq 0 ]; then
#         log "Ignition off detected, starting shutdown sequence"
#         sleep $SHUTDOWN_DELAY
#         if [ "$(gpio read 17)" -eq 0 ]; then
#             log "Initiating shutdown"
#             systemctl poweroff
#         fi
#     fi
#     sleep 1
# done

log "Power monitor started (placeholder mode)"
EOF

chmod +x /usr/local/bin/pi-dashboard-power-monitor

# Create systemd service for power monitoring
log_info "Creating power monitoring service..."
cat > /etc/systemd/system/pi-dashboard-power.service <<EOF
[Unit]
Description=Pi Dashboard Power Monitor
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/local/bin/pi-dashboard-power-monitor
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Enable but don't start (needs GPIO configuration)
systemctl daemon-reload
systemctl enable pi-dashboard-power.service 2>/dev/null || log_warn "Could not enable power monitor"

# Configure clean shutdown on power loss
log_info "Configuring UPS/power loss handling..."
cat > /etc/systemd/system/ups-shutdown.service <<EOF
[Unit]
Description=UPS Shutdown Handler
DefaultDependencies=no
Before=shutdown.target

[Service]
Type=oneshot
ExecStart=/bin/sync
RemainAfterExit=yes

[Install]
WantedBy=halt.target poweroff.target
EOF

systemctl enable ups-shutdown.service 2>/dev/null

# Optimize power settings
log_info "Optimizing power settings..."

# Disable HDMI timeout (we'll manage it)
if ! grep -q "hdmi_blanking=1" /boot/config.txt; then
    echo "hdmi_blanking=1" >> /boot/config.txt
fi

# Set up log directory
mkdir -p /var/log/pi-dashboard
chown pi:pi /var/log/pi-dashboard

echo ""
log_info "Power management setup complete!"
log_warn "NOTE: GPIO power monitoring is not yet configured"
log_info "Edit /usr/local/bin/pi-dashboard-power-monitor to add your GPIO logic"
echo ""
