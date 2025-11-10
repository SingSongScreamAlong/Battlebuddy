# BattleBuddy - Your AI Tactical Companion

A voice-first AI assistant iOS app built with SwiftUI that acts as your personal wingman for daily life.

## Project Status

**Current Phase:** Phase 6 - Intelligence & Companion Features ✅ COMPLETE! 🎉🚀

**Previous Phase:** Phase 5 - Polish & Integration ✅ COMPLETE - MVP FINISHED! 🎉

### Phase 1: Core Foundation ✅

- [x] SwiftUI app structure with TabView navigation
- [x] Core Data models (Task, UserPreferences, ConversationEntry, ReflectionLog)
- [x] HomeView with daily brief placeholder and greeting
- [x] TaskBoardView with full CRUD functionality
- [x] ReflectionLogView with mood tracking
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

### Phase 3: Calendar & Scheduling ✅

- [x] **CalendarService** - Full EventKit integration for iOS Calendar management
- [x] **Event creation** - Create events via UI and voice commands
- [x] **Conflict detection** - Real-time overlap warnings when scheduling events
- [x] **ScheduleView** - Complete calendar interface with date picker and event list
- [x] **Bidirectional sync** - Read and write events to iOS Calendar
- [x] **Natural language parsing** - "Schedule meeting tomorrow at 3pm" extracts time and date
- [x] **Calendar permissions** - Elegant permission request flow
- [x] **Event management** - Create, view, delete events with context menu
- [x] **Voice scheduling** - Say "schedule lunch with John tomorrow at noon"

### Phase 4: Intelligence & Notifications ✅

- [x] **NotificationService** - Full UNUserNotificationCenter integration with authorization
- [x] **WeatherService** - OpenWeather API integration with location-based weather data
- [x] **DailyBriefService** - Intelligent brief generation combining weather, tasks, and events
- [x] **Morning brief notifications** - Scheduled daily notifications with custom times
- [x] **Evening reflection prompts** - Scheduled daily reflection reminders
- [x] **Live daily brief in HomeView** - Real-time weather, task summary, schedule overview
- [x] **Speak daily brief** - Text-to-speech playback of the daily brief
- [x] **Weather display** - Temperature, conditions, and location-aware forecasts
- [x] **Notification permissions** - Elegant permission request flow in Settings
- [x] **API key management** - Secure Keychain storage for OpenWeather API key
- [x] **Proactive scheduling** - Automatic notification scheduling based on user preferences

### Phase 5: Polish & Integration ✅

- [x] **MessageService** - Full iMessage integration for sending texts via voice commands
- [x] **Message intent parsing** - Natural language parsing for "text Sarah I'll be late"
- [x] **Contact integration** - CNContactStore integration to find recipients by name
- [x] **Message composer** - UIViewControllerRepresentable wrapper for MFMessageComposeViewController
- [x] **AnimationHelpers** - Reusable animation library with custom springs, transitions, and effects
- [x] **Enhanced waveform** - Improved audio visualization with glow effects and spring animations
- [x] **Circular waveform** - Alternative radial waveform design with pulse rings
- [x] **Smart context management** - Token-aware conversation history with automatic pruning
- [x] **Context awareness** - Enhanced system prompts with task/calendar context
- [x] **Smooth animations** - Spring-based animations for task completion and UI interactions
- [x] **UI polish** - Refined transitions, shadows, and visual feedback throughout the app

### Phase 6: Intelligence & Companion Features ✅

- [x] **MemoryService** - Long-term memory system that learns user preferences, patterns, and goals
- [x] **ProactiveService** - Intelligent suggestions and check-ins based on time, context, and behavior
- [x] **GoalService** - Goal tracking with progress visualization and achievement system
- [x] **CostTrackingService** - API usage monitoring with budget management and insights
- [x] **Enhanced AIService** - Emotional intelligence, mood detection, and memory-aware conversations
- [x] **Sentiment analysis** - Detects user emotion and adapts AI tone accordingly
- [x] **Pattern learning** - Automatically learns from conversations (preferences, training, relationships)
- [x] **Time-aware context** - AI knows time of day and day of week for contextual responses
- [x] **OnboardingView** - Interactive tutorial with voice command guide and feature walkthrough
- [x] **GoalDashboardView** - Goal creation, progress tracking, and achievement unlocking
- [x] **InsightsView** - Mood trends, behavioral patterns, and personalized analytics
- [x] **CostDashboardView** - Budget tracking, spending charts, and cost-saving tips
- [x] **Proactive suggestions** - Context-aware suggestions displayed in HomeView
- [x] **Budget alerts** - Real-time warnings when approaching or exceeding API budget
- [x] **Achievement system** - 13 unlockable achievements for app engagement
- [x] **User profile stats** - Track streaks, total conversations, and goals completed
- [x] **Mood-aware AI** - AI adapts personality based on recent reflection log moods
- [x] **Preference memory** - AI remembers likes, dislikes, and important people
- [x] **Cost transparency** - Track every API call with accurate token usage and cost estimates

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

