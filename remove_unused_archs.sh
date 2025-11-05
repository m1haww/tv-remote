#!/bin/bash

# Script to remove unused architectures from SmartView framework
# This removes simulator architectures (x86_64, i386) from the framework
# Required for App Store submission

echo "🔧 Removing unused architectures from SmartView framework..."

FRAMEWORK_PATH="Frameworks/SmartView.framework"
FRAMEWORK_BINARY="$FRAMEWORK_PATH/SmartView"

# Check if framework exists
if [ ! -f "$FRAMEWORK_BINARY" ]; then
    echo "❌ SmartView framework not found at $FRAMEWORK_BINARY"
    exit 1
fi

# Check current architectures
echo "📋 Current architectures:"
lipo -info "$FRAMEWORK_BINARY"

# Check if this is a universal binary
if lipo -info "$FRAMEWORK_BINARY" | grep -q "universal binary"; then
    echo "🎯 Removing simulator architectures (x86_64, i386)..."

    # Extract only device architecture (arm64)
    lipo -extract arm64 "$FRAMEWORK_BINARY" -output "$FRAMEWORK_BINARY.arm64"

    # Replace the original binary
    mv "$FRAMEWORK_BINARY.arm64" "$FRAMEWORK_BINARY"

    echo "✅ Architectures after removal:"
    lipo -info "$FRAMEWORK_BINARY"

    echo "🎉 SmartView framework is now device-only and App Store ready!"
else
    echo "ℹ️  Framework is already single architecture, no changes needed"
fi

# Also update the Swift module files to only include device architecture
SWIFTMODULE_PATH="$FRAMEWORK_PATH/Modules/SmartView.swiftmodule"
if [ -d "$SWIFTMODULE_PATH" ]; then
    echo "🔄 Cleaning up Swift module files..."

    # Remove simulator Swift modules
    rm -f "$SWIFTMODULE_PATH/x86_64-apple-ios-simulator"*
    rm -f "$SWIFTMODULE_PATH/i386-apple-ios-simulator"*

    # Keep only device modules
    echo "📱 Remaining Swift modules:"
    ls -la "$SWIFTMODULE_PATH/"
fi

echo "✅ Framework cleanup complete!"