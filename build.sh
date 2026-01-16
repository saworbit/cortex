#!/bin/bash
# CORTEX BOT - Unix Build Script
# Usage: ./build.sh [quake_path]

echo "==============================================="
echo "CORTEX BOT v4.2 \"Hunter\" - Build Script"
echo "==============================================="
echo ""

# Check for FTEQCC
if ! command -v fteqcc &> /dev/null; then
    echo "ERROR: fteqcc not found"
    echo ""
    echo "Install FTEQCC:"
    echo "  Ubuntu/Debian: sudo apt install fteqcc"
    echo "  Arch: yay -S fteqcc"
    echo "  macOS: brew install fteqcc"
    echo "  Or download from: https://www.fteqcc.org/"
    exit 1
fi

echo "[1/3] Compiling QuakeC..."
fteqcc progs.src

if [ $? -ne 0 ]; then
    echo ""
    echo "ERROR: Compilation failed!"
    exit 1
fi

echo "[2/3] Compilation successful!"
echo ""

# Check if quake path provided
if [ -z "$1" ]; then
    echo "[3/3] progs.dat created in current directory"
    echo ""
    echo "To install, copy progs.dat to your Quake id1 folder:"
    echo "  cp progs.dat ~/.quake/id1/"
    echo ""
    echo "Then run Quake:"
    echo "  quakespasm +deathmatch 1 +map dm4"
    echo ""
    echo "In game console:"
    echo "  impulse 100"
    echo ""
else
    echo "[3/3] Copying to $1/id1/"
    cp progs.dat "$1/id1/progs.dat"
    echo ""
    echo "Ready to test! Run:"
    echo "  $1/quake +deathmatch 1 +map dm4"
    echo ""
fi

echo "Build complete!"
