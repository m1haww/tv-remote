# SmartView Framework Setup Instructions

## Current Status
✅ **Project Configuration Updated**: The Xcode project now references `Frameworks/SmartView.framework` (local path)
✅ **Codemagic Configuration**: Already properly configured for device-only builds

## Required Steps

### Step 1: Create Framework Directory Structure
```bash
cd "/Users/petrugrigor/Documents/tv-remote"
mkdir -p Frameworks
```

### Step 2: Set Up SmartView.framework
You have several options:

#### Option A: Use Your Device-Compatible Framework (Recommended)
If you have a device-compatible SmartView.framework:
```bash
# Copy your device-compatible framework to:
cp -r /path/to/your/device/SmartView.framework ./Frameworks/SmartView.framework
```

#### Option B: Use Backup and Let Codemagic Convert (Current Setup)
If you only have the simulator framework:
```bash
# Copy from backup (if it exists)
cp -r ./Frameworks/SmartView.framework.backup ./Frameworks/SmartView.framework
```
*Note: Codemagic will automatically convert this for device builds*

#### Option C: Download Fresh Device Framework
Download the device-compatible SmartView SDK and extract the device framework:
```bash
# Extract from SmartViewSDK and copy the ios-arm64 framework
cp -r /path/to/SmartViewSDK/ios-arm64/SmartView.framework ./Frameworks/SmartView.framework
```

### Step 3: Verify Framework Architecture (Optional)
Check if your framework is device-compatible:
```bash
file ./Frameworks/SmartView.framework/SmartView
lipo -info ./Frameworks/SmartView.framework/SmartView
```

**Device-compatible output should show:**
- `Mach-O universal binary with 1 architecture: [arm64]` OR
- `arm64` architecture only

**Simulator output will show:**
- `arm64-apple-ios-simulator` or `x86_64` architectures

### Step 4: Test Local Build (Optional)
```bash
xcodebuild -workspace "New Smart.xcworkspace" -scheme "New Smart" \
  -configuration Debug -destination 'generic/platform=iOS' \
  build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
```

### Step 5: Commit and Push for Codemagic
```bash
git add .
git commit -m "Update SmartView framework to use local reference"
git push
```

## What Codemagic Will Do Automatically

When you push to Codemagic, the build script will automatically:

1. **Check Framework**: Verify `./Frameworks/SmartView.framework` exists
2. **Strip Simulator Architectures**: Remove x86_64/i386 if present
3. **Fix Swift Modules**: Convert simulator modules to device modules
4. **Fix Target Platform**: Update platform references for iOS device
5. **Build for App Store**: Create device-only app bundle

## Expected Directory Structure

After setup, your project should look like:
```
tv-remote/
├── Frameworks/
│   └── SmartView.framework/
│       ├── SmartView (binary)
│       ├── Headers/
│       ├── Modules/
│       └── Info.plist
├── New Smart.xcworkspace
├── New Smart.xcodeproj/
└── codemagic.yaml
```

## Troubleshooting

**If Xcode shows "Framework not found":**
1. Clean build folder (⌘+Shift+K)
2. Verify framework exists at `Frameworks/SmartView.framework`
3. Check Framework Search Paths in Build Settings

**If Codemagic build fails:**
1. Check that `Frameworks/SmartView.framework` exists in repo
2. Verify the framework binary is not empty
3. Check Codemagic logs for specific errors

**If you get "Service is unavailable" errors:**
- This is normal for simulator framework - Codemagic will fix it automatically
- For local testing, you need a device-compatible framework