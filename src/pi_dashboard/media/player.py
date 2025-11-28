"""Media player module for video and audio playback."""

import os
import logging
from pathlib import Path
from typing import List, Dict, Optional

logger = logging.getLogger(__name__)


class MediaLibrary:
    """Manages media library and file scanning."""
    
    SUPPORTED_VIDEO = {'.mp4', '.mkv', '.avi', '.mov', '.m4v', '.webm'}
    SUPPORTED_AUDIO = {'.mp3', '.m4a', '.wav', '.flac', '.ogg'}
    
    def __init__(self, library_path: str):
        """Initialize media library.
        
        Args:
            library_path: Path to media library directory
        """
        self.library_path = Path(library_path)
        self.media_files: List[Dict] = []
        
    def scan(self) -> List[Dict]:
        """Scan library for media files.
        
        Returns:
            List of media file information
        """
        self.media_files = []
        
        if not self.library_path.exists():
            logger.warning(f"Media library path does not exist: {self.library_path}")
            return self.media_files
        
        try:
            for file_path in self.library_path.rglob('*'):
                if file_path.is_file():
                    ext = file_path.suffix.lower()
                    
                    if ext in self.SUPPORTED_VIDEO or ext in self.SUPPORTED_AUDIO:
                        media_type = 'video' if ext in self.SUPPORTED_VIDEO else 'audio'
                        
                        self.media_files.append({
                            'name': file_path.stem,
                            'filename': file_path.name,
                            'path': str(file_path),
                            'relative_path': str(file_path.relative_to(self.library_path)),
                            'type': media_type,
                            'extension': ext,
                            'size': file_path.stat().st_size,
                            'modified': file_path.stat().st_mtime
                        })
            
            # Sort by name
            self.media_files.sort(key=lambda x: x['name'].lower())
            logger.info(f"Found {len(self.media_files)} media files")
            
        except Exception as e:
            logger.error(f"Error scanning media library: {e}")
        
        return self.media_files
    
    def get_files(self, media_type: Optional[str] = None) -> List[Dict]:
        """Get list of media files.
        
        Args:
            media_type: Filter by 'video' or 'audio', None for all
            
        Returns:
            List of media file information
        """
        if media_type:
            return [f for f in self.media_files if f['type'] == media_type]
        return self.media_files
    
    def get_file(self, path: str) -> Optional[Dict]:
        """Get media file information by path.
        
        Args:
            path: File path
            
        Returns:
            Media file information or None
        """
        for media in self.media_files:
            if media['path'] == path:
                return media
        return None


class MediaModule:
    """Media player module."""
    
    def __init__(self, app=None, socketio=None, library_path: str = None):
        """Initialize media module.
        
        Args:
            app: Flask app instance
            socketio: SocketIO instance
            library_path: Path to media library
        """
        self.app = app
        self.socketio = socketio
        self.library_path = library_path or os.path.expanduser("~/media")
        self.library = MediaLibrary(self.library_path)
        self.current_media: Optional[Dict] = None
        
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
        
        # Scan library on init
        self.library.scan()
        
        # Register routes
        @app.route('/media')
        def media_view():
            from flask import render_template
            return render_template('media.html', 
                                 video_count=len(self.library.get_files('video')),
                                 audio_count=len(self.library.get_files('audio')))
        
        @app.route('/media/api/files')
        def media_files():
            from flask import jsonify, request
            media_type = request.args.get('type')
            files = self.library.get_files(media_type)
            return jsonify(files)
        
        @app.route('/media/api/scan')
        def media_scan():
            from flask import jsonify
            files = self.library.scan()
            return jsonify({'count': len(files), 'files': files})
        
        @app.route('/media/stream/<path:filepath>')
        def media_stream(filepath):
            """Stream media file."""
            from flask import send_file
            file_path = Path(self.library_path) / filepath
            
            if file_path.exists() and file_path.is_file():
                return send_file(str(file_path))
            
            from flask import abort
            abort(404)
        
        # Socket.IO events
        @socketio.on('media_play')
        def handle_play(data):
            """Handle play request."""
            file_path = data.get('path')
            media = self.library.get_file(file_path)
            
            if media:
                self.current_media = media
                socketio.emit('media_status', {
                    'status': 'playing',
                    'media': media
                })
                logger.info(f"Playing: {media['name']}")
        
        @socketio.on('media_pause')
        def handle_pause():
            """Handle pause request."""
            socketio.emit('media_status', {'status': 'paused'})
        
        @socketio.on('media_stop')
        def handle_stop():
            """Handle stop request."""
            self.current_media = None
            socketio.emit('media_status', {'status': 'stopped'})
    
    def get_library_stats(self) -> Dict:
        """Get media library statistics.
        
        Returns:
            Dictionary with library stats
        """
        videos = self.library.get_files('video')
        audio = self.library.get_files('audio')
        
        return {
            'total_files': len(self.library.media_files),
            'video_files': len(videos),
            'audio_files': len(audio),
            'library_path': str(self.library_path)
        }


__all__ = ['MediaModule', 'MediaLibrary']
