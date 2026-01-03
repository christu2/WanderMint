# iOS Swift Package Integration Guide

## Integrate @wandermint/shared-schemas into WanderMint iOS App

### Step 1: Add Swift Package Dependency in Xcode

1. **Open your iOS project:**
   ```bash
   open /Users/nick/Development/travelBusiness/WanderMint/WanderMint.xcodeproj
   ```

2. **Add Package Dependency:**
   - In Xcode, select your project in the Navigator (WanderMint - the blue icon at the top)
   - Select the **WanderMint** project (not the target)
   - Click on the **Package Dependencies** tab
   - Click the **+** button at the bottom

3. **Enter Package URL:**
   - In the dialog, paste this URL:
     ```
     https://github.com/christu2/wandermint-shared-schemas
     ```
   - Click "Add Package"

4. **Select Version:**
   - **Dependency Rule**: Select "Up to Next Major Version"
   - **Version**: Enter `1.0.0`
   - Click "Add Package"

5. **Add to Target:**
   - In the next dialog, ensure **WanderMintSchemas** is checked
   - Under "Add to Target", select **WanderMint**
   - Click "Add Package"

### Step 2: Verify Installation

1. **Check Package Dependencies:**
   - In Project Navigator, you should now see:
     ```
     Package Dependencies
     └── wandermint-shared-schemas
     ```

2. **Build the project:**
   - Press `Cmd + B` to build
   - Should build successfully

### Step 3: Update Code to Use Package

Your code already uses `Budget` and `TravelStyle` enums from the local file `WanderMint/Models/WanderMintSchemas.swift`.

Now you need to:

1. **Add import statement** to `TripSubmissionView.swift`:
   ```swift
   import WanderMintSchemas
   ```

2. **Remove local file** (optional, after verifying package works):
   - Select `WanderMint/Models/WanderMintSchemas.swift` in Navigator
   - Press Delete
   - Choose "Move to Trash"

### Step 4: Test Everything Works

1. **Build the app** (`Cmd + B`)
2. **Run on simulator** (`Cmd + R`)
3. **Test trip submission:**
   - Navigate to trip submission screen
   - Verify budget dropdown shows all 5 options
   - Verify travelStyle dropdown shows all 5 options
   - Submit a test trip
   - Should work without errors

### Step 5: Commit Changes

```bash
cd /Users/nick/Development/travelBusiness/WanderMint

# Add the package dependency changes
# (Xcode automatically updates these files when you add a package)
git add WanderMint.xcodeproj/project.pbxproj
git add WanderMint.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved

# If you removed the local file:
git add WanderMint/Models/

# If you added import statement:
git add WanderMint/Views/TripSubmissionView.swift

git commit -m "Integrate wandermint-shared-schemas Swift Package

- Add Swift Package dependency via SPM
- Remove local WanderMintSchemas.swift (now using package)
- Import WanderMintSchemas from package

Benefits:
- Version-controlled schema updates
- Easy to update: Xcode → File → Packages → Update to Latest
- Automatic sync with Backend and Admin"

git push
```

---

## Updating the Package Later

### When shared-schemas is updated to v1.1.0:

**Method 1: Xcode UI (Recommended)**

1. File → Packages → Update to Latest Package Versions
2. Xcode will fetch v1.1.0 automatically
3. Build and test

**Method 2: Specific Version**

1. Select project in Navigator
2. Go to Package Dependencies tab
3. Select `wandermint-shared-schemas`
4. Change version to `1.1.0`
5. Xcode will download and resolve

**Method 3: Command Line**

```bash
cd /Users/nick/Development/travelBusiness/WanderMint

# Remove resolved packages (forces update)
rm -rf WanderMint.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved

# Xcode will re-resolve on next build
open WanderMint.xcodeproj
# Then: Product → Clean Build Folder (Cmd+Shift+K)
# Then: Build (Cmd+B)
```

---

## Troubleshooting

### "No such module 'WanderMintSchemas'"

**Solution:**
- Make sure package was added to the **WanderMint** target
- Clean build folder: Product → Clean Build Folder (Cmd+Shift+K)
- Rebuild: Cmd+B

### Package not appearing in dependencies

**Solution:**
```bash
# Clear Xcode caches
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf ~/Library/Developer/Xcode/DerivedData

# Reopen Xcode
open WanderMint.xcodeproj
```

### Build errors after adding package

**Solution:**
- Make sure you added `import WanderMintSchemas` at the top of any file using Budget/TravelStyle
- If you kept the local file, there may be conflicts - remove one or the other

---

## Current Status

- ✅ Package is ready at: https://github.com/christu2/wandermint-shared-schemas
- ✅ Version v1.0.0 is tagged and available
- ✅ Swift Package Manager can find and download it
- ⏳ Waiting for you to add it in Xcode (see steps above)

Once you complete these steps, all three platforms will be using the shared schemas package! 🎉
