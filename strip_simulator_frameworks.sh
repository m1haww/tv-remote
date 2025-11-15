#!/bin/bash

# Script to strip simulator architectures from frameworks for App Store builds
# This should be run as a build phase in Xcode or in your CI/CD pipeline

echo "Stripping simulator architectures from frameworks..."

APP_PATH="${TARGET_BUILD_DIR}/${WRAPPER_NAME}"

# Find all frameworks in the app bundle
find "$APP_PATH" -name "*.framework" -type d | while read -r FRAMEWORK
do
    FRAMEWORK_EXECUTABLE_NAME=$(basename "$FRAMEWORK" .framework)
    FRAMEWORK_EXECUTABLE_PATH="$FRAMEWORK/$FRAMEWORK_EXECUTABLE_NAME"

    if [ -f "$FRAMEWORK_EXECUTABLE_PATH" ]; then
        echo "Processing $FRAMEWORK_EXECUTABLE_NAME..."

        # Get all architectures in the framework
        ARCHS="$(lipo -info "$FRAMEWORK_EXECUTABLE_PATH" | rev | cut -d ':' -f1 | rev)"

        for ARCH in $ARCHS
        do
            # Remove simulator architectures (x86_64, i386)
            if [[ "$ARCH" == "x86_64" ]] || [[ "$ARCH" == "i386" ]]; then
                echo "Stripping $ARCH from $FRAMEWORK_EXECUTABLE_NAME"
                lipo -remove "$ARCH" -output "$FRAMEWORK_EXECUTABLE_PATH" "$FRAMEWORK_EXECUTABLE_PATH"
            fi
        done

        # Remove simulator Swift modules
        if [ -d "$FRAMEWORK/Modules/$FRAMEWORK_EXECUTABLE_NAME.swiftmodule" ]; then
            find "$FRAMEWORK/Modules/$FRAMEWORK_EXECUTABLE_NAME.swiftmodule" -name "*simulator*" -delete
        fi
    fi
done

echo "Framework stripping completed."