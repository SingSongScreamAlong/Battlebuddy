//
//  VoiceInterfaceView.swift
//  BattleBuddy
//
//  Voice interface with mic button and conversation history
//

import SwiftUI
import CoreData

struct VoiceInterfaceView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appState: AppState

    @StateObject private var voiceService = VoiceService()
    @StateObject private var aiService: AIService

    @State private var showPermissionRequest = false
    @State private var currentTranscript = ""
    @State private var statusMessage = ""
    @State private var scrollToBottom = false

    init() {
        let context = PersistenceController.shared.container.viewContext
        _aiService = StateObject(wrappedValue: AIService(context: context))
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.bbBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Mode selector
                    Picker("Mode", selection: $appState.currentMode) {
                        ForEach(AppState.AIMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    .background(Color.bbBackground)

                    Divider()
                        .background(Color.bbSecondary.opacity(0.3))

                    // Conversation history
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 16) {
                                if appState.conversationHistory.isEmpty {
                                    EmptyConversationView()
                                } else {
                                    ForEach(appState.conversationHistory) { entry in
                                        ConversationBubble(entry: entry)
                                            .id(entry.id)
                                    }
                                }

                                // Active transcript preview
                                if !currentTranscript.isEmpty && voiceService.isListening {
                                    TranscriptPreview(text: currentTranscript)
                                }

                                Color.clear
                                    .frame(height: 1)
                                    .id("bottom")
                            }
                            .padding()
                        }
                        .onChange(of: appState.conversationHistory.count) { _ in
                            withAnimation {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                        .onChange(of: currentTranscript) { _ in
                            withAnimation {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                    }

                    // Bottom control area
                    VStack(spacing: 8) {
                        // Status message
                        if !statusMessage.isEmpty {
                            Text(statusMessage)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(aiService.isProcessing ? .bbAccent : .bbTextSecondary)
                                .padding(.horizontal)
                        }

                        // Waveform
                        if voiceService.isListening || voiceService.isSpeaking {
                            WaveformView(
                                audioLevel: voiceService.audioLevel,
                                isActive: voiceService.isListening || voiceService.isSpeaking
                            )
                            .transition(.opacity)
                        }

                        // Mic button
                        MicButton(
                            isListening: voiceService.isListening,
                            isSpeaking: voiceService.isSpeaking,
                            isProcessing: aiService.isProcessing,
                            accentColor: appState.currentMode.accentColor
                        ) {
                            handleMicButtonPress()
                        } onRelease: {
                            handleMicButtonRelease()
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                    .background(Color.bbBackground)
                }

                // Error overlay
                if let error = aiService.lastError {
                    ErrorBanner(message: error) {
                        aiService.lastError = nil
                    }
                }
            }
            .navigationTitle("BattleBuddy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            clearHistory()
                        }) {
                            Label("Clear History", systemImage: "trash")
                        }

                        Button(action: {
                            testVoice()
                        }) {
                            Label("Test Voice", systemImage: "speaker.wave.2")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.bbAccent)
                    }
                }
            }
            .sheet(isPresented: $showPermissionRequest) {
                PermissionRequestView(isPresented: $showPermissionRequest) {
                    // Permission granted
                }
            }
            .onAppear {
                loadConversationHistory()
                checkPermissions()
            }
        }
    }

    // MARK: - Actions
    private func handleMicButtonPress() {
        guard voiceService.permissionStatus == .authorized else {
            showPermissionRequest = true
            return
        }

        if voiceService.isSpeaking {
            voiceService.stopSpeaking()
            return
        }

        statusMessage = "Listening..."
        currentTranscript = ""

        voiceService.startListening { transcript in
            currentTranscript = transcript
        }
    }

    private func handleMicButtonRelease() {
        guard voiceService.isListening else { return }

        voiceService.stopListening()

        let finalTranscript = currentTranscript
        currentTranscript = ""

        guard !finalTranscript.isEmpty else {
            statusMessage = ""
            return
        }

        // Process with AI
        processUserMessage(finalTranscript)
    }

    private func processUserMessage(_ message: String) {
        statusMessage = "Thinking..."

        // Parse intent
        if let intent = aiService.parseIntent(message) {
            handleIntent(intent, originalMessage: message)
        }

        // Send to AI
        Task {
            await aiService.sendMessage(message, mode: appState.currentMode) { response in
                // Add to conversation history
                let entry = ConversationEntry(
                    userMessage: message,
                    aiResponse: response,
                    timestamp: Date(),
                    mode: appState.currentMode
                )

                appState.conversationHistory.append(entry)

                // Speak response
                statusMessage = "Speaking..."
                voiceService.speak(response) {
                    statusMessage = ""
                }
            }
        }
    }

    private func handleIntent(_ intent: Intent, originalMessage: String) {
        switch intent {
        case .createTask(let title):
            let taskService = TaskService(context: viewContext)
            _ = taskService.createTask(title: title, priority: "Medium")
            statusMessage = "Task created: \(title)"

        case .listTasks:
            let taskService = TaskService(context: viewContext)
            let tasks = taskService.fetchTasks(completed: false)
            print("Found \(tasks.count) tasks")

        default:
            break
        }
    }

    private func checkPermissions() {
        Task {
            let granted = await voiceService.requestPermissions()
            if !granted && voiceService.permissionStatus == .notDetermined {
                await MainActor.run {
                    showPermissionRequest = true
                }
            }
        }
    }

    private func loadConversationHistory() {
        let request: NSFetchRequest<ConversationEntryEntity> = ConversationEntryEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ConversationEntryEntity.timestamp, ascending: true)]
        request.fetchLimit = 20

        if let conversations = try? viewContext.fetch(request) {
            appState.conversationHistory = conversations.map { entity in
                ConversationEntry(
                    userMessage: entity.userMessage,
                    aiResponse: entity.aiResponse,
                    timestamp: entity.timestamp,
                    mode: AppState.AIMode(rawValue: entity.mode.capitalized) ?? .companion
                )
            }
        }
    }

    private func clearHistory() {
        aiService.clearConversationHistory()
        appState.conversationHistory.removeAll()
        statusMessage = "History cleared"
    }

    private func testVoice() {
        voiceService.speak("BattleBuddy voice system is operational. All systems green.")
    }
}

