#!/bin/bash

# Complete script to fix SmartView framework for device builds
# 1. Adds missing arm64-apple-ios Swift module files
# 2. Removes simulator architectures from binary for App Store compliance

FRAMEWORK_PATH="Frameworks/SmartView.framework"
SWIFTMODULE_PATH="$FRAMEWORK_PATH/Modules/SmartView.swiftmodule"
FRAMEWORK_BINARY="$FRAMEWORK_PATH/SmartView"

echo "🔧 Fixing SmartView framework for device builds..."

# Step 1: Add missing device Swift modules
echo "📱 Step 1: Adding device architecture Swift modules..."

if [ ! -f "$SWIFTMODULE_PATH/arm64-apple-ios.swiftinterface" ]; then
    cp "$SWIFTMODULE_PATH/arm64-apple-ios-simulator.swiftinterface" "$SWIFTMODULE_PATH/arm64-apple-ios.swiftinterface"
    cp "$SWIFTMODULE_PATH/arm64-apple-ios-simulator.private.swiftinterface" "$SWIFTMODULE_PATH/arm64-apple-ios.private.swiftinterface"
    cp "$SWIFTMODULE_PATH/arm64-apple-ios-simulator.swiftdoc" "$SWIFTMODULE_PATH/arm64-apple-ios.swiftdoc"
    cp "$SWIFTMODULE_PATH/arm64-apple-ios-simulator.abi.json" "$SWIFTMODULE_PATH/arm64-apple-ios.abi.json"

    # Fix target in interface files
    sed -i '' 's/arm64-apple-ios8.0-simulator/arm64-apple-ios8.0/g' "$SWIFTMODULE_PATH/arm64-apple-ios.swiftinterface"
    sed -i '' 's/arm64-apple-ios8.0-simulator/arm64-apple-ios8.0/g' "$SWIFTMODULE_PATH/arm64-apple-ios.private.swiftinterface"

    echo "✅ Device Swift modules created"
else
    echo "✅ Device Swift modules already exist"
fi

# Step 2: Remove simulator architectures from binary
echo "🎯 Step 2: Removing simulator architectures from binary..."

if lipo -info "$FRAMEWORK_BINARY" | grep -q "universal binary"; then
    echo "📋 Current architectures:"
    lipo -info "$FRAMEWORK_BINARY"

    # Extract only device architecture (arm64)
    lipo -extract arm64 "$FRAMEWORK_BINARY" -output "$FRAMEWORK_BINARY.arm64"

    # Replace the original binary
    mv "$FRAMEWORK_BINARY.arm64" "$FRAMEWORK_BINARY"

    echo "✅ Binary is now device-only:"
    lipo -info "$FRAMEWORK_BINARY"
else
    echo "✅ Binary is already single architecture"
fi

# Step 3: Clean up simulator Swift modules
echo "🧹 Step 3: Cleaning up simulator Swift modules..."
rm -f "$SWIFTMODULE_PATH/x86_64-apple-ios-simulator"*
rm -f "$SWIFTMODULE_PATH/i386-apple-ios-simulator"*

echo "🎉 SmartView framework is now App Store ready!"
echo "📋 Remaining Swift modules:"
ls -la "$SWIFTMODULE_PATH/" | grep -E "\.(swiftinterface|swiftdoc|abi\.json)$"