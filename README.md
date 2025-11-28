# Pi Dashboard

A comprehensive passenger dashboard system for Raspberry Pi 4, designed to provide an interactive in-car entertainment and information display.

## Overview

Pi Dashboard is a versatile platform that transforms your Raspberry Pi 4 into a feature-rich passenger entertainment system. Whether you're on a road trip or commuting, this dashboard provides camera feeds, media playback, system monitoring, and extensible functionality for additional features like weather information.

## Features

### Core Functionality
- 📹 **Camera Feeds** - Display live camera feeds from connected cameras
- 🎬 **Media Player** - Watch movies and videos with an intuitive interface
- 📊 **System Monitor** - Real-time monitoring of Raspberry Pi system stats (CPU, memory, temperature, etc.)
- 🌐 **Extensible Architecture** - Easily add custom modules and widgets

### Planned Extensions
- ☁️ Weather information and forecasts
- 🎵 Music player integration
- 🗺️ Navigation and GPS tracking
- 📱 Mobile device connectivity
- 🎮 Games and interactive content

## Hardware Requirements

- **Raspberry Pi 4** (4GB or 8GB RAM recommended)
- **Display** - Touch screen or HDMI-compatible monitor
- **Storage** - microSD card (32GB+ recommended) - Industrial grade recommended for frequent power cycles
- **Power Supply** - Official Raspberry Pi 4 power adapter or 12V car adapter with proper voltage regulation
- **UPS/Power Management** - Recommended to handle clean shutdowns and power fluctuations
- **Optional**: USB cameras, external storage, cooling fan

### Important: Vehicle Power Considerations

Since this dashboard will be subject to frequent power cycles from the vehicle ignition, special consideration must be given to:
- **Graceful shutdown handling** to prevent SD card corruption
- **Fast boot optimization** for quick startup when the vehicle starts
- **Power state detection** to trigger proper shutdown sequences
- **File system protection** using read-only modes where appropriate

## Software Requirements

- Raspberry Pi OS (Bullseye or newer)
- Python 3.9+
- Node.js 16+ (for web-based UI)
- Required dependencies (see Installation section)

## Installation

### Initial Installation (Manual)

First-time installation requires direct access to the Raspberry Pi:

```bash
# On the Raspberry Pi
git clone https://github.com/kelleyblackmore/pi-dashboard.git
cd pi-dashboard

# Run the installer
sudo ./install.sh

# The installer will:
# - Install the pi-dashboard package
# - Configure systemd services for auto-start
# - Set up power management and graceful shutdown
# - Optimize boot time
# - Configure display settings
# - Set up read-only file system (optional)
# - Enable remote update capability via Ansible
```

### Remote Updates (Ansible)

After initial installation, updates can be deployed remotely over the internet:

```bash
# On your control machine
cd pi-dashboard

# Configure your Raspberry Pi in the inventory (one-time setup)
nano ansible/inventory.yml

# Deploy updates remotely
ansible-playbook -i ansible/inventory.yml ansible/deploy.yml

# Or update just the application code
ansible-playbook -i ansible/inventory.yml ansible/update.yml

# Or update system configuration
ansible-playbook -i ansible/inventory.yml ansible/configure.yml
```

The Ansible playbooks can:
- Update the dashboard application without touching system config
- Apply new system configurations
- Deploy configuration changes
- Restart services as needed
- Perform full reinstallation if required

### Post-Installation

After installation, the dashboard will:
- Start automatically on boot
- Handle graceful shutdowns when power is lost
- Be accessible via the connected display or web interface

## Configuration

Configuration options will include:
- Display resolution and orientation
- Camera feed sources and layouts
- Media library paths
- System monitoring intervals
- Module enablement/disablement
- Power management settings (shutdown delays, boot behavior)
- File system protection modes

## Project Structure

```
pi-dashboard/
├── README.md
├── setup.py          # Package installation configuration
├── pyproject.toml    # Modern Python package metadata
├── install.sh        # System installer script
├── ansible/          # Ansible deployment
│   ├── deploy.yml    # Main playbook
│   ├── inventory.yml # Inventory template
│   ├── roles/
│   │   ├── pi-dashboard/
│   │   ├── boot-optimization/
│   │   ├── power-management/
│   │   └── system-config/
│   └── group_vars/
├── src/
│   └── pi_dashboard/ # Main package source code
│       ├── __init__.py
│       ├── main.py
│       ├── camera/
│       ├── media/
│       ├── system/
│       └── modules/  # Extensible modules (weather, etc.)
├── config/
│   ├── config.example.json
│   └── default.json
├── systemd/          # Systemd service files
│   ├── pi-dashboard.service
│   └── pi-dashboard-shutdown.service
├── scripts/          # System configuration scripts
│   ├── boot-optimization.sh
│   ├── power-management.sh
│   └── readonly-fs.sh
├── static/           # Static assets (CSS, JS, images)
├── media/            # Media library
└── docs/             # Documentation
```

## Development

This project is under active development. Contributions are welcome!

### Roadmap
- [ ] **Package and installation system**
  - [ ] setup.py and pyproject.toml configuration
  - [ ] Automated installer script
  - [ ] Systemd service configuration
  - [ ] System configuration scripts
- [ ] Core UI framework setup
- [ ] Camera feed integration
- [ ] Media player implementation
- [ ] System monitoring dashboard
- [ ] Module system architecture
- [ ] Weather module
- [ ] Touch screen optimization
- [ ] **Power management and boot optimization**
  - [ ] Fast boot configuration (<10 seconds)
  - [ ] Graceful shutdown on power loss detection
  - [ ] SD card corruption prevention
  - [ ] Auto-start on boot via systemd
  - [ ] Read-only file system configuration
  - [ ] State persistence across reboots

## Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the issues page.

## License

MIT License - see [LICENSE](LICENSE) file for details

## Acknowledgments

Built for Raspberry Pi enthusiasts who want to enhance their in-car experience.

---

**Note**: This project is currently in early development. Features and documentation will be updated as the project progresses.