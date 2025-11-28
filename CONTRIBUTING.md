# Contributing to Pi Dashboard

Thank you for your interest in contributing to Pi Dashboard!

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/pi-dashboard.git`
3. Create a branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Test on a Raspberry Pi if possible
6. Commit and push
7. Open a Pull Request

## Development Setup

```bash
# Install in development mode
pip install -e .

# Run locally
./dev.sh run

# Or manually
pi-dashboard -v
```

## Code Style

- Follow PEP 8 for Python code
- Use meaningful variable names
- Add comments for complex logic
- Keep functions focused and small

## Testing

- Test all changes on actual Raspberry Pi hardware when possible
- Verify touch interactions work without keyboard/mouse
- Check that changes work in kiosk mode
- Test power cycle scenarios (boot/shutdown)

## Pull Request Guidelines

- Describe what your PR does
- Reference any related issues
- Include screenshots for UI changes
- Test on Raspberry Pi OS if possible
- Update documentation if needed

## Areas We Need Help

- **Camera Module**: Implementing live camera feed viewer
- **Media Player**: Video/audio playback with touch controls
- **System Stats**: Real-time updates via WebSocket
- **Settings UI**: Configuration interface
- **Documentation**: More examples and guides
- **Testing**: Unit tests and integration tests

## Questions?

Open an issue or start a discussion!

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
