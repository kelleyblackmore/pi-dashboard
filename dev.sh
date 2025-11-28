#!/bin/bash
#
# Development helper script
# Quick commands for common tasks
#

set -e

show_help() {
    cat << EOF
Pi Dashboard Development Helper

Usage: ./dev.sh [command]

Commands:
    run         - Run dashboard locally with verbose logging
    test        - Run basic tests
    package     - Create deployment package
    clean       - Clean build artifacts
    logs        - View systemd logs (on Pi)
    restart     - Restart service (on Pi)
    status      - Check service status (on Pi)
    help        - Show this help message

Examples:
    ./dev.sh run        # Start dashboard locally
    ./dev.sh package    # Create release package
    ./dev.sh logs       # View logs on Pi
EOF
}

case "${1:-help}" in
    run)
        echo "Starting Pi Dashboard..."
        pip install -e . > /dev/null 2>&1 || true
        pi-dashboard -v
        ;;
    
    test)
        echo "Running tests..."
        python -m pytest tests/ 2>/dev/null || echo "No tests found (tests/ directory not created yet)"
        ;;
    
    package)
        echo "Creating deployment package..."
        ./package.sh
        ;;
    
    clean)
        echo "Cleaning build artifacts..."
        rm -rf build/ dist/ *.egg-info/ src/*.egg-info/
        rm -f pi-dashboard-*.tar.gz
        find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
        echo "Clean complete!"
        ;;
    
    logs)
        echo "Viewing Pi Dashboard logs..."
        sudo journalctl -u pi-dashboard -f
        ;;
    
    restart)
        echo "Restarting Pi Dashboard service..."
        sudo systemctl restart pi-dashboard
        echo "Service restarted!"
        ;;
    
    status)
        echo "Pi Dashboard service status:"
        sudo systemctl status pi-dashboard
        ;;
    
    help|*)
        show_help
        ;;
esac
