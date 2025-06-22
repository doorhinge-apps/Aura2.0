# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Aura 2.0 is a SwiftUI-based browser designed for iOS 26+ with cross-platform support for iOS, iPadOS, macOS, and VisionOS. This is a complete rewrite focused on bringing customizable desktop browser features to all Apple platforms.

## Build and Development Commands

Since this is an Xcode project, use these commands for development:

```bash
# Open the project in Xcode
open "Aura 2.0.xcodeproj"

# Build from command line (if needed)
xcodebuild -project "Aura 2.0.xcodeproj" -scheme "Aura 2.0" -destination "platform=iOS Simulator,name=iPhone 15" build

# Run tests
xcodebuild test -project "Aura 2.0.xcodeproj" -scheme "Aura 2.0" -destination "platform=iOS Simulator,name=iPhone 15"
```

## Code Architecture

### Core Structure
- **App Entry Point**: `Aura_2_0App.swift` - Main SwiftUI app with SwiftData model container and environment objects
- **Content Container**: `ContentContainer.swift` - Main content view coordinator
- **UI Root**: `ContentView.swift` - Primary UI entry point

### Data Layer
- **SwiftData**: Uses SwiftData for persistent storage with `SpaceData` as the main model
- **Storage Management**: `Core/Storage/` contains data models:
  - `BrowserTab.swift` - Runtime tab representation
  - `StoredTab.swift` - Persistent tab data
  - `SpaceData.swift` - Workspace/space data model
  - `TabType.swift` - Enum for tab types (primary, favorites, pinned)
  - `WebMetadata.swift` - Web page metadata storage

### View Models (ObservableObject)
Located in `Core/ViewModels/`:
- `StorageManager` - Manages tab storage and persistence
- `TabsManager` - Handles tab operations and state
- `UIViewModel` - UI state management
- `SettingsManager` - Application settings

### UI Architecture
- **Main UI**: `UI/WebsitePanel.swift` - Primary web browsing interface
- **Sidebar**: `UI/Sidebar Components/` - Navigation and tab management
  - Space-based organization with favorites, pinned, and primary tabs
  - Customizable icons and themes per space
- **Settings**: `UI/Settings/` - App configuration with subpages for different categories
- **Favicon System**: Custom favicon loading with `SDWebImageSwiftUI` dependency

### Key Features
- **Space-based Browsing**: Workspaces with different tab collections
- **Tab Types**: Primary, favorites, and pinned tab categories
- **Custom Scheme Handler**: `AuraSchemeHandler.swift` for internal URLs
- **Cross-platform Design**: Optimized for touch and traditional input methods

### Dependencies
- **SDWebImageSwiftUI** (3.1.3) - Image loading and caching for favicons
- **SwiftData** - Native persistence layer
- **WebKit** - Web browsing engine

### Development Notes
- Uses SwiftUI lifecycle with environment objects passed down from app root
- Command system implemented for keyboard shortcuts (Cmd+T, Cmd+W, etc.)
- Vision Pro specific UI adaptations in `HoverDisabledVision.swift`
- Launch screen uses storyboard with custom animation