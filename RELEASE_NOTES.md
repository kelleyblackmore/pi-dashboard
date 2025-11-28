# Pi Dashboard v0.1.0 - Initial Release

## 🚗 Passenger Dashboard System for Raspberry Pi 4

A comprehensive entertainment and information dashboard designed for in-vehicle use with a 7" touchscreen display.

### ✨ Features

- **Touch-Optimized UI** - Beautiful, responsive interface designed for 800x480 touchscreens
- **System Monitoring** - Real-time CPU, memory, disk, and temperature monitoring
- **Auto-Start** - Boots directly into kiosk mode on vehicle startup
- **Power Management** - Handles frequent on/off cycles with graceful shutdown
- **Boot Optimization** - Fast boot time (<10 seconds target)
- **Remote Updates** - Deploy updates via Ansible over the internet
- **SD Card Protection** - Optional read-only filesystem to prevent corruption
- **Modular Architecture** - Easy to extend with additional modules

### 📦 Installation

#### Quick Install (On Raspberry Pi)

```bash
# Clone the repository
git clone https://github.com/kelleyblackmore/pi-dashboard.git
cd pi-dashboard

# Run the installer
sudo ./install.sh

# Reboot when prompted
```

#### Or Download Release Package

```bash
# Download the release
wget https://github.com/kelleyblackmore/pi-dashboard/releases/download/v0.1.0/pi-dashboard-0.1.0.tar.gz

# Extract
tar -xzf pi-dashboard-0.1.0.tar.gz
cd pi-dashboard-0.1.0

# Install
sudo ./install.sh
```

### 🎯 What's Included

- ✅ Flask-based web server with Socket.IO
- ✅ Touch-friendly dashboard interface
- ✅ System monitoring module
- ✅ Systemd services for auto-start
- ✅ Boot optimization scripts
- ✅ Power management configuration
- ✅ Ansible playbooks for remote deployment
- ✅ Kiosk mode setup (Chromium fullscreen)
- 🔲 Camera module (placeholder)
- 🔲 Media player module (placeholder)

### 🔧 Requirements

- Raspberry Pi 4 (4GB or 8GB RAM recommended)
- 7" touchscreen display (800x480)
- Raspberry Pi OS (Bullseye or newer)
- Python 3.9+
- Internet connection (for initial setup and updates)

### 📖 Documentation

- [README.md](README.md) - Full documentation
- [QUICKSTART.md](QUICKSTART.md) - Quick start guide

### 🐛 Known Issues

- Camera and media modules are placeholders (implementation in progress)
- System stats may not display on non-Pi systems

### 🚀 Coming Soon

- Full camera feed implementation
- Video/audio media player
- Weather module
- Navigation integration
- Music player

---

**Full Changelog**: https://github.com/kelleyblackmore/pi-dashboard/commits/v0.1.0
