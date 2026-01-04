#!/bin/sh

# Xcode Cloud post-clone script
# This script runs after Xcode Cloud clones the repository

set -e

echo "🔧 Xcode Cloud: Running post-clone script..."

# The project has legacy CocoaPods references but we use Swift Package Manager now
# Remove the xcconfig file references that Xcode Cloud can't find

echo "📦 Removing CocoaPods xcconfig references from Xcode project..."

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

# Remove baseConfigurationReference lines that point to Pods xcconfig files
# This prevents "Unable to open base configuration reference file" errors
sed -i '' '/baseConfigurationReference.*Pods.*xcconfig/d' "$PROJECT_FILE"

# Remove Pods framework references from the Frameworks build phase
sed -i '' '/Pods_.*\.framework in Frameworks/d' "$PROJECT_FILE"

echo "✅ Removed CocoaPods references from project file"
echo "📦 Project is using Swift Package Manager (wandermint-shared-schemas)"
echo "🔨 Xcode Cloud will now build successfully"
