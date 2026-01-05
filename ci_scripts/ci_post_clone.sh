#!/bin/sh

# Xcode Cloud post-clone script
# This script runs after Xcode Cloud clones the repository

set -e

echo "🔧 Xcode Cloud: Running post-clone script..."

# Navigate to repository root (script runs from ci_scripts directory)
cd ..

echo "📦 Removing Podfile to prevent CocoaPods from running..."
if [ -f "Podfile" ]; then
    rm -f Podfile Podfile.lock
    echo "  ✅ Removed Podfile and Podfile.lock"
else
    echo "  ℹ️  No Podfile found (already removed)"
fi

if [ -d "Pods" ]; then
    rm -rf Pods
    echo "  ✅ Removed Pods directory"
fi

echo ""
echo "📝 Note: Project still has CocoaPods references in project.pbxproj"
echo "   This is intentional - editing project.pbxproj in CI is too risky"
echo "   Without Podfile, CocoaPods won't run and build should succeed with warnings"
echo ""
echo "✅ Post-clone script completed"
echo "🔨 Building with Swift Package Manager only (wandermint-shared-schemas)"
