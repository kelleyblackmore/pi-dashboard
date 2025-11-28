#!/bin/bash
#
# Package Pi Dashboard for deployment
# Creates a tarball ready for transfer to Raspberry Pi
#

set -e

VERSION="0.1.0"
PACKAGE_NAME="pi-dashboard-${VERSION}"
OUTPUT_FILE="${PACKAGE_NAME}.tar.gz"

echo "=== Pi Dashboard Packager ==="
echo ""
echo "Creating deployment package: ${OUTPUT_FILE}"
echo ""

# Clean up any previous builds
echo "Cleaning up..."
rm -rf dist/ build/ *.egg-info/
rm -f "${OUTPUT_FILE}"

# Create temporary directory for packaging
TEMP_DIR=$(mktemp -d)
PACKAGE_DIR="${TEMP_DIR}/${PACKAGE_NAME}"

echo "Copying files..."
mkdir -p "${PACKAGE_DIR}"

# Copy essential files
cp -r src/ "${PACKAGE_DIR}/"
cp -r config/ "${PACKAGE_DIR}/"
cp -r systemd/ "${PACKAGE_DIR}/"
cp -r scripts/ "${PACKAGE_DIR}/"
cp -r ansible/ "${PACKAGE_DIR}/"
mkdir -p "${PACKAGE_DIR}/media"
cp media/.gitkeep "${PACKAGE_DIR}/media/" 2>/dev/null || true

# Copy root files
cp setup.py "${PACKAGE_DIR}/"
cp pyproject.toml "${PACKAGE_DIR}/"
cp README.md "${PACKAGE_DIR}/"
cp QUICKSTART.md "${PACKAGE_DIR}/"
cp LICENSE "${PACKAGE_DIR}/"
cp install.sh "${PACKAGE_DIR}/"
cp .gitignore "${PACKAGE_DIR}/"

# Make scripts executable
chmod +x "${PACKAGE_DIR}/install.sh"
chmod +x "${PACKAGE_DIR}/scripts/"*.sh
chmod +x "${PACKAGE_DIR}/scripts/pi-dashboard-shutdown"

# Create the tarball
echo "Creating archive..."
cd "${TEMP_DIR}"
tar -czf "${OUTPUT_FILE}" "${PACKAGE_NAME}/"

# Move to original directory
mv "${OUTPUT_FILE}" "${OLDPWD}/"
cd "${OLDPWD}"

# Cleanup
rm -rf "${TEMP_DIR}"

# Show result
FILE_SIZE=$(du -h "${OUTPUT_FILE}" | cut -f1)
echo ""
echo "✓ Package created successfully!"
echo ""
echo "  File: ${OUTPUT_FILE}"
echo "  Size: ${FILE_SIZE}"
echo ""
echo "Transfer to your Raspberry Pi with:"
echo "  scp ${OUTPUT_FILE} pi@<pi-ip>:/home/pi/"
echo ""
echo "Then on the Pi:"
echo "  tar -xzf ${OUTPUT_FILE}"
echo "  cd ${PACKAGE_NAME}"
echo "  sudo ./install.sh"
echo ""