**Required for AI and Weather features:**

**OpenAI API Key (required for Phase 2+ AI features):**
1. Get your API key from [platform.openai.com](https://platform.openai.com)
2. Build and run the app
3. Go to Settings tab
4. Enter your API key in the "OpenAI API Key" field (stored securely in Keychain)

**OpenWeather API Key (optional for Phase 4 weather features):**
1. Get your free API key from [openweathermap.org](https://openweathermap.org/api)
2. Go to Settings tab
3. Enter your API key in the "OpenWeather API Key" field (stored securely in Keychain)
4. Grant location permissions when prompted for weather data

### 4. Build and Run

1. Select your target device (iPhone simulator or physical device)
2. Press `Cmd + R` to build and run
3. Grant permissions when prompted:
   - Microphone (Phase 2 - for voice commands)
   - Calendar (Phase 3 - for event management)
   - Reminders (Phase 3 - for task sync)
   - Notifications (Phase 4 - for daily brief and reminders)
   - Location (Phase 4 - for weather data)

## Project Structure

```
BattleBuddy/
├── BattleBuddyApp.swift         # App entry point and state management
├── ContentView.swift             # Main TabView navigation
├── Info.plist                    # App configuration and permissions
├── Models/
│   ├── PersistenceController.swift                   # Core Data stack
│   ├── BattleBuddy.xcdatamodeld/                    # Core Data model
│   ├── TaskEntity+CoreDataClass.swift
│   ├── UserPreferencesEntity+CoreDataClass.swift
│   ├── ReflectionLogEntity+CoreDataClass.swift
│   ├── ConversationEntryEntity+CoreDataClass.swift
│   ├── GoalEntity+CoreDataClass.swift                # Phase 6 ✅
│   ├── AIMemoryEntity+CoreDataClass.swift            # Phase 6 ✅
│   ├── CostTrackingEntity+CoreDataClass.swift        # Phase 6 ✅
│   ├── ProactiveSuggestionEntity+CoreDataClass.swift # Phase 6 ✅
│   ├── AchievementEntity+CoreDataClass.swift         # Phase 6 ✅
│   └── UserProfileEntity+CoreDataClass.swift         # Phase 6 ✅
├── Views/
│   ├── HomeView.swift                   # Dashboard with proactive suggestions (Phase 6 ✅)
│   ├── VoiceInterfaceView.swift         # Voice conversation UI (Phase 2)
│   ├── TaskBoardView.swift              # Task management
│   ├── ScheduleView.swift               # Calendar integration (Phase 3)
│   ├── ReflectionLogView.swift          # Daily mood tracking
│   ├── SettingsView.swift               # User preferences
│   ├── OnboardingView.swift             # Interactive tutorial (Phase 6 ✅)
│   ├── GoalDashboardView.swift          # Goal tracking & achievements (Phase 6 ✅)
│   ├── InsightsView.swift               # Mood trends & analytics (Phase 6 ✅)
│   └── CostDashboardView.swift          # Budget management (Phase 6 ✅)
├── Services/
│   ├── VoiceService.swift               # Speech-to-text/text-to-speech (Phase 2 ✅)
│   ├── AIService.swift                  # OpenAI with emotional intelligence (Phase 2, 5, 6 ✅)
│   ├── TaskService.swift                # Task management logic (Phase 2 ✅)
│   ├── CalendarService.swift            # EventKit wrapper (Phase 3 ✅)
│   ├── NotificationService.swift        # Local notifications (Phase 4 ✅)
│   ├── WeatherService.swift             # OpenWeather API integration (Phase 4 ✅)
│   ├── DailyBriefService.swift          # Intelligent brief generation (Phase 4 ✅)
│   ├── MessageService.swift             # iMessage integration (Phase 5 ✅)
│   ├── MemoryService.swift              # Long-term learning (Phase 6 ✅)
│   ├── ProactiveService.swift           # Intelligent suggestions (Phase 6 ✅)
│   ├── GoalService.swift                # Goal & achievement system (Phase 6 ✅)
│   └── CostTrackingService.swift        # API usage monitoring (Phase 6 ✅)
└── Utilities/
    ├── ColorExtension.swift      # Theme colors
    ├── KeychainHelper.swift      # Secure API key storage (Phase 2 ✅)
    └── AnimationHelpers.swift    # Reusable animations and transitions (Phase 5 ✅)
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

### Phase 3: Calendar & Scheduling ✅

- iOS Calendar integration via EventKit
- Event creation via UI and voice commands
- Real-time conflict detection with overlap warnings
- Complete schedule display with graphical date picker
- Natural language date/time parsing
- Bidirectional calendar sync (read/write)
- Calendar permission management

### Phase 4: Intelligence & Notifications ✅

- Local notification system with UNUserNotificationCenter
- OpenWeather API integration for real-time weather data
- Intelligent daily brief generation combining weather, tasks, and calendar
- Morning brief notifications with custom scheduling
- Evening reflection prompt notifications
- Live daily brief display in HomeView with refresh and speak features
- Weather display with temperature, conditions, and location
- Notification permission management in Settings
- Proactive scheduling based on user preferences
- Location-based weather forecasting

### Phase 5: Polish & Integration ✅

- iMessage integration with MessageUI framework
- Contact search by name using CNContactStore
- Natural language message parsing ("text Sarah I'll be late")
- Voice-to-text message composition
- Custom animation library with spring physics and transitions
- Enhanced audio waveform with glow effects
- Circular waveform alternative design with pulse rings
- Smart conversation context management with token counting
- Automatic context pruning for optimal performance
- Spring-based UI animations for smooth interactions
- Polished visual feedback and transitions throughout app

### Phase 6: Intelligence & Companion Features ✅

- **True AI Companion** - The app now truly acts as a personal wingman that knows you
- **Long-term memory system** - Remembers preferences, patterns, people, and goals across sessions
- **Emotional intelligence** - Detects mood from reflections and adapts AI tone accordingly
- **Proactive suggestions** - Context-aware suggestions based on time, tasks, mood, and behavior
- **Goal tracking with achievements** - Set goals, track progress, unlock 13 achievements
- **Cost transparency** - Track every API call with accurate token counting and budget alerts
- **Pattern learning** - Automatically learns from conversations (likes, dislikes, training, relationships)
- **Time-aware AI** - Knows time of day, day of week, and adjusts personality accordingly
- **Interactive onboarding** - Beautiful tutorial with voice command guide for first-time users
- **Mood trend analysis** - Visualize 7-day mood patterns with insights and wellbeing suggestions
- **Budget management** - Set monthly budget, get alerts, view spending charts and projections
- **User profile stats** - Track streaks, total conversations, tasks completed, and goals achieved
- **Memory insights** - View what the AI has learned about you in the Insights tab
- **Behavioral analytics** - See patterns in workout times, productivity peaks, and habits
- **Cost-saving tips** - AI suggests ways to reduce API usage and stay within budget
- **Proactive check-ins** - Morning motivation, break reminders, goal progress nudges
- **Achievement gamification** - Unlock badges for streaks, tasks, conversations, and goals
- **Enhanced HomeView** - Shows proactive suggestions and budget warnings front and center

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
- "Schedule [event] tomorrow at [time]" - Creates a calendar event
- "What's on my schedule?" - Shows calendar events
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

### Scheduling Events (Phase 3)

**Via Voice:**
- "Schedule meeting with team tomorrow at 3pm"
- "Schedule lunch at noon today"
- "Schedule dentist appointment next Monday at 10am"

**Via UI:**
1. Go to the "Schedule" tab
2. Grant calendar permissions if prompted
3. Select a date from the calendar
4. Tap the floating "+" button
5. Enter event details (title, time, location, notes)
6. The app will warn you if there are conflicts
7. Tap "Add"

Events are synced with your iOS Calendar and visible across all your devices.

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

- Portrait orientation only
- iPhone only (no iPad optimization)
- Requires OpenAI API key (not included)
- Requires OpenWeather API key for weather features (not included)
- Internet connection required for AI, weather, and messaging features
- Location permission required for weather data
- Contacts permission required for message recipient lookup
- Message sending requires iOS device (not available in simulator)

## Future Enhancements (Post-Phase 6)

- Apple Watch companion app with goal and achievement sync
- Wake word detection ("Hey BattleBuddy")
- Web research capabilities for fact-checking
- ~~Goal tracking with progress visualization~~ ✅ **Completed in Phase 6**
- Multi-user support with family sharing
- Siri Shortcuts integration for voice automation
- iPad and Mac versions with optimized layouts
- Offline mode with cached AI responses
- Cloud sync via CloudKit for cross-device memory
- Social features - share achievements with friends
- Advanced analytics - monthly reports and insights

## Contributing

This is an actively developed project. Phases are built incrementally following the development brief.

## License

Copyright © 2025. All rights reserved.

---

**Built with:** Swift 5.9, SwiftUI, Core Data, EventKit, UserNotifications, CoreLocation, MessageUI, Contacts, iOS Speech Framework, AVFoundation

**Status:** Phase 6 Complete - TRUE AI COMPANION FEATURES ADDED! 🎉🚀

**Version:** 6.0.0 (Intelligence & Companion Update)

**What's New in Phase 6:**
- 🧠 Long-term memory that learns your preferences
- 💡 Proactive suggestions based on context and time
- 🎯 Goal tracking with 13 unlockable achievements
- 💰 Budget tracking with spending insights
- 😊 Mood-aware AI that adapts to your emotional state
- 📊 Analytics dashboard showing patterns and trends
- 🎓 Interactive onboarding for new users
