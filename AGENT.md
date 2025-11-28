# Pi Dashboard Development Guide

## Project Overview

This is a passenger dashboard system for Raspberry Pi 4 designed for in-vehicle use with a 7" touchscreen (800x480). The system provides entertainment and information with a touch-optimized interface that works without keyboard/mouse.

## Current State (v0.1.0)

### ✅ Completed
- Python package structure with Flask/SocketIO backend
- Touch-optimized web UI with beautiful gradient design
- System monitoring module (CPU, memory, disk, temperature)
- Systemd services for auto-start and graceful shutdown
- Boot optimization scripts for fast startup
- Power management for vehicle power cycles
- Read-only filesystem option for SD card protection
- Ansible playbooks for remote deployment and updates
- Automated installation script with kiosk mode
- GitHub release v0.1.0 published

### 🔲 To Be Implemented
1. **Camera Module** - Live camera feed viewer (placeholder exists)
2. **Media Player Module** - Video/audio playback (placeholder exists)
3. **Enhanced System Stats** - Real-time updates via WebSocket
4. **Settings UI** - Touch-friendly configuration interface

## Architecture

### Technology Stack
- **Backend**: Flask 3.x + Flask-SocketIO for real-time communication
- **Frontend**: HTML/CSS/JavaScript with Socket.IO client
- **Display**: Chromium in kiosk mode (fullscreen, no UI elements)
- **System**: Systemd services, auto-login, auto-start X server

### File Structure
```
pi-dashboard/
├── src/pi_dashboard/
│   ├── main.py              # Flask app entry point
│   ├── camera/              # Camera module
│   │   ├── __init__.py
│   │   └── camera.py        # Camera feed handler (stub)
│   ├── media/               # Media player module
│   │   ├── __init__.py
│   │   └── player.py        # Media playback (stub)
│   ├── system/              # System monitoring
│   │   └── __init__.py      # SystemMonitor class (working)
│   ├── modules/             # Extensible modules directory
│   └── templates/           # Jinja2 HTML templates
│       ├── index.html       # Main dashboard
│       ├── camera.html      # Camera view (stub)
│       ├── media.html       # Media player (stub)
│       ├── system.html      # System stats (stub)
│       └── settings.html    # Settings (stub)
├── config/
│   ├── default.json         # Default configuration
│   └── config.example.json  # Full config template
├── systemd/                 # Service files
├── scripts/                 # System setup scripts
├── ansible/                 # Deployment playbooks
├── install.sh               # Main installer
└── package.sh               # Release packager
```

## Key Design Decisions

### Touch-First Interface
- Large buttons (minimum 44px tap targets)
- No hover states (not applicable on touch)
- Prevent double-tap zoom, context menus
- Hide cursor since no mouse is available
- Use `cursor: none` in CSS

### Vehicle Power Handling
- Graceful shutdown handler via systemd
- Boot optimization for quick startup (<10 seconds target)
- Optional read-only filesystem to prevent SD card corruption
- Watchdog service for recovery from crashes

### Remote Management
- SSH enabled for remote access
- Ansible playbooks for updates over internet
- Three update strategies:
  - `deploy.yml` - Full deployment
  - `update.yml` - Application code only
  - `configure.yml` - Configuration changes only

## Development Workflow

### Local Development
```bash
cd /workspaces/pi-dashboard
pip install -e .
pi-dashboard -v  # Run with verbose logging
# Access at http://localhost:5000
```

### Testing on Pi
```bash
# Package for deployment
./package.sh

# Transfer to Pi
scp pi-dashboard-0.1.0.tar.gz pi@<ip>:/home/pi/

# On Pi: extract and install
tar -xzf pi-dashboard-0.1.0.tar.gz
cd pi-dashboard-0.1.0
sudo ./install.sh
```

### Creating New Release
```bash
# Update version in pyproject.toml
# Run packager
./package.sh

# Commit changes
git add .
git commit -m "Version x.y.z"
git push

# Create tag and release
git tag -a vx.y.z -m "Release notes"
git push origin vx.y.z

# Create GitHub release with tarball
gh release create vx.y.z pi-dashboard-x.y.z.tar.gz \
  --title "Pi Dashboard vx.y.z" \
  --notes "Release notes here"
```

## Implementation Priorities

### 1. Camera Module (High Priority)
**Goal**: Display live camera feeds from USB or Pi Camera

**Requirements**:
- Support multiple camera sources
- MJPEG streaming for low latency
- Touch to switch between cameras
- Configurable resolution

**Files to Modify**:
- `src/pi_dashboard/camera/camera.py` - Implement CameraManager class
- `src/pi_dashboard/templates/camera.html` - Real camera feed display
- `src/pi_dashboard/main.py` - Add camera streaming routes