// MARK: - Empty State
struct EmptyConversationView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform")
                .font(.system(size: 64))
                .foregroundColor(.bbSecondary)

            Text("Ready to chat")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.bbTextPrimary)

            Text("Hold the mic button to speak")
                .font(.system(size: 16))
                .foregroundColor(.bbTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }
}

// MARK: - Conversation Bubble
struct ConversationBubble: View {
    let entry: ConversationEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User message
            HStack {
                Spacer()
                Text(entry.userMessage)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.bbAccent)
                    .cornerRadius(16)
                    .frame(maxWidth: 280, alignment: .trailing)
            }

            // AI response
            HStack {
                Text(entry.aiResponse)
                    .font(.system(size: 15))
                    .foregroundColor(.bbTextPrimary)
                    .padding(12)
                    .background(Color.bbCardBackground)
                    .cornerRadius(16)
                    .frame(maxWidth: 280, alignment: .leading)
                Spacer()
            }
        }
    }
}

// MARK: - Transcript Preview
struct TranscriptPreview: View {
    let text: String

    var body: some View {
        HStack {
            Spacer()
            HStack(spacing: 8) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .bbAccent))
                    .scaleEffect(0.8)

                Text(text)
                    .font(.system(size: 14, style: .rounded))
                    .foregroundColor(.bbTextSecondary)
                    .lineLimit(3)
            }
            .padding(12)
            .background(Color.bbCardBackground.opacity(0.7))
            .cornerRadius(12)
            .frame(maxWidth: 280, alignment: .trailing)
        }
    }
}

// MARK: - Mic Button
struct MicButton: View {
    let isListening: Bool
    let isSpeaking: Bool
    let isProcessing: Bool
    let accentColor: Color
    let onPress: () -> Void
    let onRelease: () -> Void

    @State private var isPressed = false

    var body: some View {
        ZStack {
            // Outer pulse rings when active
            if isListening {
                Circle()
                    .stroke(accentColor.opacity(0.3), lineWidth: 3)
                    .frame(width: 100, height: 100)
                    .scaleEffect(isPressed ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isPressed)
            }

            // Main button
            Circle()
                .fill(buttonColor)
                .frame(width: 80, height: 80)
                .shadow(color: accentColor.opacity(0.4), radius: isPressed ? 20 : 12, x: 0, y: 4)
                .scaleEffect(isPressed ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)

            // Icon
            Group {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else if isSpeaking {
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                } else if isListening {
                    Image(systemName: "waveform")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                        onPress()
                    }
                }
                .onEnded { _ in
                    isPressed = false
                    onRelease()
                }
        )
    }

    private var buttonColor: Color {
        if isProcessing {
            return accentColor.opacity(0.7)
        } else if isSpeaking {
            return Color.bbSuccess
        } else if isListening {
            return Color.red
        } else {
            return accentColor
        }
    }
}

// MARK: - Error Banner
struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        VStack {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)

                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .lineLimit(2)

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.bbTextSecondary)
                }
            }
            .padding()
            .background(Color.red.opacity(0.9))
            .cornerRadius(12)
            .padding()

            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

#Preview {
    VoiceInterfaceView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(AppState())
}
