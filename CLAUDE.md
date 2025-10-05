# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **边界舱 (Boundary Capsule)** - an iOS app for couples to manage personal space and communicate asynchronously. It's built with SwiftUI and targets iOS 15.6+.

## Development Commands

### Building & Running
- **Build**: `⌘+B` in Xcode or via Xcode's build system
- **Run**: `⌘+R` in Xcode
- **Clean Build**: `⌘+Shift+K` in Xcode

### Testing
- No automated test suite is currently set up
- Use SwiftUI previews for rapid UI iteration
- Manual testing via iOS Simulator or device

## Architecture

### Core Pattern
- **MVVM** with SwiftUI's native state management
- **@StateObject/@EnvironmentObject** for dependency injection
- **ObservableObject** classes for reactive state

### Key State Objects
- `UserState` - Current user's energy level, focus mode, temporary states
- `PartnerState` - Partner's state information
- `GrowthGarden` - Shared progress tracking between partners

### Navigation Structure
Three-tab app with `MainTabView`:
1. **我的空间 (My Space)** - Personal state management, energy planning
2. **我们的空间 (Our Space)** - Shared space for couple communication
3. **个人中心 (Profile)** - Settings and configuration

## Key Models & Enums

### EnergyLevel Enum
```swift
enum EnergyLevel: String, CaseIterable, Codable {
    case high = "🟢"      // 满血复活状态拉满
    case medium = "🟡"    // 血条还行但别催我
    case low = "🔴"       // 血槽空了莫挨老子
    case unplanned = "⚪"  // 待规划
}
```

### TemporaryStateType Enum
```swift
enum TemporaryStateType: String, CaseIterable, Codable {
    case fastCharge = "快充模式"    // Temporary high energy boost
    case lowPower = "低电量模式"    // Temporary low energy protection
}
```

## File Structure

```
Personal Space/
├── Personal_SpaceApp.swift          # App entry point
├── ContentView.swift               # Initial content view (likely unused)
├── AppModels.swift                 # Core models and state management (700+ lines)
├── Utils/
│   └── AppTheme.swift             # Centralized design system
├── Views/
│   ├── MainTabView.swift          # Main tab navigation
│   ├── MySpaceView.swift          # "My Space" tab implementation
│   ├── OurSpaceView.swift         # "Our Space" tab implementation
│   ├── ProfileView.swift          # Profile/Settings tab
│   ├── EnergyPlanningView.swift   # Energy planning feature
│   └── Components/                # Reusable UI components
│       ├── TemporaryStateButton.swift
│       ├── TemporaryStateTimePicker.swift
│       ├── TemporaryStateOverlay.swift
│       ├── TemporaryStateCountdownView.swift
│       ├── MoodChartView.swift
│       └── EnergyProgressView.swift
└── Assets.xcassets/               # App icons and assets
```

## Design System (AppTheme.swift)

### Colors
- **Primary**: `#2A9D8F` (Teal)
- **Energy States**: Green/Yellow/Red system matching emoji indicators
- **Card Background**: White with subtle shadows
- **Text**: `#2b2d42` primary, `#6c757d` secondary

### Spacing & Layout
- **Card Radius**: 20px consistent across app
- **Standard Spacing**: 8px, 12px, 16px, 20px, 24px, 32px intervals
- **Shadow System**: Subtle black opacity for depth

## Key Features

### Energy Signal System
- Visual mood indicators using colored circles (🟢🟡🔴⚪)
- Partner synchronization for status visibility
- Temporary state overrides (fast charge/low power modes)

### Temporary States
- Time-limited energy level overrides
- Countdown timers with visual feedback
- Automatic restoration to original state
- "Brush logic" for historical state visualization

### Focus Mode
- Do-not-disturb functionality
- Partner notification system
- App-wide silence when enabled

## Recent Development Focus

Based on recent commits, active work includes:
- Brush logic implementation for state visualization
- Temporary state countdown and timer systems
- Performance optimizations for state changes
- Color change logic for past time periods

## Documentation

- **边界舱-PRD.md**: Comprehensive Product Requirements Document (Chinese)
- **界面优化总结.md**: UI optimization summary and design decisions
- Inline code comments in Chinese throughout Swift files