**Suggested Approach**:
- Use OpenCV for camera capture
- Stream frames as MJPEG via Flask route
- Use `<img>` tag with src pointing to stream endpoint

### 2. Media Player Module (High Priority)
**Goal**: Play videos and audio files from local storage

**Requirements**:
- Browse media library (/home/pi/media or configured path)
- Touch-friendly file browser
- Video playback with controls (play/pause, seek, volume)
- Support common formats (MP4, MKV, AVI, MP3)

**Files to Modify**:
- `src/pi_dashboard/media/player.py` - Implement MediaPlayer class
- `src/pi_dashboard/templates/media.html` - Media browser and player UI
- `src/pi_dashboard/main.py` - Add media routes

**Suggested Approach**:
- Use HTML5 `<video>` tag for playback
- Serve media files via Flask static/send_file
- Custom touch controls overlaid on video

### 3. Real-Time System Stats (Medium Priority)
**Goal**: Live updating system information

**Requirements**:
- Push updates via Socket.IO every 2 seconds
- Display CPU, memory, disk, temperature
- Visual indicators (progress bars, colors)

**Files to Modify**:
- `src/pi_dashboard/main.py` - Add background thread for stats updates
- `src/pi_dashboard/templates/system.html` - Real-time display
- `src/pi_dashboard/templates/index.html` - Update header stats

**Suggested Approach**:
- Background thread emits stats via Socket.IO
- Client JavaScript updates DOM on message receive
- Use systemMonitor.get_all_stats() from system module

### 4. Settings UI (Medium Priority)
**Goal**: Configure dashboard without editing JSON files

**Requirements**:
- Touch-friendly form controls
- Save to /etc/pi-dashboard/config.json
- Restart service on save
- Toggle modules on/off

**Files to Modify**:
- `src/pi_dashboard/templates/settings.html` - Settings form
- `src/pi_dashboard/main.py` - Add save settings route
- Config loading in main.py - Reload on changes

## Important Notes

### Hardware Constraints
- **Display**: 800x480 resolution, 7" diagonal
- **No keyboard/mouse**: Everything must work via touch
- **Vehicle environment**: Frequent power cycles, vibration, temperature extremes
- **SD card**: Limited write cycles, hence read-only filesystem option

### Configuration Locations
- **Development**: `config/default.json` or `config/config.json`
- **Installed**: `/etc/pi-dashboard/config.json`
- **Logs**: `/var/log/pi-dashboard/` (in-memory tmpfs if read-only FS)

### Service Management
```bash
# View logs
sudo journalctl -u pi-dashboard -f

# Restart
sudo systemctl restart pi-dashboard

# Stop
sudo systemctl stop pi-dashboard

# Status
sudo systemctl status pi-dashboard
```

### Kiosk Mode Details
- Chromium starts in kiosk mode via Openbox autostart
- Auto-login as 'pi' user
- startx runs automatically on tty1
- Unclutter hides cursor
- Display power management disabled

## Common Issues & Solutions

### OpenCV Import Errors
- OpenCV requires system libraries not available in all environments
- Camera module imports are wrapped in try/except
- Falls back gracefully if not available

### Permission Issues
- Dashboard runs as 'pi' user
- Config directory owned by 'pi'
- Systemd service runs with User=pi

### Network Issues
- Dashboard binds to 0.0.0.0:5000
- Firewall rules allow port 5000 and 22 (SSH)
- Check with `sudo ufw status` if using ufw

## Testing Checklist

Before creating a release:
- [ ] Test installation on fresh Raspberry Pi OS
- [ ] Verify auto-start on boot
- [ ] Test graceful shutdown
- [ ] Verify touchscreen responsiveness
- [ ] Check all navigation works without keyboard
- [ ] Test power cycle (hard shutdown and restart)
- [ ] Verify logs are accessible
- [ ] Test remote Ansible update
- [ ] Check system stats display correctly
- [ ] Verify kiosk mode (no browser UI visible)

## Resources

- **Repository**: https://github.com/kelleyblackmore/pi-dashboard
- **Latest Release**: https://github.com/kelleyblackmore/pi-dashboard/releases/latest
- **Flask Docs**: https://flask.palletsprojects.com/
- **Socket.IO**: https://socket.io/docs/v4/
- **Raspberry Pi**: https://www.raspberrypi.com/documentation/

## Next Agent Tasks

The next agent should focus on implementing one of the stub modules:

1. **Camera Module** - Most impactful for dashboard use
2. **Media Player** - Core entertainment feature
3. **Real-time System Stats** - Quick win to make dashboard feel alive

Choose based on user priorities or start with system stats for quickest visible improvement.
