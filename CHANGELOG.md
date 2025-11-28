# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-11-28

### Added
- Initial release of Pi Dashboard
- Flask-based web server with Socket.IO support
- Touch-optimized dashboard UI for 7" displays (800x480)
- System monitoring module (CPU, memory, disk, temperature)
- Systemd service files for auto-start and graceful shutdown
- Boot optimization scripts for fast startup
- Power management configuration for vehicle environments
- Read-only filesystem support for SD card protection
- Ansible playbooks for remote deployment and updates
- Automated installation script with kiosk mode setup
- Package script for creating deployment archives
- Comprehensive documentation (README, QUICKSTART, AGENT)

### Placeholder Modules
- Camera module structure (implementation pending)
- Media player module structure (implementation pending)
- Settings UI structure (implementation pending)

### Known Issues
- Camera and media modules are not yet functional
- System stats in UI header show "--" (not connected to backend yet)

## [Unreleased]

### Planned
- Full camera feed implementation with MJPEG streaming
- Media player with file browser and playback controls
- Real-time system stats updates via WebSocket
- Touch-friendly settings configuration UI
- Weather module integration
- Navigation/GPS integration
- Music player module

---

[0.1.0]: https://github.com/kelleyblackmore/pi-dashboard/releases/tag/v0.1.0
