#!/bin/bash

# Script to fix SmartView framework for device builds
# This adds missing arm64-apple-ios Swift module files

FRAMEWORK_PATH="Frameworks/SmartView.framework/Modules/SmartView.swiftmodule"

echo "🔧 Fixing SmartView framework for device builds..."

# Check if device files already exist
if [ -f "$FRAMEWORK_PATH/arm64-apple-ios.swiftinterface" ]; then
    echo "✅ Device Swift modules already exist, skipping fix"
    exit 0
fi

# Copy simulator files to device architecture
echo "📱 Adding device architecture Swift modules..."

cp "$FRAMEWORK_PATH/arm64-apple-ios-simulator.swiftinterface" "$FRAMEWORK_PATH/arm64-apple-ios.swiftinterface"
cp "$FRAMEWORK_PATH/arm64-apple-ios-simulator.private.swiftinterface" "$FRAMEWORK_PATH/arm64-apple-ios.private.swiftinterface"
cp "$FRAMEWORK_PATH/arm64-apple-ios-simulator.swiftdoc" "$FRAMEWORK_PATH/arm64-apple-ios.swiftdoc"
cp "$FRAMEWORK_PATH/arm64-apple-ios-simulator.abi.json" "$FRAMEWORK_PATH/arm64-apple-ios.abi.json"

# Fix target in interface files
echo "🎯 Updating target architecture in interface files..."
sed -i '' 's/arm64-apple-ios8.0-simulator/arm64-apple-ios8.0/g' "$FRAMEWORK_PATH/arm64-apple-ios.swiftinterface"
sed -i '' 's/arm64-apple-ios8.0-simulator/arm64-apple-ios8.0/g' "$FRAMEWORK_PATH/arm64-apple-ios.private.swiftinterface"

echo "✅ SmartView framework fixed for device builds!"
echo "📋 Files created:"
ls -la "$FRAMEWORK_PATH/arm64-apple-ios.*"