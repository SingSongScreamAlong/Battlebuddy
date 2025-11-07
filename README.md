# BattleBuddy - Your AI Tactical Companion

A voice-first AI assistant iOS app built with SwiftUI that acts as your personal wingman for daily life.

## Project Status

**Current Phase:** Phase 1 - Core Foundation ✅ COMPLETE

### Completed Features

- [x] SwiftUI app structure with TabView navigation
- [x] Core Data models (Task, UserPreferences, ConversationEntry, ReflectionLog)
- [x] HomeView with daily brief placeholder and greeting
- [x] TaskBoardView with full CRUD functionality
- [x] ReflectionLogView with mood tracking
- [x] ScheduleView placeholder (Calendar integration in Phase 3)
- [x] VoiceInterfaceView placeholder (Voice services in Phase 2)
- [x] SettingsView with user preferences
- [x] Dark theme with tactical color palette
- [x] Priority-based task sorting (High/Medium/Low)
- [x] Swipe-to-delete for tasks
- [x] Mode switching system (Operator/Companion/Strategist)

### Next Up: Phase 2 - Voice & AI

- [ ] VoiceService implementation (speech-to-text, text-to-speech)
- [ ] OpenAI GPT-4 API integration
- [ ] Real-time voice conversation
- [ ] Intent parsing for voice commands
- [ ] Animated waveform visualization

## Requirements

- **iOS:** 17.0+
- **Xcode:** 15.0+
- **Swift:** 5.9+
- **Device:** iPhone (portrait only for MVP)

## Setup Instructions

### 1. Clone the Repository

```bash
git clone <repository-url>
cd Battlebuddy
```

### 2. Open in Xcode

```bash
open BattleBuddy/BattleBuddy.xcodeproj
```

### 3. Configure API Keys (Phase 2+)

For Phase 2 AI integration, you'll need an OpenAI API key:

1. Get your API key from [platform.openai.com](https://platform.openai.com)
2. Open the app and go to Settings tab
3. Enter your API key in the "OpenAI API Key" field

### 4. Build and Run

1. Select your target device (iPhone simulator or physical device)
2. Press `Cmd + R` to build and run
3. Grant permissions when prompted:
   - Microphone (Phase 2)
   - Calendar (Phase 3)
   - Reminders (Phase 3)
   - Notifications (Phase 4)

## Project Structure

```
BattleBuddy/
├── BattleBuddyApp.swift         # App entry point and state management
├── ContentView.swift             # Main TabView navigation
├── Info.plist                    # App configuration and permissions
├── Models/
│   ├── PersistenceController.swift           # Core Data stack
│   ├── BattleBuddy.xcdatamodeld/            # Core Data model
│   ├── TaskEntity+CoreDataClass.swift
│   ├── UserPreferencesEntity+CoreDataClass.swift
│   ├── ReflectionLogEntity+CoreDataClass.swift
│   └── ConversationEntryEntity+CoreDataClass.swift
├── Views/
│   ├── HomeView.swift            # Dashboard with daily brief
│   ├── VoiceInterfaceView.swift  # Voice conversation UI (Phase 2)
│   ├── TaskBoardView.swift       # Task management
│   ├── ScheduleView.swift        # Calendar integration (Phase 3)
│   ├── ReflectionLogView.swift   # Daily mood tracking
│   └── SettingsView.swift        # User preferences
├── Services/                     # Coming in Phase 2+
│   ├── VoiceService.swift        # Speech-to-text/text-to-speech
│   ├── AIService.swift           # OpenAI integration
│   ├── TaskService.swift         # Task management logic
│   ├── CalendarService.swift     # EventKit wrapper
│   └── NotificationService.swift # Push notifications
└── Utilities/
    └── ColorExtension.swift      # Theme colors
```

## Features by Phase

### Phase 1: Core Foundation ✅

- Basic SwiftUI structure
- Core Data persistence
- Task management (create, edit, delete, complete)
- Daily reflection logging
- User preferences
- Mode selection (Operator/Companion/Strategist)

### Phase 2: Voice & AI (Next)

- Speech-to-text input
- Text-to-speech output
- OpenAI GPT-4 integration
- Conversational AI with context
- Intent parsing for commands

### Phase 3: Calendar & Scheduling

- iOS Calendar integration via EventKit
- Event creation via voice
- Conflict detection
- Schedule display

### Phase 4: Intelligence & Notifications

- Daily morning brief generation
- Evening reflection prompts
- Proactive notifications
- Weather integration

### Phase 5: Polish & Integration

- iMessage integration
- Smooth animations
- Voice waveform visualization
- Context memory system
- Final UI polish

## Design System

### Color Palette

- **Background:** `#1a1a1a` (slate black)
- **Card Background:** `#2d2d2d` (dark gray)
- **Accent:** `#3b82f6` (electric blue)
- **Secondary:** `#6b7280` (tactical gray)
- **Success:** `#10b981` (green)
- **Warning:** `#f59e0b` (amber)
- **Text Primary:** `#ffffff` (white)
- **Text Secondary:** `#9ca3af` (light gray)

### AI Modes

- **Operator Mode:** Amber (`#f59e0b`) - Concise, tactical responses
- **Companion Mode:** Blue (`#3b82f6`) - Warm, supportive tone
- **Strategist Mode:** Purple (`#8b5cf6`) - Analytical, planning-focused

## Usage

### Creating Tasks

1. Go to the "Tasks" tab
2. Tap the floating "+" button
3. Enter task title and select priority
4. Optionally set a due date
5. Tap "Add"

Tasks are automatically sorted by priority (High → Medium → Low) and completion status.

### Daily Reflections

1. Go to the "Reflect" tab
2. Tap the "+" button
3. Select your mood for the day
4. Optionally add notes
5. Tap "Save"

Reflections are stored chronologically with mood emoji indicators.

### Settings

1. Go to the "Settings" tab
2. Set your name for personalized greetings
3. Choose your default AI mode
4. Configure notification times
5. Add your OpenAI API key (Phase 2)

## Development Notes

### Core Data

- **Automatic merging** enabled for background updates
- **Preview data** generated for SwiftUI previews
- **Singleton preferences** pattern for user settings
- All entities use UUID as primary key

### SwiftUI Patterns

- **Environment objects** for app-wide state
- **FetchRequest** for reactive Core Data queries
- **ObservedObject** for Core Data entities
- Dark mode enforced via `.preferredColorScheme(.dark)`

### Code Style

- SwiftUI declarative syntax
- Extracted subviews for reusability
- MARK comments for organization
- Preview providers for all views

## Known Limitations (MVP)

- No voice functionality yet (Phase 2)
- No calendar integration yet (Phase 3)
- No AI conversations yet (Phase 2)
- No notifications yet (Phase 4)
- Portrait orientation only
- iPhone only (no iPad optimization)

## Future Enhancements (Post-MVP)

- Apple Watch companion app
- Wake word detection ("Hey BattleBuddy")
- Web research capabilities
- Goal tracking with progress visualization
- Multi-user support
- Siri Shortcuts integration
- iPad and Mac versions

## Contributing

This is an MVP development project. Phases are built incrementally following the development brief.

## License

Copyright © 2025. All rights reserved.

---

**Built with:** Swift 5.9, SwiftUI, Core Data
**Status:** Phase 1 Complete - Ready for Phase 2
**Version:** 1.0.0 (MVP)
