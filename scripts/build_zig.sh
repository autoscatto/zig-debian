#!/bin/bash

# Ensure a version and architecture are provided as arguments
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Error: Specify the version and architecture as arguments (e.g., ./build_zig.sh 0.6.0 x86_64-linux)"
  exit 1
fi

VERSION="$1"
ARCH="$2"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
WORKDIR=$(mktemp -d)
echo "Working directory: $WORKDIR"
cd "$WORKDIR" || exit 1

# Download the specified Zig version for the architecture
echo "Downloading Zig version $VERSION for $ARCH..."
wget "https://ziglang.org/download/$VERSION/zig-$ARCH-$VERSION.tar.xz" || exit 1

# Extract the archive
echo "Extracting zig-$ARCH-$VERSION.tar.xz..."
tar xvf "zig-$ARCH-$VERSION.tar.xz" || exit 1

# Create a symlink
echo "Creating symlink zig-$ARCH-$VERSION..."
ln -s "zig-$ARCH-$VERSION" "zig-$ARCH-$VERSION" || exit 1

# Create the original tarball
echo "Creating zig_$VERSION_$ARCH.orig.tar.xz..."
tar cJhf "zig_$VERSION_$ARCH.orig.tar.xz" "zig-$ARCH-$VERSION" || exit 1

# Enter the Zig directory
cd "zig-$ARCH-$VERSION" || exit 1

# Copy all files into a new debian directory
echo "Copying all files (excluding scripts) into the debian directory..."
mkdir -p debian
rsync -av --exclude 'scripts' "$SCRIPT_DIR/../" debian/ || exit 1

# Replace $version and $arch with the specified version and architecture
echo "Replacing '\$version' with '$VERSION' and '\$arch' with '$ARCH' in all files..."
find debian -type f -exec sed -i "s/\$version/$VERSION/g" {} +
find debian -type f -exec sed -i "s/\$arch/$ARCH/g" {} +

# Build the package
echo "Building the package with debuild..."
debuild -us -uc || exit 1

echo "Build completed! Packages are in: $WORKDIR"
