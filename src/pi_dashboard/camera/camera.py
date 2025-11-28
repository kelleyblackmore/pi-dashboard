"""Camera module for displaying camera feeds."""

import base64
import logging
from threading import Thread, Lock
from typing import Optional, List, Dict

try:
    import cv2
    CV2_AVAILABLE = True
except ImportError:
    CV2_AVAILABLE = False
    logging.warning("OpenCV not available - camera features will be disabled")

logger = logging.getLogger(__name__)


class CameraFeed:
    """Handles a single camera feed."""
    
    def __init__(self, camera_id: int = 0, name: str = "Camera"):
        """Initialize camera feed.
        
        Args:
            camera_id: Camera device ID (0 for default)
            name: Display name for the camera
        """
        self.camera_id = camera_id
        self.name = name
        self.camera = None
        self.frame = None
        self.lock = Lock()
        self.running = False
        self.thread = None
        
    def start(self) -> bool:
        """Start capturing from camera.
        
        Returns:
            True if camera started successfully
        """
        if not CV2_AVAILABLE:
            logger.error("OpenCV not available")
            return False
            
        try:
            self.camera = cv2.VideoCapture(self.camera_id)
            if not self.camera.isOpened():
                logger.error(f"Failed to open camera {self.camera_id}")
                return False
                
            # Set camera properties
            self.camera.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
            self.camera.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
            self.camera.set(cv2.CAP_PROP_FPS, 30)
            
            self.running = True
            self.thread = Thread(target=self._capture_loop, daemon=True)
            self.thread.start()
            
            logger.info(f"Started camera feed: {self.name}")
            return True
            
        except Exception as e:
            logger.error(f"Error starting camera {self.camera_id}: {e}")
            return False
    
    def _capture_loop(self):
        """Continuously capture frames from camera."""
        while self.running:
            try:
                ret, frame = self.camera.read()
                if ret:
                    with self.lock:
                        self.frame = frame
            except Exception as e:
                logger.error(f"Error capturing frame: {e}")
                break
    
    def get_frame_jpeg(self) -> Optional[bytes]:
        """Get current frame as JPEG bytes.
        
        Returns:
            JPEG encoded frame or None
        """
        with self.lock:
            if self.frame is None:
                return None
            
            try:
                # Encode frame as JPEG
                ret, buffer = cv2.imencode('.jpg', self.frame, [cv2.IMWRITE_JPEG_QUALITY, 85])
                if ret:
                    return buffer.tobytes()
            except Exception as e:
                logger.error(f"Error encoding frame: {e}")
                
        return None
    
    def get_frame_base64(self) -> Optional[str]:
        """Get current frame as base64 encoded string.
        
        Returns:
            Base64 encoded JPEG frame or None
        """
        jpeg_bytes = self.get_frame_jpeg()
        if jpeg_bytes:
            return base64.b64encode(jpeg_bytes).decode('utf-8')
        return None
    
    def stop(self):
        """Stop capturing from camera."""
        self.running = False
        if self.thread:
            self.thread.join(timeout=2)
        if self.camera:
            self.camera.release()
        logger.info(f"Stopped camera feed: {self.name}")


class CameraModule:
    """Manages multiple camera feeds."""
    
    def __init__(self, app=None, socketio=None):
        """Initialize camera module.
        
        Args:
            app: Flask app instance
            socketio: SocketIO instance
        """
        self.app = app
        self.socketio = socketio
        self.feeds: Dict[int, CameraFeed] = {}
        
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
        @app.route('/camera')
        def camera_view():
            from flask import render_template
            return render_template('camera.html', feeds=self.feeds)
        
        @app.route('/camera/<int:camera_id>/stream')
        def camera_stream(camera_id):
            """Stream camera feed as MJPEG."""
            from flask import Response
            
            def generate():
                feed = self.feeds.get(camera_id)
                if not feed:
                    return
                    
                while True:
                    frame = feed.get_frame_jpeg()
                    if frame:
                        yield (b'--frame\r\n'
                               b'Content-Type: image/jpeg\r\n\r\n' + frame + b'\r\n')
            
            return Response(generate(), mimetype='multipart/x-mixed-replace; boundary=frame')
        
        # Socket.IO events
        @socketio.on('camera_frame_request')
        def handle_frame_request(data):
            """Send camera frame via Socket.IO."""
            camera_id = data.get('camera_id', 0)
            feed = self.feeds.get(camera_id)
            
            if feed:
                frame_b64 = feed.get_frame_base64()
                if frame_b64:
                    socketio.emit('camera_frame', {
                        'camera_id': camera_id,
                        'frame': frame_b64
                    })
    
    def add_camera(self, camera_id: int = 0, name: str = "Camera") -> bool:
        """Add and start a camera feed.
        
        Args:
            camera_id: Camera device ID
            name: Display name
            
        Returns:
            True if camera was added successfully
        """
        if camera_id in self.feeds:
            logger.warning(f"Camera {camera_id} already exists")
            return True
        
        feed = CameraFeed(camera_id=camera_id, name=name)
        if feed.start():
            self.feeds[camera_id] = feed
            return True
        return False
    
    def remove_camera(self, camera_id: int):
        """Remove and stop a camera feed.
        
        Args:
            camera_id: Camera device ID to remove
        """
        if camera_id in self.feeds:
            self.feeds[camera_id].stop()
            del self.feeds[camera_id]
    
    def stop_all(self):
        """Stop all camera feeds."""
        for feed in self.feeds.values():
            feed.stop()
        self.feeds.clear()


__all__ = ['CameraModule', 'CameraFeed']
