# BattleBuddy - Your AI Tactical Companion

A voice-first AI assistant iOS app built with SwiftUI that acts as your personal wingman for daily life.

## Project Status

**Current Phase:** Phase 2 - Voice & AI ✅ COMPLETE

### Phase 1: Core Foundation ✅

- [x] SwiftUI app structure with TabView navigation
- [x] Core Data models (Task, UserPreferences, ConversationEntry, ReflectionLog)
- [x] HomeView with daily brief placeholder and greeting
- [x] TaskBoardView with full CRUD functionality
- [x] ReflectionLogView with mood tracking
- [x] ScheduleView placeholder (Calendar integration in Phase 3)
- [x] SettingsView with user preferences
- [x] Dark theme with tactical color palette
- [x] Priority-based task sorting (High/Medium/Low)
- [x] Swipe-to-delete for tasks
- [x] Mode switching system (Operator/Companion/Strategist)

### Phase 2: Voice & AI ✅

- [x] **VoiceService** - Full speech-to-text and text-to-speech integration using iOS Speech Framework
- [x] **AIService** - OpenAI GPT-4 API client with conversation context and streaming support
- [x] **Real-time voice interface** - Tap-and-hold mic button with live transcription preview
- [x] **Intent parsing** - Extracts commands like "add task", "list tasks" from natural language
- [x] **Animated waveform** - Real-time audio level visualization during listening/speaking
- [x] **Conversation history** - Persistent chat history stored in Core Data with context management
- [x] **Permission flow** - Elegant microphone permission request UI
- [x] **Keychain security** - Secure API key storage using iOS Keychain
- [x] **Service layer architecture** - TaskService abstraction for cleaner code organization
- [x] **Error handling** - User-friendly error banners with retry logic
- [x] **Voice-to-task creation** - Say "add task buy groceries" to create tasks hands-free
- [x] **Mode-specific AI prompts** - Personality adapts to Operator/Companion/Strategist modes

### Next Up: Phase 3 - Calendar & Scheduling

- [ ] CalendarService with EventKit integration
- [ ] Event creation via voice
- [ ] Conflict detection
- [ ] ScheduleView implementation
- [ ] Bidirectional calendar sync

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

### 3. Configure API Keys

**Required for Phase 2 AI features:**

1. Get your API key from [platform.openai.com](https://platform.openai.com)
2. Build and run the app
3. Go to Settings tab
4. Enter your API key in the "OpenAI API Key" field (stored securely in Keychain)
5. Go to Voice tab and grant microphone permissions when prompted

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
├── Services/
│   ├── VoiceService.swift        # Speech-to-text/text-to-speech (Phase 2 ✅)
│   ├── AIService.swift           # OpenAI integration (Phase 2 ✅)
│   ├── TaskService.swift         # Task management logic (Phase 2 ✅)
│   ├── CalendarService.swift     # EventKit wrapper (Phase 3)
│   └── NotificationService.swift # Push notifications (Phase 4)
└── Utilities/
    ├── ColorExtension.swift      # Theme colors
    └── KeychainHelper.swift      # Secure API key storage (Phase 2 ✅)
```

## Features by Phase

### Phase 1: Core Foundation ✅

- Basic SwiftUI structure
- Core Data persistence
- Task management (create, edit, delete, complete)
- Daily reflection logging
- User preferences
- Mode selection (Operator/Companion/Strategist)

### Phase 2: Voice & AI ✅

- Speech-to-text input using iOS Speech Framework
- Text-to-speech output using AVSpeechSynthesizer
- OpenAI GPT-4 API integration with context management
- Conversational AI with mode-specific personalities
- Intent parsing for voice commands ("add task", "list tasks", etc.)
- Real-time waveform visualization
- Microphone permission handling
- Secure API key storage in Keychain
- Service layer architecture for clean separation of concerns

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

### Voice Conversations (Phase 2)

1. Go to the "Voice" tab
2. Grant microphone permissions if prompted
3. **Tap and hold** the microphone button
4. Speak your message or command
5. Release to send
6. BattleBuddy will process, respond, and speak the answer

**Voice Commands:**
- "Add task [name]" - Creates a new task
- "List my tasks" - Shows your tasks
- "What's on my schedule?" - Shows calendar events (Phase 3)
- Or just chat naturally!

### Creating Tasks

**Via Voice:**
- "Add task buy groceries"
- "Create a task to call mom"

**Via UI:**
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
3. Choose your default AI mode (Operator/Companion/Strategist)
4. Configure notification times
5. Add your OpenAI API key (required for AI features)

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

- No calendar integration yet (Phase 3)
- No notifications yet (Phase 4)
- No iMessage integration yet (Phase 5)
- Portrait orientation only
- iPhone only (no iPad optimization)
- Requires OpenAI API key (not included)
- Internet connection required for AI features

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

**Built with:** Swift 5.9, SwiftUI, Core Data, iOS Speech Framework, AVFoundation
**Status:** Phase 2 Complete - Voice & AI Fully Operational
**Version:** 2.0.0 (MVP)
