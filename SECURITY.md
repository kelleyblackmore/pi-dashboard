# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in Pi Dashboard, please report it by:

1. **DO NOT** open a public issue
2. Email the maintainer or use GitHub's private vulnerability reporting
3. Include details about the vulnerability and steps to reproduce

## Security Considerations

### Network Security
- The dashboard runs on port 5000 by default
- SSH is enabled for remote access
- Consider using a VPN for remote connections
- Change default passwords immediately

### Physical Security
- The Pi is physically accessible in the vehicle
- Consider case locks or mounting in secure location
- SD card contains system and configuration

### Default Credentials
- Default Raspberry Pi OS password should be changed
- No authentication on dashboard by default (optional PIN in config)

### Updates
- Keep Raspberry Pi OS updated: `sudo apt update && sudo apt upgrade`
- Update dashboard via Ansible or git pull
- Monitor GitHub releases for security patches

### Best Practices
1. Change default passwords
2. Use SSH keys instead of password authentication
3. Enable firewall (ufw) and limit open ports
4. Use read-only filesystem when possible
5. Regular backups of configuration
6. Monitor system logs for suspicious activity

## Scope

This security policy applies to:
- Pi Dashboard application code
- Installation and configuration scripts
- Ansible playbooks

It does not cover:
- Raspberry Pi OS security (refer to Raspberry Pi documentation)
- Third-party Python packages (check their individual security policies)
- Physical hardware security
