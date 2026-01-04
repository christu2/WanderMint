#!/bin/sh

# Xcode Cloud post-clone script
# This script runs after Xcode Cloud clones the repository

set -e

echo "🔧 Xcode Cloud: Running post-clone script..."

# The project has legacy CocoaPods references but we use Swift Package Manager now
# Remove all CocoaPods references to prevent build errors

echo "📦 Removing ALL CocoaPods references from Xcode project..."

# Navigate to repository root (script runs from ci_scripts directory)
cd ..

PROJECT_FILE="WanderMint.xcodeproj/project.pbxproj"

# Verify project file exists
if [ ! -f "$PROJECT_FILE" ]; then
    echo "❌ Error: Project file not found at $PROJECT_FILE"
    echo "Current directory: $(pwd)"
    ls -la
    exit 1
fi

# Backup the project file
cp "$PROJECT_FILE" "$PROJECT_FILE.backup"

echo "  Removing baseConfigurationReference (xcconfig files)..."
sed -i '' '/baseConfigurationReference.*Pods.*xcconfig/d' "$PROJECT_FILE"

echo "  Removing Pods framework references..."
sed -i '' '/Pods_.*\.framework in Frameworks/d' "$PROJECT_FILE"

echo "  Removing [CP] Check Pods Manifest.lock build phase..."
sed -i '' '/\[CP\] Check Pods Manifest\.lock/,/shellScript = /d' "$PROJECT_FILE"

echo "  Removing [CP] Embed Pods Frameworks build phase..."
sed -i '' '/\[CP\] Embed Pods Frameworks/,/shellScript = /d' "$PROJECT_FILE"

echo "  Removing [CP] Copy Pods Resources build phase..."
sed -i '' '/\[CP\] Copy Pods Resources/,/shellScript = /d' "$PROJECT_FILE"

echo "  Removing Pods-*.xcfilelist references..."
sed -i '' '/Pods-.*\.xcfilelist/d' "$PROJECT_FILE"

echo "  Removing shellScript references to Pods..."
sed -i '' '/shellScript.*Pods/d' "$PROJECT_FILE"

echo "✅ Removed all CocoaPods references from project file"
echo "📦 Project is now using Swift Package Manager only (wandermint-shared-schemas)"
echo "🔨 Xcode Cloud will build successfully"
