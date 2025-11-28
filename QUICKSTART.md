# Pi Dashboard - Quick Start Guide

## Transfer to Raspberry Pi

### Option 1: Using Git (Recommended)
```bash
# On your Raspberry Pi
git clone https://github.com/kelleyblackmore/pi-dashboard.git
cd pi-dashboard
sudo ./install.sh
```

### Option 2: Manual Transfer
If you've packaged the project as a tar.gz file:

```bash
# Transfer the file to your Pi (from your computer)
scp pi-dashboard.tar.gz pi@<pi-ip-address>:/home/pi/

# On the Raspberry Pi
cd /home/pi
tar -xzf pi-dashboard.tar.gz
cd pi-dashboard
sudo ./install.sh
```

## Installation Steps

The `install.sh` script will:
1. Update system packages
2. Install Python dependencies
3. Install the pi-dashboard package
4. Configure systemd services
5. Set up auto-start and kiosk mode
6. Optionally run boot optimization
7. Optionally configure power management
8. Optionally set up read-only filesystem

## Post-Installation

After installation and reboot, the dashboard will:
- Auto-start on boot
- Display in fullscreen kiosk mode
- Be accessible at `http://localhost:5000`

## Manual Testing

To test before installing as a service:

```bash
# Install dependencies
sudo apt-get update
sudo apt-get install python3 python3-pip

# Install the package
pip3 install -e .

# Run the dashboard
pi-dashboard -v

# Access at http://<pi-ip>:5000
```

## Troubleshooting

### View logs
```bash
sudo journalctl -u pi-dashboard -f
```

### Restart service
```bash
sudo systemctl restart pi-dashboard
```

### Stop service
```bash
sudo systemctl stop pi-dashboard
```

### Check service status
```bash
sudo systemctl status pi-dashboard
```

## Remote Updates

After initial installation, use Ansible for remote updates:

```bash
# On your computer
cd pi-dashboard
ansible-playbook -i ansible/inventory.yml ansible/update.yml
```

## Configuration

Edit configuration at:
- `/etc/pi-dashboard/config.json`

After changes, restart the service:
```bash
sudo systemctl restart pi-dashboard
```
