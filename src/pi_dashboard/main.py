"""
Main entry point for the Pi Dashboard application.
"""

import os
import sys
import json
import logging
from pathlib import Path
from typing import Optional

from flask import Flask, render_template
from flask_socketio import SocketIO

from pi_dashboard.camera import CameraModule
from pi_dashboard.media import MediaModule
from pi_dashboard.system import SystemModule


# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class PiDashboard:
    """Main dashboard application class."""
    
    def __init__(self, config_path: Optional[str] = None):
        """Initialize the dashboard application.
        
        Args:
            config_path: Path to configuration file. If None, uses default locations.
        """
        self.config = self._load_config(config_path)
        self.app = Flask(__name__, 
                         template_folder=self._get_template_dir(),
                         static_folder=self._get_static_dir())
        self.app.config['SECRET_KEY'] = self.config.get('secret_key', 'dev-secret-key')
        self.socketio = SocketIO(self.app, cors_allowed_origins="*")
        
        # Module registry
        self.modules = {}
        
        # Initialize modules
        self._init_modules()
        
        # Set up routes
        self._setup_routes()
        
        logger.info("Pi Dashboard initialized")
    
    def _load_config(self, config_path: Optional[str]) -> dict:
        """Load configuration from file.
        
        Args:
            config_path: Path to config file
            
        Returns:
            Configuration dictionary
        """
        if config_path is None:
            # Try default locations
            possible_paths = [
                Path("/etc/pi-dashboard/config.json"),
                Path.home() / ".config" / "pi-dashboard" / "config.json",
                Path(__file__).parent.parent.parent / "config" / "config.json",
                Path(__file__).parent.parent.parent / "config" / "default.json",
            ]
            
            for path in possible_paths:
                if path.exists():
                    config_path = str(path)
                    break
        
        if config_path and Path(config_path).exists():
            logger.info(f"Loading config from: {config_path}")
            with open(config_path, 'r') as f:
                return json.load(f)
        else:
            logger.warning("No config file found, using defaults")
            return self._get_default_config()
    
    def _get_default_config(self) -> dict:
        """Get default configuration."""
        return {
            "display": {
                "width": 800,
                "height": 480,
                "fullscreen": True,
                "hide_cursor": True,
                "orientation": 0
            },
            "server": {
                "host": "0.0.0.0",
                "port": 5000,
                "debug": False
            },
            "modules": {
                "camera": {"enabled": True},
                "media": {"enabled": True},
                "system": {"enabled": True},
                "weather": {"enabled": False}
            },
            "power": {
                "shutdown_delay": 30,
                "boot_optimization": True
            }
        }
    
    def _get_template_dir(self) -> str:
        """Get templates directory path."""
        return str(Path(__file__).parent / "templates")
    
    def _get_static_dir(self) -> str:
        """Get static files directory path."""
        # Check if there's a static dir in project root
        project_static = Path(__file__).parent.parent.parent / "static"
        if project_static.exists():
            return str(project_static)
        # Fall back to package static
        return str(Path(__file__).parent / "static")
    
    def _init_modules(self):
        """Initialize dashboard modules."""
        # Camera module
        if self.config.get('modules', {}).get('camera', {}).get('enabled', True):
            self.modules['camera'] = CameraModule(self.app, self.socketio)
            logger.info("Camera module initialized")
        
        # Media module
        if self.config.get('modules', {}).get('media', {}).get('enabled', True):
            media_path = self.config.get('modules', {}).get('media', {}).get('library_path', '~/media')
            self.modules['media'] = MediaModule(self.app, self.socketio, library_path=media_path)
            logger.info("Media module initialized")
        
        # System module
        if self.config.get('modules', {}).get('system', {}).get('enabled', True):
            update_interval = self.config.get('modules', {}).get('system', {}).get('update_interval', 2)
            self.modules['system'] = SystemModule(self.app, self.socketio, update_interval=update_interval)
            logger.info("System module initialized")
    
    def _setup_routes(self):
        """Set up Flask routes."""
        
        @self.app.route('/')
        def index():
            """Main dashboard page."""
            return render_template('index.html', config=self.config)
        
        @self.app.route('/health')
        def health():
            """Health check endpoint."""
            return {'status': 'ok', 'version': '0.1.0'}
        
        @self.app.route('/settings')
        def settings():
            """Settings page."""
            return render_template('settings.html')
        
        @self.socketio.on('connect')
        def handle_connect():
            """Handle client connection."""
            logger.info("Client connected")
        
        @self.socketio.on('disconnect')
        def handle_disconnect():
            """Handle client disconnection."""
            logger.info("Client disconnected")
        
        @self.socketio.on('get_stats')
        def handle_get_stats():
            """Send current system stats."""
            if 'system' in self.modules:
                from pi_dashboard.system import SystemMonitor
                stats = SystemMonitor.get_all_stats()
                self.socketio.emit('stats_update', stats)
    
    def load_module(self, module_name: str):
        """Load a dashboard module.
        
        Args:
            module_name: Name of the module to load
        """
        if not self.config.get('modules', {}).get(module_name, {}).get('enabled', False):
            logger.info(f"Module {module_name} is disabled, skipping")
            return
        
        try:
            # Dynamic module loading will be implemented here
            logger.info(f"Loading module: {module_name}")
            # TODO: Implement module loading system
        except Exception as e:
            logger.error(f"Failed to load module {module_name}: {e}")
    
    def run(self):
        """Run the dashboard application."""
        server_config = self.config.get('server', {})
        host = server_config.get('host', '0.0.0.0')
        port = server_config.get('port', 5000)
        debug = server_config.get('debug', False)
        
        logger.info(f"Starting Pi Dashboard on {host}:{port}")
        logger.info(f"Access the dashboard at http://localhost:{port}")
        
        # Load enabled modules
        for module_name in self.config.get('modules', {}).keys():
            self.load_module(module_name)
        
        self.socketio.run(self.app, host=host, port=port, debug=debug)


def main():
    """Main entry point."""
    import argparse
    
    parser = argparse.ArgumentParser(description='Pi Dashboard - Passenger Entertainment System')
    parser.add_argument('-c', '--config', help='Path to configuration file')
    parser.add_argument('-v', '--verbose', action='store_true', help='Enable verbose logging')
    
    args = parser.parse_args()
    
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    try:
        dashboard = PiDashboard(config_path=args.config)
        dashboard.run()
    except KeyboardInterrupt:
        logger.info("Shutting down Pi Dashboard")
        sys.exit(0)
    except Exception as e:
        logger.error(f"Fatal error: {e}", exc_info=True)
        sys.exit(1)


if __name__ == '__main__':
    main()
