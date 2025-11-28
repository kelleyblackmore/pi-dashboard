"""System monitoring module for Raspberry Pi stats."""

import psutil
import logging
from typing import Dict, Any
from threading import Thread
import time

logger = logging.getLogger(__name__)


class SystemMonitor:
    """Monitor system resources and stats."""
    
    @staticmethod
    def get_cpu_usage() -> float:
        """Get CPU usage percentage."""
        return round(psutil.cpu_percent(interval=0.5), 1)
    
    @staticmethod
    def get_cpu_count() -> Dict[str, int]:
        """Get CPU count information."""
        return {
            'physical': psutil.cpu_count(logical=False) or 1,
            'logical': psutil.cpu_count(logical=True) or 1
        }
    
    @staticmethod
    def get_memory_usage() -> Dict[str, Any]:
        """Get memory usage information."""
        mem = psutil.virtual_memory()
        return {
            'total': mem.total,
            'available': mem.available,
            'used': mem.used,
            'percent': round(mem.percent, 1),
            'total_gb': round(mem.total / (1024**3), 2),
            'used_gb': round(mem.used / (1024**3), 2),
            'available_gb': round(mem.available / (1024**3), 2)
        }
    
    @staticmethod
    def get_disk_usage() -> Dict[str, Any]:
        """Get disk usage information."""
        disk = psutil.disk_usage('/')
        return {
            'total': disk.total,
            'used': disk.used,
            'free': disk.free,
            'percent': round(disk.percent, 1),
            'total_gb': round(disk.total / (1024**3), 2),
            'used_gb': round(disk.used / (1024**3), 2),
            'free_gb': round(disk.free / (1024**3), 2)
        }
    
    @staticmethod
    def get_temperature() -> float:
        """Get CPU temperature (Raspberry Pi specific)."""
        try:
            with open('/sys/class/thermal/thermal_zone0/temp', 'r') as f:
                temp = float(f.read()) / 1000.0
                return round(temp, 1)
        except Exception:
            # Not on a Raspberry Pi or no sensor available
            return 0.0
    
    @staticmethod
    def get_network_stats() -> Dict[str, Any]:
        """Get network interface statistics."""
        net_io = psutil.net_io_counters()
        return {
            'bytes_sent': net_io.bytes_sent,
            'bytes_recv': net_io.bytes_recv,
            'packets_sent': net_io.packets_sent,
            'packets_recv': net_io.packets_recv,
            'mb_sent': round(net_io.bytes_sent / (1024**2), 2),
            'mb_recv': round(net_io.bytes_recv / (1024**2), 2)
        }
    
    @staticmethod
    def get_uptime() -> Dict[str, Any]:
        """Get system uptime."""
        boot_time = psutil.boot_time()
        uptime_seconds = time.time() - boot_time
        
        days = int(uptime_seconds // 86400)
        hours = int((uptime_seconds % 86400) // 3600)
        minutes = int((uptime_seconds % 3600) // 60)
        
        return {
            'boot_time': boot_time,
            'uptime_seconds': uptime_seconds,
            'uptime_text': f"{days}d {hours}h {minutes}m"
        }
    
    @staticmethod
    def get_all_stats() -> Dict[str, Any]:
        """Get all system statistics."""
        return {
            'cpu': {
                'usage': SystemMonitor.get_cpu_usage(),
                'count': SystemMonitor.get_cpu_count()
            },
            'memory': SystemMonitor.get_memory_usage(),
            'disk': SystemMonitor.get_disk_usage(),
            'temperature': SystemMonitor.get_temperature(),
            'network': SystemMonitor.get_network_stats(),
            'uptime': SystemMonitor.get_uptime()
        }


class SystemModule:
    """System monitoring module with real-time updates."""
    
    def __init__(self, app=None, socketio=None, update_interval: int = 2):
        """Initialize system module.
        
        Args:
            app: Flask app instance
            socketio: SocketIO instance
            update_interval: Seconds between stat updates
        """
        self.app = app
        self.socketio = socketio
        self.update_interval = update_interval
        self.monitor = SystemMonitor()
        self.running = False
        self.thread = None
        
        if app and socketio:
            self.init_app(app, socketio)
    
    def init_app(self, app, socketio):
        """Initialize with Flask app and SocketIO.
        
        Args:
            app: Flask app instance
            socketio: SocketIO instance
        """
        self.app = app
        self.socketio = socketio
        
        # Register routes
        @app.route('/system')
        def system_view():
            from flask import render_template
            stats = self.monitor.get_all_stats()
            return render_template('system.html', stats=stats)
        
        @app.route('/system/api/stats')
        def system_stats():
            from flask import jsonify
            return jsonify(self.monitor.get_all_stats())
        
        # Socket.IO events
        @socketio.on('system_stats_start')
        def handle_stats_start():
            """Start sending real-time stats."""
            if not self.running:
                self.start_monitoring()
        
        @socketio.on('system_stats_stop')
        def handle_stats_stop():
            """Stop sending real-time stats."""
            self.stop_monitoring()
    
    def start_monitoring(self):
        """Start real-time monitoring."""
        if self.running:
            return
        
        self.running = True
        self.thread = Thread(target=self._monitor_loop, daemon=True)
        self.thread.start()
        logger.info("Started system monitoring")
    
    def _monitor_loop(self):
        """Monitor loop that sends stats via Socket.IO."""
        while self.running:
            try:
                stats = self.monitor.get_all_stats()
                self.socketio.emit('system_stats_update', stats)
                time.sleep(self.update_interval)
            except Exception as e:
                logger.error(f"Error in monitor loop: {e}")
                break
    
    def stop_monitoring(self):
        """Stop real-time monitoring."""
        self.running = False
        if self.thread:
            self.thread.join(timeout=5)
        logger.info("Stopped system monitoring")


__all__ = ['SystemMonitor', 'SystemModule']
